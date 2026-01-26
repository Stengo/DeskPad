import Cocoa
import Combine

/// Main view controller for the DeskPad display window
final class DeskPadViewController: NSViewController, NSWindowDelegate {
    // MARK: - Dependencies

    private let displayManager: VirtualDisplayManager
    private let mouseTracker: MouseTracker

    // MARK: - Views

    private var renderer: DisplayStreamRenderer!

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()
    private var isWindowHighlighted = false

    // MARK: - Constants

    private enum Constants {
        static let windowSnappingThreshold: CGFloat = 30
    }

    // MARK: - Initialization

    init(displayManager: VirtualDisplayManager, mouseTracker: MouseTracker) {
        self.displayManager = displayManager
        self.mouseTracker = mouseTracker
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        renderer = DisplayStreamRenderer(frame: .zero)
        view = renderer

        // Add click gesture
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        view.addGestureRecognizer(clickGesture)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // Create virtual display when view appears
        displayManager.create()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()

        // Clean up when view disappears
        renderer.stopStream()
        mouseTracker.stopTracking()
    }

    // MARK: - Bindings

    private func setupBindings() {
        // When display becomes ready, configure the renderer and start tracking
        displayManager.$isReady
            .combineLatest(displayManager.$displayID, displayManager.$resolution, displayManager.$scaleFactor)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReady, displayID, resolution, scaleFactor in
                guard isReady, let displayID = displayID, resolution != .zero else { return }
                self?.configureDisplay(displayID: displayID, resolution: resolution, scaleFactor: scaleFactor)
            }
            .store(in: &cancellables)

        // Update window highlight based on mouse position
        mouseTracker.$isWithinVirtualDisplay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isWithin in
                self?.updateWindowHighlight(isWithin)
            }
            .store(in: &cancellables)
    }

    // MARK: - Display Configuration

    private func configureDisplay(displayID: CGDirectDisplayID, resolution: CGSize, scaleFactor: CGFloat) {
        // Configure window
        configureWindow(for: resolution)

        // Start streaming
        renderer.configure(displayID: displayID, resolution: resolution, scaleFactor: scaleFactor)

        // Start mouse tracking
        mouseTracker.startTracking(displayID: displayID)
    }

    private func configureWindow(for resolution: CGSize) {
        guard let window = view.window else { return }

        window.setContentSize(resolution)
        window.contentAspectRatio = resolution
        window.center()
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

        // Snap to exact resolution if close
        let resolution = displayManager.resolution
        if resolution != .zero,
           abs(contentSize.width - resolution.width) < Constants.windowSnappingThreshold
        {
            return window.frameRect(forContentRect: NSRect(origin: .zero, size: resolution)).size
        }

        return frameSize
    }
}
