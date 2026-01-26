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
        print("[DisplayStreamRenderer] setupMetal called")
        wantsLayer = true

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[DisplayStreamRenderer] Metal is not supported on this device")
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
        print("[DisplayStreamRenderer] Metal setup complete")
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
        print("[DisplayStreamRenderer] configure called - displayID: \(displayID), resolution: \(resolution), scaleFactor: \(scaleFactor)")

        // Skip if already configured with same parameters
        if displayID == currentDisplayID,
           resolution == currentResolution,
           scaleFactor == currentScaleFactor,
           displayStream != nil
        {
            print("[DisplayStreamRenderer] Already configured with same parameters, skipping")
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

        print("[DisplayStreamRenderer] Creating stream with outputWidth: \(outputWidth), outputHeight: \(outputHeight)")

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
            handler: { [weak self] status, _, frameSurface, _ in
                if status != .frameComplete {
                    print("[DisplayStreamRenderer] Stream status: \(status.rawValue)")
                }
                guard let surface = frameSurface else {
                    return
                }
                self?.renderFrame(surface)
            }
        )

        if let stream = stream {
            self.displayStream = stream
            let startResult = stream.start()
            print("[DisplayStreamRenderer] Stream created and started with result: \(startResult.rawValue)")
        } else {
            print("[DisplayStreamRenderer] ERROR: Failed to create CGDisplayStream!")
        }
    }

    /// Stops the display stream
    func stopStream() {
        displayStream?.stop()
        displayStream = nil
    }

    // MARK: - Rendering

    private var frameCount = 0

    private func renderFrame(_ surface: IOSurfaceRef) {
        frameCount += 1
        if frameCount == 1 || frameCount % 60 == 0 {
            print("[DisplayStreamRenderer] Rendering frame #\(frameCount)")
        }

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
