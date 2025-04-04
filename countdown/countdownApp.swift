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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Set Date"
        statusItem?.button?.action = #selector(promptForDate)
        
        startTimer()
    }
    
    @objc func promptForDate() {
        let alert = NSAlert()
        alert.messageText = "Enter target date and time"
        alert.informativeText = "Format: YYYY-MM-DD HH:MM"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = inputField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let dateString = inputField.stringValue
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
            statusItem?.button?.title = "✅ Time's up!"
            timer?.invalidate()
        }
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
