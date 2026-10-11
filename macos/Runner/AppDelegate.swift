import Cocoa
import FlutterMacOS
import window_manager

@main
class AppDelegate: FlutterAppDelegate {
    private let activationNotification = Notification.Name("io.github.yuuukicreation.po0clash.activate")

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleActivationNotification(_:)),
            name: activationNotification,
            object: nil
        )
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let anotherInstanceIsRunning = NSWorkspace.shared.runningApplications.contains {
            $0.processIdentifier != ProcessInfo.processInfo.processIdentifier &&
                $0.bundleIdentifier == bundleIdentifier
        }
        if anotherInstanceIsRunning {
            DistributedNotificationCenter.default().postNotificationName(
                activationNotification,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        }
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        WindowManagerPlugin.instance?.handleShouldTerminate()
        return .terminateCancel
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
      return true
    }
    
    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        revealWindow()
        return false
    }

    @objc private func handleActivationNotification(_ notification: Notification) {
        revealWindow()
    }

    private func revealWindow() {
        if let window = NSApp.windows.first(where: { $0 is MainFlutterWindow }) {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        WindowManagerPlugin.instance?.handleReopen()
    }
}
