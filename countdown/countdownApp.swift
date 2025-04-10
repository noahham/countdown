import SwiftUI
import AppKit

@main
struct CountdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No primary window
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static var shared: AppDelegate? = nil
    var statusItem: NSStatusItem?
    var timer: Timer?
    var menu: NSMenu?
    
    let settings = SettingsData()
//    let confetti = ConfettiView()
    var settingsWindow: NSWindow?
    var dateWindow: NSWindow?
    
    // Adds app to dock if a window is open
    func applicationWillBecomeActive(_ notification: Notification) {
            NSApp.setActivationPolicy(.regular)
    }
        
    // Removes app from dock when a window isn't open
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        return false
    }
    
    // Initializes the menu bar instance
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Set Date"
        
        // On-click popup
        menu = NSMenu()
        menu?.addItem(NSMenuItem(title: "Set Date", action: #selector(promptForDate), keyEquivalent: ""))
        menu?.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        
        startTimer()
    }
    
    // Opens menu to change date
    @objc func promptForDate() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        dateWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        dateWindow?.center()
        dateWindow?.title = "Select Date"
        dateWindow?.isReleasedWhenClosed = false
        dateWindow?.contentView = NSHostingView(rootView: DateSelectionView(settings: settings))
        
        dateWindow?.delegate = self
        
        dateWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.setActivationPolicy(.regular)
    }
    
    // Opens menu to change settings
    @objc func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow?.center()
        settingsWindow?.title = "Settings"
        settingsWindow?.isReleasedWhenClosed = false
        settingsWindow?.contentView = NSHostingView(rootView: SettingsView(settings: settings))
        
        settingsWindow?.delegate = self
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.setActivationPolicy(.regular)
    }
    
    // Starts timer and adjusts update timing to update as little as possible
    func startTimer() {
        timer?.invalidate()

        let now = Date()
        let calendar = Calendar.current
        var interval: TimeInterval = 3600
        var fireDate: Date = now

        if settings.selectedUnit == .days {
            interval = 86400
            fireDate = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime)!
        } else if settings.minutesCheck {
            interval = 60
            fireDate = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime)!
        } else {
            interval = 3600
            fireDate = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)!
        }

        // Schedule the first update at the exact boundary
        let delay = fireDate.timeIntervalSinceNow
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.updateCountdown()
            self.timer = Timer.scheduledTimer(timeInterval: interval,
                                              target: self,
                                              selector: #selector(self.updateCountdown),
                                              userInfo: nil,
                                              repeats: true)
        }

        updateCountdown() // Run once immediately
    }

    // Recalculates time to finish with correct units
    @objc func updateCountdown() {
        guard let target = settings.targetDate else {
            statusItem?.button?.title = "Set Date"
            return
        }
        
        let timeLeft = target.timeIntervalSinceNow
        
        if timeLeft > 0 { // If timer is still going
            if settings.selectedUnit == .days { //
                let daysLeft = Int(timeLeft / 86400)
                statusItem?.button?.title = "\(daysLeft)d"
                
            // Units are in hours
            } else if settings.minutesCheck {
                
                let hoursLeft = Int(timeLeft / 3600)
                let minutesLeft = Int((timeLeft.truncatingRemainder(dividingBy: 3600)) / 60)
                statusItem?.button?.title = "\(hoursLeft)h \(minutesLeft)m"
                
            } else {
                
                let hoursLeft = Int(timeLeft / 3600)
                statusItem?.button?.title = "\(hoursLeft)h"
            }
            
        } else {
            statusItem?.button?.title = "Time's up!"
            timer?.invalidate()
//            confetti.startConfetti()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                self.confetti.stopConfetti()
//            }
        }
    }
    
    // On settings window close
    @objc func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == settingsWindow {
            settingsWindow = nil
        } else if notification.object as? NSWindow == dateWindow {
            dateWindow = nil
        }
        
        updateCountdown()
        AppDelegate.shared?.startTimer()
        settingsWindow = nil
    }
    
    // Updates timer on wake
    @objc func didWake(notification: Notification) {
        updateCountdown()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// Window for changing settings
struct SettingsView: View {
    @ObservedObject var settings: SettingsData

    var body: some View {
        VStack(spacing: 12) {
            Picker("Display in: ", selection: $settings.selectedUnit) {
                Text("Days").tag(TimeUnit.days)
                Text("Hours").tag(TimeUnit.hours)
            }
            .pickerStyle(.segmented)
            .padding(.top)
            .frame(width: 250)

            Toggle(isOn: $settings.minutesCheck) {
                Text("Show Minutes")
            }
            .toggleStyle(.checkbox)
            .disabled(settings.selectedUnit == .days)
            .padding(.bottom)

            Button("Save") {NSApp.windows.first(where: { $0.title == "Settings" })?.close()}
            
            Text("Created by Noah Ham.")
                .font(.caption)
                .padding(.top)
        }
        .frame(width: 300, height: 200)
    }
}

// Window for selecting date
struct DateSelectionView: View {
    @ObservedObject var settings: SettingsData
    
    var body: some View {
        VStack(spacing: 12) {
            DatePicker("Alert Date:", selection: Binding(
                get: { settings.targetDate ?? Date() },
                set: { settings.targetDate = $0 }
            ), in: Date()...) // No date before the present allowed
            
            Button("Submit") {NSApp.windows.first(where: { $0.title == "Select Date" })?.close()}
            .padding(.top)
        }
        .frame(width: 300, height: 200)
    }
}

// Holds all data transferred between classes and structs
class SettingsData: ObservableObject {
    @Published var minutesCheck: Bool = false
    @Published var selectedUnit: TimeUnit = .days
    @Published var targetDate: Date? = nil
}


// TimeUnit datatype
enum TimeUnit: String, CaseIterable, Identifiable {
    case days, hours
    var id: String {self.rawValue}
}
