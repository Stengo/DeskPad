import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var window: NSWindow!
    private var viewController: DeskPadViewController!

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_: Notification) {
        print("[AppDelegate] applicationDidFinishLaunching")

        // Create view controller (which creates display in viewDidLoad)
        viewController = DeskPadViewController()
        print("[AppDelegate] DeskPadViewController created")

        // Create and configure window
        window = NSWindow(contentViewController: viewController)
        print("[AppDelegate] Window created")

        configureWindow()
        print("[AppDelegate] Window configured")

        // Set window delegate
        window.delegate = viewController

        // Show window
        window.makeKeyAndOrderFront(nil)
        print("[AppDelegate] Window shown")

        // Setup application menu
        setupMenu()
        print("[AppDelegate] Setup complete")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        true
    }

    // MARK: - Window Configuration

    private func configureWindow() {
        window.title = "DeskPad"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.backgroundColor = .white
        window.contentMinSize = CGSize(width: 400, height: 300)
        window.contentMaxSize = CGSize(width: 3840, height: 2160)
        window.styleMask.insert(.resizable)
        window.collectionBehavior.insert(.fullScreenNone)
    }

    // MARK: - Menu Setup

    private func setupMenu() {
        let mainMenu = NSMenu()

        // Application menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "DeskPad")

        let quitItem = NSMenuItem(
            title: "Quit DeskPad",
            action: #selector(NSApp.terminate),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }
}
