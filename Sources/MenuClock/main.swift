import Cocoa
import Foundation
import Yams
import ServiceManagement

class TwoLineStatusView: NSView {
    var pairs: [(label: String, time: String)] = [] {
        didSet { needsDisplay = true }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let topFont = NSFont.systemFont(ofSize: 9)
        let bottomFont = NSFont.systemFont(ofSize: 9, weight: .medium)
        
        let topAttributes: [NSAttributedString.Key: Any] = [
            .font: topFont,
            .foregroundColor: NSColor.labelColor
        ]
        let bottomAttributes: [NSAttributedString.Key: Any] = [
            .font: bottomFont,
            .foregroundColor: NSColor.labelColor
        ]
        
        var xOffset: CGFloat = 2
        
        for pair in pairs {
            let timeString = NSAttributedString(string: pair.time, attributes: topAttributes)
            let labelString = NSAttributedString(string: pair.label, attributes: bottomAttributes)
            
            let timeSize = timeString.size()
            let labelSize = labelString.size()
            
            // Calculate max width for this pair
            let pairWidth = max(timeSize.width, labelSize.width)
            
            // Center time above label
            let timeCenterOffset = (pairWidth - timeSize.width) / 2
            let labelCenterOffset = (pairWidth - labelSize.width) / 2
            
            // Draw time (top)
            timeString.draw(at: NSPoint(x: xOffset + timeCenterOffset, y: 11))
            // Draw label (bottom)
            labelString.draw(at: NSPoint(x: xOffset + labelCenterOffset, y: 1))
            
            // Move to next pair position with spacing
            xOffset += pairWidth + 8
        }
    }
}

class MenuClockApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var config: Config!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load configuration
        guard let config = loadConfig() else {
            showError("Could not load configuration file.\n\nExpected location:\n\(configURL().path)\n\nIf that file exists, this could also be a format problem.")
            NSApplication.shared.terminate(nil)
            return
        }
        self.config = config
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create custom two-line view
        let customView = TwoLineStatusView(frame: NSRect(x: 0, y: 0, width: 100, height: 22))
        customView.pairs = []
        statusItem.button?.addSubview(customView)
        statusItem.button?.frame = customView.frame
        
        // Create menu
        let menu = NSMenu()
        
        // Add menu items for each configured clock
        for clock in config.clocks {
            menu.addItem(NSMenuItem(title: "\(clock.label): --:--", action: nil, keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Edit configuration...", action: #selector(editConfig), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Reload configuration", action: #selector(reloadConfig), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        // Update times immediately and then every so often
        updateTimes()
        timer = Timer.scheduledTimer(withTimeInterval: Double(config.updateInterval), repeats: true) { [weak self] _ in
            self?.updateTimes()
        }
    }
    
    func configURL() -> URL {
        // Use ~/Library/Application Support/MenuClock/config.yaml
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDirectory = appSupport.appendingPathComponent("MenuClock")
        return appDirectory.appendingPathComponent("config.yaml")
    }
    
    func configureLoginItem() {
        guard let config = config else { return }
        
        // Skip login item registration if not running from an app bundle (development mode)
        let bundlePath = Bundle.main.bundlePath
        guard bundlePath.hasSuffix(".app") else {
            if config.runAtStartup {
                print("Skipping login item registration (not running from app bundle)")
            }
            return
        }
        
        let service = SMAppService.mainApp
        let isEnabled = service.status == .enabled
        
        if config.runAtStartup && !isEnabled {
            // Register as login item
            do {
                try service.register()
                print("Registered as login item")
            } catch {
                print("Failed to register as login item: \(error)")
            }
        } else if !config.runAtStartup && isEnabled {
            // Unregister as login item
            do {
                try service.unregister()
                print("Unregistered as login item")
            } catch {
                print("Failed to unregister as login item: \(error)")
            }
        }
    }
    
    func loadConfig() -> Config? {
        let url = configURL()
        
        // If config doesn't exist, create default
        if !FileManager.default.fileExists(atPath: url.path) {
            createDefaultConfig()
        }
        
        guard let yamlString = try? String(contentsOf: url, encoding: .utf8),
              let config = try? YAMLDecoder().decode(Config.self, from: yamlString) else {
            return nil
        }
        
        print("Loaded config from: \(url.path)")
        return config
    }
    
    func createDefaultConfig() {
        let url = configURL()
        let directory = url.deletingLastPathComponent()
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Create default config
        let defaultConfig = Config(
            clocks: [
                ClockConfig(label: "Seattle", shortLabel: "SEA", timeZone: "America/Los_Angeles", format: "h:mm a"),
                ClockConfig(label: "Dublin", shortLabel: "DUB", timeZone: "Europe/Dublin", format: "h:mm a"),
                ClockConfig(label: "Hyderabad", shortLabel: "HYD", timeZone: "Asia/Kolkata", format: "h:mm a", display: "menu")
            ],
            updateInterval: 10,
            runAtStartup: true
        )
        
        if let yamlString = try? YAMLEncoder().encode(defaultConfig) {
            try? yamlString.write(to: url, atomically: true, encoding: .utf8)
            print("Created default config at: \(url.path)")
        }
    }
    
    func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "MenuClock Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func rebuildMenu() {
        guard let config = config else { return }
        
        let menu = NSMenu()
        
        // Add menu items for clocks with display = "menu" or "both"
        let menuClocks = config.menuClocks()
        for clock in menuClocks {
            menu.addItem(NSMenuItem(title: "\(clock.label): --:--", action: nil, keyEquivalent: ""))
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Edit Configuration...", action: #selector(editConfig), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Reload Configuration", action: #selector(reloadConfig), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func editConfig() {
        let url = configURL()
        
        // Ensure config file exists
        if !FileManager.default.fileExists(atPath: url.path) {
            createDefaultConfig()
        }
        
        // Open the config file with the default application
        NSWorkspace.shared.open(url)
    }
    
    @objc func reloadConfig() {
        guard let newConfig = loadConfig() else {
            showError("Failed to reload configuration.\n\nPlease check your config file at:\n\(configURL().path)")
            return
        }
        
        // Update config
        config = newConfig
        
        // Update login item registration
        configureLoginItem()
        
        // Invalidate old timer
        timer?.invalidate()
        
        // Rebuild menu with new clocks
        rebuildMenu()
        
        // Update times immediately
        updateTimes()
        
        // Start new timer with potentially new interval
        timer = Timer.scheduledTimer(withTimeInterval: Double(config.updateInterval), repeats: true) { [weak self] _ in
            self?.updateTimes()
        }
        
        print("Configuration reloaded successfully")
    }
    
    func updateTimes() {
        guard let menu = statusItem.menu, let config = config else { return }
        
        let now = Date()
        var formattedTimes: [(shortLabel: String, time: String)] = []
        
        // Get clocks for menu (those with display = "menu" or "both")
        let menuClocks = config.menuClocks()
        
        // Format times for each configured clock in menu
        for (index, clock) in menuClocks.enumerated() {
            guard let timeZone = TimeZone(identifier: clock.timeZone) else {
                print("Warning: Invalid time zone '\(clock.timeZone)'")
                continue
            }
            
            let formatter = DateFormatter()
            formatter.timeZone = timeZone
            formatter.dateFormat = clock.format
            let timeString = formatter.string(from: now)
            
            // Update menu item
            if index < menu.items.count {
                menu.items[index].title = "\(clock.label): \(timeString)"
            }
        }
        
        // Get clocks for menu bar (those with display = "menubar" or "both")
        let menuBarClocks = config.menuBarClocks()
        
        // Format times for menu bar display
        for clock in menuBarClocks {
            guard let timeZone = TimeZone(identifier: clock.timeZone) else {
                continue
            }
            
            let formatter = DateFormatter()
            formatter.timeZone = timeZone
            formatter.dateFormat = clock.format
            let timeString = formatter.string(from: now)
            
            formattedTimes.append((clock.shortLabel, timeString))
        }
        
        // Update button to show all times in two lines
        if let button = statusItem.button,
           let customView = button.subviews.first as? TwoLineStatusView {
            customView.pairs = formattedTimes.map { (label: $0.shortLabel, time: $0.time) }
            
            // Calculate total width needed
            let topFont = NSFont.systemFont(ofSize: 9)
            let bottomFont = NSFont.systemFont(ofSize: 9, weight: .medium)
            
            var totalWidth: CGFloat = 4  // Initial padding
            for pair in formattedTimes {
                let timeWidth = (pair.time as NSString).size(withAttributes: [.font: topFont]).width
                let labelWidth = (pair.shortLabel as NSString).size(withAttributes: [.font: bottomFont]).width
                totalWidth += max(timeWidth, labelWidth) + 8  // 8 for spacing between pairs
            }
            
            let newFrame = NSRect(x: 0, y: 0, width: totalWidth, height: 22)
            customView.frame = newFrame
            button.frame = newFrame
        }
    }
    
    @objc func quitApp() {
        timer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}

// Main application setup
let app = NSApplication.shared
let delegate = MenuClockApp()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hide dock icon
app.run()
