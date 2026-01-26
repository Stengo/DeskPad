import Cocoa
import Combine

/// Main view controller for the DeskPad display window
final class DeskPadViewController: NSViewController, NSWindowDelegate {
    // MARK: - Properties

    private var displayManager: VirtualDisplayManager!
    private var mouseTracker: MouseTracker!
    private var renderer: DisplayStreamRenderer!
    private var cancellables = Set<AnyCancellable>()
    private var isWindowHighlighted = false

    // MARK: - Constants

    private enum Constants {
        static let windowSnappingThreshold: CGFloat = 30
    }

    // MARK: - Initialization

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        renderer = DisplayStreamRenderer(frame: NSRect(x: 0, y: 0, width: 1280, height: 720))
        view = renderer

        // Add click gesture
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        view.addGestureRecognizer(clickGesture)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create managers
        displayManager = VirtualDisplayManager()
        mouseTracker = MouseTracker()

        // Set up bindings for state changes
        setupBindings()

        // Create virtual display immediately
        displayManager.create()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        renderer.stopStream()
        mouseTracker.stopTracking()
        displayManager.destroy()
    }

    // MARK: - Bindings

    private func setupBindings() {
        // When display becomes ready, configure everything
        displayManager.$isReady
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReady in
                guard isReady else { return }
                self?.onDisplayReady()
            }
            .store(in: &cancellables)

        // Update window highlight based on mouse position
        mouseTracker.$isWithinVirtualDisplay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isWithin in
                self?.updateWindowHighlight(isWithin)
            }
            .store(in: &cancellables)

        // React to resolution changes
        displayManager.$resolution
            .dropFirst() // Skip initial value
            .receive(on: DispatchQueue.main)
            .sink { [weak self] resolution in
                guard let self, resolution != .zero else { return }
                self.onResolutionChanged(resolution)
            }
            .store(in: &cancellables)
    }

    // MARK: - Display Configuration

    private func onDisplayReady() {
        print("[DeskPadViewController] onDisplayReady called")

        guard let displayID = displayManager.displayID else {
            print("[DeskPadViewController] No displayID")
            return
        }

        let resolution = displayManager.resolution
        let scaleFactor = displayManager.scaleFactor

        print("[DeskPadViewController] Resolution: \(resolution), Scale: \(scaleFactor)")

        // Configure window size
        if let window = view.window, resolution != .zero {
            print("[DeskPadViewController] Setting window size to: \(resolution)")
            window.setContentSize(resolution)
            window.contentAspectRatio = resolution
            window.center()
        }

        // Start streaming
        if resolution != .zero {
            print("[DeskPadViewController] Starting stream for displayID: \(displayID)")
            renderer.configure(displayID: displayID, resolution: resolution, scaleFactor: scaleFactor)
        }

        // Start mouse tracking
        mouseTracker.startTracking(displayID: displayID)
        print("[DeskPadViewController] Mouse tracking started")
    }

    private func onResolutionChanged(_ resolution: CGSize) {
        guard let displayID = displayManager.displayID else { return }

        // Update window
        if let window = view.window {
            window.setContentSize(resolution)
            window.contentAspectRatio = resolution
        }

        // Reconfigure stream
        renderer.configure(
            displayID: displayID,
            resolution: resolution,
            scaleFactor: displayManager.scaleFactor
        )
    }

    // MARK: - Window Highlight

    private func updateWindowHighlight(_ highlighted: Bool) {
        guard highlighted != isWindowHighlighted else { return }
        isWindowHighlighted = highlighted

        view.window?.backgroundColor = highlighted
            ? NSColor(named: "TitleBarActive") ?? .windowBackgroundColor
            : NSColor(named: "TitleBarInactive") ?? .white

        if highlighted {
            view.window?.orderFrontRegardless()
        }
    }

    // MARK: - Input Handling

    @objc private func handleClick(_ gesture: NSClickGestureRecognizer) {
        let viewPoint = gesture.location(in: view)

        guard let displayPoint = renderer.convertToDisplayCoordinates(viewPoint) else {
            return
        }

        mouseTracker.moveCursor(to: displayPoint)
    }

    // MARK: - NSWindowDelegate

    func windowWillResize(_ window: NSWindow, to frameSize: NSSize) -> NSSize {
        let contentSize = window.contentRect(forFrameRect: NSRect(origin: .zero, size: frameSize)).size
        let resolution = displayManager.resolution

        // Snap to exact resolution if close
        if resolution != .zero,
           abs(contentSize.width - resolution.width) < Constants.windowSnappingThreshold
        {
            return window.frameRect(forContentRect: NSRect(origin: .zero, size: resolution)).size
        }

        return frameSize
    }
}
