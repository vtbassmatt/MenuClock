import XCTest
import Yams
@testable import MenuClock

final class MenuClockTests: XCTestCase {
    
    // MARK: - ClockConfig Tests
    
    func testClockConfigWithAllFields() throws {
        let yaml = """
        label: Seattle
        shortLabel: SEA
        timeZone: America/Los_Angeles
        format: h:mm a
        display: both
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.label, "Seattle")
        XCTAssertEqual(config.shortLabel, "SEA")
        XCTAssertEqual(config.timeZone, "America/Los_Angeles")
        XCTAssertEqual(config.format, "h:mm a")
        XCTAssertEqual(config.display, "both")
    }
    
    func testClockConfigWithMissingDisplay() throws {
        let yaml = """
        label: Dublin
        shortLabel: DUB
        timeZone: Europe/Dublin
        format: HH:mm
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.display, "both", "Display should default to 'both' when not specified")
    }
    
    func testClockConfigWithInvalidDisplay() throws {
        let yaml = """
        label: Tokyo
        shortLabel: TYO
        timeZone: Asia/Tokyo
        format: HH:mm
        display: invalid
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.display, "both", "Invalid display value should default to 'both'")
    }
    
    func testClockConfigWithMenuBarDisplay() throws {
        let yaml = """
        label: London
        shortLabel: LON
        timeZone: Europe/London
        format: HH:mm
        display: menubar
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.display, "menubar")
    }
    
    func testClockConfigWithMenuDisplay() throws {
        let yaml = """
        label: Paris
        shortLabel: PAR
        timeZone: Europe/Paris
        format: HH:mm
        display: menu
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.display, "menu")
    }
    
    func testClockConfigWithMissingLabel() throws {
        let yaml = """
        shortLabel: NYC
        timeZone: America/New_York
        format: h:mm a
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.label, "Unknown", "Missing label should default to 'Unknown'")
        XCTAssertEqual(config.shortLabel, "NYC")
    }
    
    func testClockConfigWithMissingShortLabel() throws {
        let yaml = """
        label: New York
        timeZone: America/New_York
        format: h:mm a
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.label, "New York")
        XCTAssertEqual(config.shortLabel, "New", "Missing shortLabel should use first 3 chars of label")
    }
    
    func testClockConfigWithMissingTimeZone() throws {
        let yaml = """
        label: Unknown City
        shortLabel: UNK
        format: HH:mm
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.timeZone, "UTC", "Missing timeZone should default to UTC")
    }
    
    func testClockConfigWithMissingFormat() throws {
        let yaml = """
        label: Berlin
        shortLabel: BER
        timeZone: Europe/Berlin
        """
        
        let config = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(config.format, "HH:mm", "Missing format should default to HH:mm")
    }
    
    func testClockConfigDirectInitialization() {
        let config = ClockConfig(
            label: "Test City",
            shortLabel: "TST",
            timeZone: "UTC",
            format: "HH:mm:ss"
        )
        
        XCTAssertEqual(config.label, "Test City")
        XCTAssertEqual(config.shortLabel, "TST")
        XCTAssertEqual(config.timeZone, "UTC")
        XCTAssertEqual(config.format, "HH:mm:ss")
        XCTAssertEqual(config.display, "both", "Display should default to 'both' in regular initializer")
    }
    
    func testClockConfigDirectInitializationWithDisplay() {
        let config = ClockConfig(
            label: "Test City",
            shortLabel: "TST",
            timeZone: "UTC",
            format: "HH:mm:ss",
            display: "menubar"
        )
        
        XCTAssertEqual(config.display, "menubar")
    }
    
    // MARK: - Config Tests
    
    func testConfigWithAllFields() throws {
        let yaml = """
        clocks:
          - label: Seattle
            shortLabel: SEA
            timeZone: America/Los_Angeles
            format: h:mm a
          - label: Dublin
            shortLabel: DUB
            timeZone: Europe/Dublin
            format: h:mm a
        updateInterval: 10
        runAtStartup: true
        """
        
        let config = try YAMLDecoder().decode(Config.self, from: yaml)
        
        XCTAssertEqual(config.clocks.count, 2)
        XCTAssertEqual(config.updateInterval, 10)
        XCTAssertTrue(config.runAtStartup)
    }
    
    func testConfigWithMissingClocks() throws {
        let yaml = """
        updateInterval: 5
        runAtStartup: false
        """
        
        let config = try YAMLDecoder().decode(Config.self, from: yaml)
        
        XCTAssertEqual(config.clocks.count, 1, "Missing clocks should create default UTC clock")
        XCTAssertEqual(config.clocks[0].label, "UTC")
        XCTAssertEqual(config.updateInterval, 5)
        XCTAssertFalse(config.runAtStartup)
    }
    
    func testConfigWithEmptyClocks() throws {
        let yaml = """
        clocks: []
        updateInterval: 10
        runAtStartup: true
        """
        
        let config = try YAMLDecoder().decode(Config.self, from: yaml)
        
        XCTAssertEqual(config.clocks.count, 0, "Empty clocks array should be preserved")
    }
    
    func testConfigWithMissingUpdateInterval() throws {
        let yaml = """
        clocks:
          - label: Seattle
            shortLabel: SEA
            timeZone: America/Los_Angeles
            format: h:mm a
        runAtStartup: true
        """
        
        let config = try YAMLDecoder().decode(Config.self, from: yaml)
        
        XCTAssertEqual(config.updateInterval, 10, "Missing updateInterval should default to 10")
    }
    
    func testConfigWithMissingRunAtStartup() throws {
        let yaml = """
        clocks:
          - label: Seattle
            shortLabel: SEA
            timeZone: America/Los_Angeles
            format: h:mm a
        updateInterval: 15
        """
        
        let config = try YAMLDecoder().decode(Config.self, from: yaml)
        
        XCTAssertFalse(config.runAtStartup, "Missing runAtStartup should default to false")
    }
    
    func testConfigDirectInitialization() {
        let clock = ClockConfig(
            label: "Test",
            shortLabel: "TST",
            timeZone: "UTC",
            format: "HH:mm"
        )
        
        let config = Config(
            clocks: [clock],
            updateInterval: 20,
            runAtStartup: true
        )
        
        XCTAssertEqual(config.clocks.count, 1)
        XCTAssertEqual(config.updateInterval, 20)
        XCTAssertTrue(config.runAtStartup)
    }
    
    // MARK: - Display Filtering Tests
    
    func testMenuBarClocksFiltering() {
        let clocks = [
            ClockConfig(label: "Both", shortLabel: "BOT", timeZone: "UTC", format: "HH:mm", display: "both"),
            ClockConfig(label: "MenuBar", shortLabel: "BAR", timeZone: "UTC", format: "HH:mm", display: "menubar"),
            ClockConfig(label: "Menu", shortLabel: "MEN", timeZone: "UTC", format: "HH:mm", display: "menu")
        ]
        
        let config = Config(clocks: clocks, updateInterval: 10, runAtStartup: false)
        let menuBarClocks = config.menuBarClocks()
        
        XCTAssertEqual(menuBarClocks.count, 2, "Should include 'both' and 'menubar' clocks")
        XCTAssertTrue(menuBarClocks.contains { $0.label == "Both" })
        XCTAssertTrue(menuBarClocks.contains { $0.label == "MenuBar" })
        XCTAssertFalse(menuBarClocks.contains { $0.label == "Menu" })
    }
    
    func testMenuClocksFiltering() {
        let clocks = [
            ClockConfig(label: "Both", shortLabel: "BOT", timeZone: "UTC", format: "HH:mm", display: "both"),
            ClockConfig(label: "MenuBar", shortLabel: "BAR", timeZone: "UTC", format: "HH:mm", display: "menubar"),
            ClockConfig(label: "Menu", shortLabel: "MEN", timeZone: "UTC", format: "HH:mm", display: "menu")
        ]
        
        let config = Config(clocks: clocks, updateInterval: 10, runAtStartup: false)
        let menuClocks = config.menuClocks()
        
        XCTAssertEqual(menuClocks.count, 2, "Should include 'both' and 'menu' clocks")
        XCTAssertTrue(menuClocks.contains { $0.label == "Both" })
        XCTAssertTrue(menuClocks.contains { $0.label == "Menu" })
        XCTAssertFalse(menuClocks.contains { $0.label == "MenuBar" })
    }
    
    func testAllClocksWithDefaultDisplay() {
        let clocks = [
            ClockConfig(label: "City1", shortLabel: "C1", timeZone: "UTC", format: "HH:mm"),
            ClockConfig(label: "City2", shortLabel: "C2", timeZone: "UTC", format: "HH:mm")
        ]
        
        let config = Config(clocks: clocks, updateInterval: 10, runAtStartup: false)
        
        XCTAssertEqual(config.menuBarClocks().count, 2, "All clocks with default display should appear in menu bar")
        XCTAssertEqual(config.menuClocks().count, 2, "All clocks with default display should appear in menu")
    }
    
    func testNoMenuBarClocks() {
        let clocks = [
            ClockConfig(label: "Menu1", shortLabel: "M1", timeZone: "UTC", format: "HH:mm", display: "menu"),
            ClockConfig(label: "Menu2", shortLabel: "M2", timeZone: "UTC", format: "HH:mm", display: "menu")
        ]
        
        let config = Config(clocks: clocks, updateInterval: 10, runAtStartup: false)
        
        XCTAssertEqual(config.menuBarClocks().count, 0, "No clocks should appear in menu bar")
        XCTAssertEqual(config.menuClocks().count, 2, "All clocks should appear in menu")
    }
    
    func testNoMenuClocks() {
        let clocks = [
            ClockConfig(label: "Bar1", shortLabel: "B1", timeZone: "UTC", format: "HH:mm", display: "menubar"),
            ClockConfig(label: "Bar2", shortLabel: "B2", timeZone: "UTC", format: "HH:mm", display: "menubar")
        ]
        
        let config = Config(clocks: clocks, updateInterval: 10, runAtStartup: false)
        
        XCTAssertEqual(config.menuBarClocks().count, 2, "All clocks should appear in menu bar")
        XCTAssertEqual(config.menuClocks().count, 0, "No clocks should appear in menu")
    }
    
    // MARK: - Round-trip Encoding Tests
    
    func testClockConfigRoundTrip() throws {
        let original = ClockConfig(
            label: "Singapore",
            shortLabel: "SIN",
            timeZone: "Asia/Singapore",
            format: "HH:mm:ss",
            display: "menubar"
        )
        
        let yaml = try YAMLEncoder().encode(original)
        let decoded = try YAMLDecoder().decode(ClockConfig.self, from: yaml)
        
        XCTAssertEqual(decoded.label, original.label)
        XCTAssertEqual(decoded.shortLabel, original.shortLabel)
        XCTAssertEqual(decoded.timeZone, original.timeZone)
        XCTAssertEqual(decoded.format, original.format)
        XCTAssertEqual(decoded.display, original.display)
    }
    
    func testConfigRoundTrip() throws {
        let clock1 = ClockConfig(label: "City1", shortLabel: "C1", timeZone: "UTC", format: "HH:mm", display: "both")
        let clock2 = ClockConfig(label: "City2", shortLabel: "C2", timeZone: "UTC", format: "HH:mm", display: "menu")
        
        let original = Config(
            clocks: [clock1, clock2],
            updateInterval: 30,
            runAtStartup: true
        )
        
        let yaml = try YAMLEncoder().encode(original)
        let decoded = try YAMLDecoder().decode(Config.self, from: yaml)
        
        XCTAssertEqual(decoded.clocks.count, original.clocks.count)
        XCTAssertEqual(decoded.updateInterval, original.updateInterval)
        XCTAssertEqual(decoded.runAtStartup, original.runAtStartup)
        XCTAssertEqual(decoded.clocks[0].label, "City1")
        XCTAssertEqual(decoded.clocks[1].label, "City2")
    }
}
