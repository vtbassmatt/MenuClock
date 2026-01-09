import Cocoa
import Foundation

class MenuClockApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    
    let seattleTimeZone = TimeZone(identifier: "America/Los_Angeles")!
    let dublinTimeZone = TimeZone(identifier: "Europe/Dublin")!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "⏰"
        }
        
        // Create menu
        let menu = NSMenu()
        
        // Add menu items
        menu.addItem(NSMenuItem(title: "Seattle: --:--", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Dublin: --:--", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        // Update times immediately and then every so often
        updateTimes()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateTimes()
        }
    }
    
    func updateTimes() {
        guard let menu = statusItem.menu else { return }
        
        let now = Date()
        
        // Format Seattle time
        let seattleFormatter = DateFormatter()
        seattleFormatter.timeZone = seattleTimeZone
        seattleFormatter.dateFormat = "HH:mm"
        let seattleTime = seattleFormatter.string(from: now)
        
        // Format Dublin time
        let dublinFormatter = DateFormatter()
        dublinFormatter.timeZone = dublinTimeZone
        dublinFormatter.dateFormat = "HH:mm"
        let dublinTime = dublinFormatter.string(from: now)
        
        // Update menu items
        if menu.items.count >= 2 {
            menu.items[0].title = "Seattle: \(seattleTime)"
            menu.items[1].title = "Dublin: \(dublinTime)"
        }
        
        // Update button to show both times
        if let button = statusItem.button {
            button.title = "⌚️ SEA: \(seattleTime) | DUB: \(dublinTime)"
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
