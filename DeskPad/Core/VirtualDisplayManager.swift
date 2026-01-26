import Combine
import Foundation

/// Manages the lifecycle of the virtual display
final class VirtualDisplayManager: ObservableObject {
    // MARK: - Published State

    @Published private(set) var displayID: CGDirectDisplayID?
    @Published private(set) var resolution: CGSize = .zero
    @Published private(set) var scaleFactor: CGFloat = 1.0
    @Published private(set) var isReady = false

    // MARK: - Private Properties

    private var virtualDisplay: CGVirtualDisplay?
    private var notificationObserver: NSObjectProtocol?

    // MARK: - Constants

    private enum Constants {
        static let maxWidth: UInt32 = 3840
        static let maxHeight: UInt32 = 2160
        static let physicalSize = CGSize(width: 1600, height: 1000) // mm
        static let vendorID: UInt32 = 0x3456
        static let productID: UInt32 = 0x1234
        static let serialNum: UInt32 = 0x0001
        static let refreshRate: CGFloat = 60

        static let displayModes: [CGVirtualDisplayMode] = [
            // 16:9 aspect ratio
            CGVirtualDisplayMode(width: 3840, height: 2160, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 2560, height: 1440, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1920, height: 1080, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1600, height: 900, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1366, height: 768, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1280, height: 720, refreshRate: refreshRate),
            // 16:10 aspect ratio
            CGVirtualDisplayMode(width: 2560, height: 1600, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1920, height: 1200, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1680, height: 1050, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1440, height: 900, refreshRate: refreshRate),
            CGVirtualDisplayMode(width: 1280, height: 800, refreshRate: refreshRate),
        ]
    }

    // MARK: - Initialization

    init() {}

    deinit {
        destroy()
    }

    // MARK: - Public Methods

    /// Creates and configures the virtual display
    func create() {
        guard virtualDisplay == nil else { return }

        // Create descriptor
        let descriptor = CGVirtualDisplayDescriptor()
        descriptor.setDispatchQueue(DispatchQueue.main)
        descriptor.name = "DeskPad Display"
        descriptor.maxPixelsWide = Constants.maxWidth
        descriptor.maxPixelsHigh = Constants.maxHeight
        descriptor.sizeInMillimeters = Constants.physicalSize
        descriptor.vendorID = Constants.vendorID
        descriptor.productID = Constants.productID
        descriptor.serialNum = Constants.serialNum

        // Create the virtual display
        let display = CGVirtualDisplay(descriptor: descriptor)
        self.virtualDisplay = display
        self.displayID = display.displayID

        // Configure settings
        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 1
        settings.modes = Constants.displayModes
        display.apply(settings)

        // Start observing screen parameter changes
        startObservingScreenChanges()

        // Query initial configuration after a brief delay to allow system to recognize display
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.updateScreenConfiguration()
        }
    }

    /// Destroys the virtual display
    func destroy() {
        stopObservingScreenChanges()
        virtualDisplay = nil
        displayID = nil
        resolution = .zero
        scaleFactor = 1.0
        isReady = false
    }

    // MARK: - Private Methods

    private func startObservingScreenChanges() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: .main
        ) { [weak self] _ in
            self?.updateScreenConfiguration()
        }
    }

    private func stopObservingScreenChanges() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }

    private func updateScreenConfiguration() {
        guard let displayID = displayID else { return }

        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) else {
            // Display not yet recognized by system, retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateScreenConfiguration()
            }
            return
        }

        resolution = screen.frame.size
        scaleFactor = screen.backingScaleFactor
        isReady = true
    }
}
