import Cocoa

/// Simple layer-based renderer for the display stream
final class DisplayStreamRenderer: NSView {
    // MARK: - Properties

    private var displayStream: CGDisplayStream?
    private var currentDisplayID: CGDirectDisplayID?
    private var currentResolution: CGSize = .zero
    private var currentScaleFactor: CGFloat = 1.0

    // MARK: - Constants

    private enum Constants {
        /// BGRA pixel format as 32-bit integer ('BGRA')
        static let bgraPixelFormat: Int32 = 1_111_970_369
    }

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopStream()
    }

    // MARK: - Public Methods

    /// Configures and starts the display stream
    func configure(displayID: CGDirectDisplayID, resolution: CGSize, scaleFactor: CGFloat) {
        // Skip if already configured with same parameters
        if displayID == currentDisplayID,
           resolution == currentResolution,
           scaleFactor == currentScaleFactor,
           displayStream != nil
        {
            return
        }

        // Stop existing stream
        stopStream()

        // Store current configuration
        currentDisplayID = displayID
        currentResolution = resolution
        currentScaleFactor = scaleFactor

        // Calculate output dimensions
        let outputWidth = Int(resolution.width * scaleFactor)
        let outputHeight = Int(resolution.height * scaleFactor)

        // Create new display stream
        let stream = CGDisplayStream(
            dispatchQueueDisplay: displayID,
            outputWidth: outputWidth,
            outputHeight: outputHeight,
            pixelFormat: Constants.bgraPixelFormat,
            properties: [
                CGDisplayStream.showCursor: true,
            ] as CFDictionary,
            queue: .main,
            handler: { [weak self] _, _, frameSurface, _ in
                guard let surface = frameSurface else { return }
                self?.layer?.contents = surface
            }
        )

        if let stream = stream {
            displayStream = stream
            stream.start()
        }
    }

    /// Stops the display stream
    func stopStream() {
        displayStream?.stop()
        displayStream = nil
    }

    // MARK: - Coordinate Conversion

    /// Converts a point in view coordinates to display coordinates
    func convertToDisplayCoordinates(_ viewPoint: NSPoint) -> NSPoint? {
        guard currentResolution != .zero else { return nil }

        let normalizedX = viewPoint.x / bounds.width
        // Flip Y coordinate (view origin is bottom-left, but we want top-left for display)
        let normalizedY = (bounds.height - viewPoint.y) / bounds.height

        return NSPoint(
            x: normalizedX * currentResolution.width,
            y: normalizedY * currentResolution.height
        )
    }
}
