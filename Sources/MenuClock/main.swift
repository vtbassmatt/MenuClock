import Cocoa
import Foundation
import Yams

struct ClockConfig: Codable {
    let label: String
    let shortLabel: String
    let timeZone: String
    let format: String
}

struct Config: Codable {
    let clocks: [ClockConfig]
    let updateInterval: Int
}

class MenuClockApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var config: Config!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load configuration
        guard let config = loadConfig() else {
            showError("Could not load configuration file.\n\nExpected location:\n\(configURL().path)")
            NSApplication.shared.terminate(nil)
            return
        }
        self.config = config
        
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "⏰"
        }
        
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
                ClockConfig(label: "Seattle", shortLabel: "SEA", timeZone: "America/Los_Angeles", format: "HH:mm"),
                ClockConfig(label: "Dublin", shortLabel: "DUB", timeZone: "Europe/Dublin", format: "HH:mm")
            ],
            updateInterval: 10
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
        
        // Add menu items for each configured clock
        for clock in config.clocks {
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
        
        // Format times for each configured clock
        for (index, clock) in config.clocks.enumerated() {
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
            
            formattedTimes.append((clock.shortLabel, timeString))
        }
        
        // Update button to show all times
        if let button = statusItem.button {
            let timesText = formattedTimes.map { "\($0.shortLabel): \($0.time)" }.joined(separator: " | ")
            let attributed = NSAttributedString(
                string: "⌚️ \(timesText)",
                attributes: [.font: NSFont.systemFont(ofSize: 11)]
            )
            button.attributedTitle = attributed
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
