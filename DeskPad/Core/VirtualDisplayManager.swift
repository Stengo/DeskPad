import Cocoa
import Combine

/// Manages the lifecycle of the virtual display
@MainActor
final class VirtualDisplayManager: ObservableObject {
    // MARK: - Published State

    @Published private(set) var displayID: CGDirectDisplayID?
    @Published private(set) var resolution: CGSize = .zero
    @Published private(set) var scaleFactor: CGFloat = 1.0
    @Published private(set) var isReady = false

    // MARK: - Private Properties

    private var virtualDisplay: CGVirtualDisplay?
    private var screenChangeSubscription: AnyCancellable?
    private var retrySubscription: AnyCancellable?
    private var retryCount = 0

    // MARK: - Constants

    private enum Constants {
        static let maxWidth: UInt32 = 3840
        static let maxHeight: UInt32 = 2160
        static let physicalSize = CGSize(width: 1600, height: 1000) // mm
        static let vendorID: UInt32 = 0x3456
        static let productID: UInt32 = 0x1234
        static let serialNum: UInt32 = 0x0001
        static let refreshRate: CGFloat = 60
        static let maxRetries = 50
        static let retryInterval: TimeInterval = 0.1

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
        screenChangeSubscription?.cancel()
        retrySubscription?.cancel()
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
        virtualDisplay = display
        displayID = display.displayID

        // Configure settings
        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 1
        settings.modes = Constants.displayModes
        display.apply(settings)

        // Start observing screen parameter changes using Combine
        screenChangeSubscription = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification, object: NSApplication.shared)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateScreenConfiguration()
            }

        // Start retry loop to find the display
        retryCount = 0
        startRetryLoop()
    }

    /// Destroys the virtual display
    func destroy() {
        screenChangeSubscription?.cancel()
        screenChangeSubscription = nil
        retrySubscription?.cancel()
        retrySubscription = nil
        virtualDisplay = nil
        displayID = nil
        resolution = .zero
        scaleFactor = 1.0
        isReady = false
    }

    // MARK: - Private Methods

    private func startRetryLoop() {
        retrySubscription = Timer.publish(every: Constants.retryInterval, on: .main, in: .common)
            .autoconnect()
            .prefix(Constants.maxRetries)
            .sink { [weak self] _ in
                self?.updateScreenConfiguration()
            }
    }

    private func updateScreenConfiguration() {
        guard let displayID = displayID else { return }

        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) else {
            retryCount += 1
            return
        }

        // Found the screen - stop retry loop
        retrySubscription?.cancel()
        retrySubscription = nil

        resolution = screen.frame.size
        scaleFactor = screen.backingScaleFactor
        isReady = true
    }
}
