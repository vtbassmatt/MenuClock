# MenuClock

A world clock in the menu bar showing times for Seattle and Dublin.

## Features

- Displays current time for Seattle (America/Los_Angeles) and Dublin (Europe/Dublin)
- Lives in the macOS menu bar
- Updates every second
- Shows times in both the menu bar button and dropdown menu

## Building and Running

1. Make sure you have Xcode installed (includes Swift compiler)

2. Build the application:
   ```bash
   swift build -c release
   ```

3. Run the application:
   ```bash
   .build/release/MenuClock
   ```

4. The clock will appear in your menu bar with both times displayed. Click on it to see a dropdown with the times and a Quit option.

## How It Works

The app uses:
- `NSStatusItem` to create a menu bar item
- `Timer` to update times every second
- `TimeZone` and `DateFormatter` to display times in different time zones
- `NSApplication` with `.accessory` activation policy to hide the dock icon