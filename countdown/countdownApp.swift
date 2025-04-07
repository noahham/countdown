import SwiftUI

@main
struct CountdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?
    var menu: NSMenu?
    
    let settings = SettingsData()
    var settingsWindow: NSWindow?
    var dateWindow: NSWindow?
    
    var updateInterval: Int?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
    
    @objc func promptForDate() {
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
    }
    
    @objc func openSettings() {
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
    }
    
    func startTimer() {
        timer?.invalidate()

        var interval: TimeInterval = 3600 // Default
        var fireDate: Date = Date()

        let calendar = Calendar.current
        let now = Date()

        if settings.selectedUnit == .days {
            interval = 86400 // 1 day
            fireDate = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime)!
        } else if settings.minutesCheck {
            interval = 60
            fireDate = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime)!
        } else {
            interval = 3600
            fireDate = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)!
        }

        updateInterval = Int(interval)

        // Schedule first update at next boundary
        let delay = fireDate.timeIntervalSinceNow
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.updateCountdown()
            self?.timer = Timer.scheduledTimer(timeInterval: interval,
                                               target: self as Any,
                                               selector: #selector(self?.updateCountdown),
                                               userInfo: nil,
                                               repeats: true)
        }

        updateCountdown()
    }


    
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
                let minutesLeft = Int((timeLeft.truncatingRemainder(dividingBy: 3600)) / 60)
                let hoursLeft = Int(timeLeft / 3600)
                statusItem?.button?.title = "\(hoursLeft)h \(minutesLeft)m"
                
            } else {
                let hoursLeft = Int(timeLeft / 3600)
                statusItem?.button?.title = "\(hoursLeft)h"
            }
        } else {
            statusItem?.button?.title = "Time's up!"
            timer?.invalidate()
        }
    }
    
    @objc func windowWillClose(_ notification: Notification) {
        updateCountdown()
        settingsWindow = nil
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

            Button("Save") {
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.startTimer() // Restart with new interval
                }
                NSApp.windows.first(where: { $0.title == "Settings" })?.close()
            }
            
            Text("Created by Noah Ham.")
                .font(.caption)
                .padding(.top)
        }
        .frame(width: 300, height: 200)
    }
}

struct DateSelectionView: View {
    @ObservedObject var settings: SettingsData
    
    var body: some View {
        VStack(spacing: 12) {
            DatePicker("Alert Date:", selection: Binding(
                get: { settings.targetDate ?? Date() },
                set: { settings.targetDate = $0 }
            ))
            
            Button("Submit") {NSApp.windows.first(where: { $0.title == "Select Date" })?.close()}
            .padding(.top)
        }
        .frame(width: 300, height: 200)
    }
}

class SettingsData: ObservableObject {
    @Published var minutesCheck: Bool = false
    @Published var selectedUnit: TimeUnit = .days
    @Published var targetDate: Date? = nil
}


enum TimeUnit: String, CaseIterable, Identifiable {
    case days, hours
    var id: String {self.rawValue}
}
