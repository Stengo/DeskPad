import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var window: NSWindow!
    private var viewController: DeskPadViewController!

    // MARK: - Constants

    private enum Constants {
        static let windowTitle = "DeskPad"
        static let minContentSize = CGSize(width: 400, height: 300)
        static let maxContentSize = CGSize(width: 3840, height: 2160)
    }

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_: Notification) {
        // Create view controller (which creates display in viewDidLoad)
        viewController = DeskPadViewController()

        // Create and configure window
        window = NSWindow(contentViewController: viewController)
        configureWindow()

        // Set window delegate
        window.delegate = viewController

        // Show window
        window.makeKeyAndOrderFront(nil)

        // Setup application menu
        setupMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        true
    }

    // MARK: - Window Configuration

    private func configureWindow() {
        window.title = Constants.windowTitle
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.backgroundColor = .white
        window.contentMinSize = Constants.minContentSize
        window.contentMaxSize = Constants.maxContentSize
        window.styleMask.insert(.resizable)
        window.collectionBehavior.insert(.fullScreenNone)
    }

    // MARK: - Menu Setup

    private func setupMenu() {
        let mainMenu = NSMenu()

        // Application menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: Constants.windowTitle)

        let quitItem = NSMenuItem(
            title: "Quit \(Constants.windowTitle)",
            action: #selector(NSApp.terminate),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }
}
