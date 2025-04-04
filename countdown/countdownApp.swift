import SwiftUI
import AppKit

@main
struct CountdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No main window
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?
    var targetDate: Date?
    var menu: NSMenu?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Set Date"
        
        menu = NSMenu()
        menu?.addItem(NSMenuItem(title: "Set Date", action: #selector(promptForDate), keyEquivalent: ""))
        menu?.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        
        startTimer()
    }
    
    @objc func promptForDate() {
        let inputView = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        let alert = NSAlert()
        alert.messageText = "Enter target date and time"
        alert.informativeText = "Format: YYYY-MM-DD HH:MM"
        alert.alertStyle = .informational
        alert.accessoryView = inputView
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let dateString = inputView.stringValue
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = formatter.date(from: dateString) {
                targetDate = date
                updateCountdown()
            } else {
                showError("Invalid date format. Use YYYY-MM-DD HH:MM")
            }
        }
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.center()
            settingsWindow?.title = "Settings"
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.contentView = NSHostingView(rootView: SettingsView())
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
        updateCountdown() // Ensure it updates immediately on launch
    }
    
    @objc func updateCountdown() {
        guard let targetDate = targetDate else { return }
        let timeLeft = targetDate.timeIntervalSinceNow
        if timeLeft > 0 {
            let hoursLeft = Int(timeLeft / 3600)
            let minutesLeft = Int((timeLeft.truncatingRemainder(dividingBy: 3600)) / 60)
            statusItem?.button?.title = "⏳ \(hoursLeft)h \(minutesLeft)m"
        } else {
            statusItem?.button?.title = "Time's up!"
            timer?.invalidate()
        }
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
    @State private var minutesCheck = false
    @State private var selectedUnit: TimeUnit = .hours
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Settings")
                .font(.headline)
                .padding()

            Picker("Display in: ", selection: $selectedUnit) {
                Text("Days").tag(TimeUnit.days)
                Text("Hours").tag(TimeUnit.hours)
            }
            .pickerStyle(.segmented)
            .padding(.vertical)
            .frame(width: 250)
            
            Toggle(isOn: $minutesCheck) {
                Text("Show Minutes")
            }
            .toggleStyle(.checkbox)

            Button("Close") {
                NSApp.keyWindow?.close()
            }
            .padding()
            .frame(width: 500)
        }
    }	
}

enum TimeUnit: String, CaseIterable, Identifiable {
    case days, hours
    var id: String { self.rawValue }
}
	
