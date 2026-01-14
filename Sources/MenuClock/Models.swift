import Foundation
import Yams

public struct ClockConfig: Codable {
    public let label: String
    public let shortLabel: String
    public let timeZone: String
    public let format: String
    public let display: String  // "menubar", "menu", or "both" (default)
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case label, shortLabel, timeZone, format, display
    }
    
    // Regular initializer for direct instantiation
    public init(label: String, shortLabel: String, timeZone: String, format: String, display: String = "both") {
        self.label = label
        self.shortLabel = shortLabel
        self.timeZone = timeZone
        self.format = format
        self.display = display
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields with fallbacks
        if let label = try? container.decode(String.self, forKey: .label) {
            self.label = label
        } else {
            print("Warning: clock config missing 'label', using default")
            self.label = "Unknown"
        }
        
        if let shortLabel = try? container.decode(String.self, forKey: .shortLabel) {
            self.shortLabel = shortLabel
        } else {
            print("Warning: clock config missing 'shortLabel', using label")
            self.shortLabel = String(self.label.prefix(3))
        }
        
        if let timeZone = try? container.decode(String.self, forKey: .timeZone) {
            self.timeZone = timeZone
        } else {
            print("Warning: clock config missing 'timeZone', using UTC")
            self.timeZone = "UTC"
        }
        
        if let format = try? container.decode(String.self, forKey: .format) {
            self.format = format
        } else {
            print("Warning: clock config missing 'format', using default")
            self.format = "HH:mm"
        }
        
        if let display = try? container.decode(String.self, forKey: .display) {
            // Validate display value
            if ["menubar", "menu", "both"].contains(display) {
                self.display = display
            } else {
                print("Warning: invalid display value '\(display)', using 'both'")
                self.display = "both"
            }
        } else {
            self.display = "both"
        }
        
        // Check for extra keys
        let knownKeys = Set(CodingKeys.allCases.map { $0.stringValue })
        let allKeys = container.allKeys.map { $0.stringValue }
        let extraKeys = Set(allKeys).subtracting(knownKeys)
        if !extraKeys.isEmpty {
            print("Warning: clock config has extra keys: \(extraKeys.joined(separator: ", "))")
        }
    }
}

public struct Config: Codable {
    public let clocks: [ClockConfig]
    public let updateInterval: Int
    public let runAtStartup: Bool
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case clocks, updateInterval, runAtStartup
    }
    
    // Regular initializer for direct instantiation
    public init(clocks: [ClockConfig], updateInterval: Int, runAtStartup: Bool) {
        self.clocks = clocks
        self.updateInterval = updateInterval
        self.runAtStartup = runAtStartup
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Parse clocks array
        if let clocks = try? container.decode([ClockConfig].self, forKey: .clocks) {
            self.clocks = clocks
            if clocks.isEmpty {
                print("Warning: 'clocks' array is empty")
            }
        } else {
            print("Warning: config missing 'clocks', using default")
            self.clocks = [
                ClockConfig(label: "UTC", shortLabel: "UTC", timeZone: "UTC", format: "HH:mm")
            ]
        }
        
        // Parse updateInterval
        if let interval = try? container.decode(Int.self, forKey: .updateInterval) {
            self.updateInterval = interval
        } else {
            print("Warning: config missing 'updateInterval', using default (10)")
            self.updateInterval = 10
        }
        
        // Parse runAtStartup
        if let runAtStartup = try? container.decode(Bool.self, forKey: .runAtStartup) {
            self.runAtStartup = runAtStartup
        } else {
            print("Warning: config missing 'runAtStartup', using default (false)")
            self.runAtStartup = false
        }
        
        // Check for extra keys
        let knownKeys = Set(CodingKeys.allCases.map { $0.stringValue })
        let allKeys = container.allKeys.map { $0.stringValue }
        let extraKeys = Set(allKeys).subtracting(knownKeys)
        if !extraKeys.isEmpty {
            print("Warning: config has extra keys: \(extraKeys.joined(separator: ", "))")
        }
    }
}

// Helper functions for filtering clocks by display type
public extension Config {
    /// Returns clocks that should appear in the menu bar
    func menuBarClocks() -> [ClockConfig] {
        return clocks.filter { $0.display == "menubar" || $0.display == "both" }
    }
    
    /// Returns clocks that should appear in the dropdown menu
    func menuClocks() -> [ClockConfig] {
        return clocks.filter { $0.display == "menu" || $0.display == "both" }
    }
}
