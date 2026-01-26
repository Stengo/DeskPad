import Cocoa
import Combine
import Metal
import MetalKit

/// Metal-based renderer for the display stream
final class DisplayStreamRenderer: NSView {
    // MARK: - Properties

    private var displayStream: CGDisplayStream?
    private var metalLayer: CAMetalLayer!
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!

    private var currentDisplayID: CGDirectDisplayID?
    private var currentResolution: CGSize = .zero
    private var currentScaleFactor: CGFloat = 1.0

    /// BGRA pixel format as 32-bit integer
    private let pixelFormat: Int32 = 1_111_970_369

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupMetal()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMetal()
    }

    deinit {
        stopStream()
    }

    // MARK: - Setup

    private func setupMetal() {
        wantsLayer = true

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        self.device = device
        self.commandQueue = device.makeCommandQueue()

        // Create Metal layer
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = false
        metalLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0

        layer = metalLayer
    }

    override func layout() {
        super.layout()
        metalLayer?.frame = bounds
        metalLayer?.drawableSize = CGSize(
            width: bounds.width * (window?.backingScaleFactor ?? 2.0),
            height: bounds.height * (window?.backingScaleFactor ?? 2.0)
        )
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
            pixelFormat: pixelFormat,
            properties: [
                CGDisplayStream.showCursor: true,
            ] as CFDictionary,
            queue: .main,
            handler: { [weak self] _, _, frameSurface, _ in
                guard let surface = frameSurface else { return }
                self?.renderFrame(surface)
            }
        )

        self.displayStream = stream
        stream?.start()
    }

    /// Stops the display stream
    func stopStream() {
        displayStream?.stop()
        displayStream = nil
    }

    // MARK: - Rendering

    private func renderFrame(_ surface: IOSurfaceRef) {
        // For simplicity and efficiency, we'll use the CALayer contents approach
        // which is already GPU-optimized via IOSurface
        // Metal rendering would be used for additional post-processing
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        metalLayer.contents = surface
        CATransaction.commit()
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
