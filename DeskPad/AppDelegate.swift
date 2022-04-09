import Cocoa
import Dynamic

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let viewController = ViewController()
        window = NSWindow(contentViewController: viewController)
        window.makeKeyAndOrderFront(nil)
        window.setFrame(NSRect(x: 0, y: 0, width: 1280, height: 800), display: true)
        window.center()
    }
}
