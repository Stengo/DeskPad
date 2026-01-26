import Cocoa
import ReSwift

enum ScreenViewAction: Action {
    case setDisplayID(CGDirectDisplayID)
}

private enum DisplayConstants {
    static let maxPixelsWide: UInt32 = 3840
    static let maxPixelsHigh: UInt32 = 2160
    static let sizeInMillimeters = CGSize(width: 1600, height: 1000)
    static let productID: UInt32 = 0x1234
    static let vendorID: UInt32 = 0x3456
    static let serialNum: UInt32 = 0x0001
    static let refreshRate: CGFloat = 60
    static let windowSnappingOffset: CGFloat = 30
    static let minContentSize = CGSize(width: 400, height: 300)

    /// BGRA pixel format - 'BGRA' as 32-bit integer
    static let bgraPixelFormat: Int32 = 1_111_970_369
}

private enum DisplayModes {
    static let modes: [CGVirtualDisplayMode] = [
        // 16:9 aspect ratio
        CGVirtualDisplayMode(width: 3840, height: 2160, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 2560, height: 1440, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1920, height: 1080, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1600, height: 900, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1366, height: 768, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1280, height: 720, refreshRate: DisplayConstants.refreshRate),
        // 16:10 aspect ratio
        CGVirtualDisplayMode(width: 2560, height: 1600, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1920, height: 1200, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1680, height: 1050, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1440, height: 900, refreshRate: DisplayConstants.refreshRate),
        CGVirtualDisplayMode(width: 1280, height: 800, refreshRate: DisplayConstants.refreshRate),
    ]
}

@MainActor
final class ScreenViewController: SubscriberViewController<ScreenViewData>, NSWindowDelegate {
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(didClickOnScreen)))
    }

    private var display: CGVirtualDisplay!
    private var stream: CGDisplayStream?
    private var isWindowHighlighted = false
    private var previousResolution: CGSize?
    private var previousScaleFactor: CGFloat?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureVirtualDisplay()
    }

    private func configureVirtualDisplay() {
        let descriptor = CGVirtualDisplayDescriptor()
        descriptor.setDispatchQueue(DispatchQueue.main)
        descriptor.name = "DeskPad Display"
        descriptor.maxPixelsWide = DisplayConstants.maxPixelsWide
        descriptor.maxPixelsHigh = DisplayConstants.maxPixelsHigh
        descriptor.sizeInMillimeters = DisplayConstants.sizeInMillimeters
        descriptor.productID = DisplayConstants.productID
        descriptor.vendorID = DisplayConstants.vendorID
        descriptor.serialNum = DisplayConstants.serialNum

        let display = CGVirtualDisplay(descriptor: descriptor)
        store.dispatch(ScreenViewAction.setDisplayID(display.displayID))
        self.display = display

        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 1
        settings.modes = DisplayModes.modes
        display.apply(settings)
    }

    override func update(with viewData: ScreenViewData) {
        updateWindowHighlight(isHighlighted: viewData.isWindowHighlighted)
        updateDisplayStream(resolution: viewData.resolution, scaleFactor: viewData.scaleFactor)
    }

    private func updateWindowHighlight(isHighlighted: Bool) {
        guard isHighlighted != isWindowHighlighted else { return }

        isWindowHighlighted = isHighlighted
        view.window?.backgroundColor = isHighlighted
            ? NSColor(named: "TitleBarActive")
            : NSColor(named: "TitleBarInactive")

        if isHighlighted {
            view.window?.orderFrontRegardless()
        }
    }

    private func updateDisplayStream(resolution: CGSize, scaleFactor: CGFloat) {
        guard resolution != .zero,
              resolution != previousResolution || scaleFactor != previousScaleFactor
        else {
            return
        }

        previousResolution = resolution
        previousScaleFactor = scaleFactor
        stream = nil

        configureWindowSize(for: resolution)
        createDisplayStream(resolution: resolution, scaleFactor: scaleFactor)
    }

    private func configureWindowSize(for resolution: CGSize) {
        view.window?.setContentSize(resolution)
        view.window?.contentAspectRatio = resolution
        view.window?.center()
    }

    private func createDisplayStream(resolution: CGSize, scaleFactor: CGFloat) {
        let outputWidth = Int(resolution.width * scaleFactor)
        let outputHeight = Int(resolution.height * scaleFactor)

        let stream = CGDisplayStream(
            dispatchQueueDisplay: display.displayID,
            outputWidth: outputWidth,
            outputHeight: outputHeight,
            pixelFormat: DisplayConstants.bgraPixelFormat,
            properties: [
                CGDisplayStream.showCursor: true,
            ] as CFDictionary,
            queue: .main,
            handler: { [weak self] _, _, frameSurface, _ in
                guard let surface = frameSurface else { return }
                self?.view.layer?.contents = surface
            }
        )

        self.stream = stream
        stream?.start()
    }

    nonisolated func windowWillResize(_ window: NSWindow, to frameSize: NSSize) -> NSSize {
        MainActor.assumeIsolated {
            calculateResizedFrame(for: window, proposedSize: frameSize)
        }
    }

    private func calculateResizedFrame(for window: NSWindow, proposedSize frameSize: NSSize) -> NSSize {
        let contentSize = window.contentRect(forFrameRect: NSRect(origin: .zero, size: frameSize)).size

        guard let screenResolution = previousResolution,
              abs(contentSize.width - screenResolution.width) < DisplayConstants.windowSnappingOffset
        else {
            return frameSize
        }

        return window.frameRect(forContentRect: NSRect(origin: .zero, size: screenResolution)).size
    }

    @objc private func didClickOnScreen(_ gestureRecognizer: NSGestureRecognizer) {
        guard let screenResolution = previousResolution else { return }

        let clickedPoint = gestureRecognizer.location(in: view)
        let normalizedX = clickedPoint.x / view.frame.width
        let normalizedY = (view.frame.height - clickedPoint.y) / view.frame.height

        let onScreenPoint = NSPoint(
            x: normalizedX * screenResolution.width,
            y: normalizedY * screenResolution.height
        )

        store.dispatch(MouseLocationAction.requestMove(toPoint: onScreenPoint))
    }
}
