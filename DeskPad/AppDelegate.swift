import Cocoa
import Dynamic

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let viewController = ViewController()
        window = NSWindow(contentViewController: viewController)
        window.makeKeyAndOrderFront(nil)
        let contentSize = NSSize(width: 1280, height: 800)
        window.contentMinSize = contentSize
        window.contentMaxSize = contentSize
        window.setContentSize(contentSize)
        window.center()
    }
}
