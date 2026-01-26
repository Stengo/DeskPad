import Cocoa
import Combine

/// Tracks mouse position and handles cursor movement
@MainActor
final class MouseTracker: ObservableObject {
    // MARK: - Published State

    @Published private(set) var isWithinVirtualDisplay = false

    // MARK: - Private Properties

    private var timerSubscription: AnyCancellable?
    private var displayID: CGDirectDisplayID?

    // MARK: - Constants

    private enum Constants {
        static let trackingInterval: TimeInterval = 0.25
    }

    // MARK: - Initialization

    init() {}

    deinit {
        timerSubscription?.cancel()
    }

    // MARK: - Public Methods

    /// Starts tracking mouse position relative to the virtual display
    func startTracking(displayID: CGDirectDisplayID) {
        self.displayID = displayID

        // Stop any existing subscription
        stopTracking()

        // Start polling timer using Combine
        timerSubscription = Timer.publish(every: Constants.trackingInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMouseLocation()
            }
    }

    /// Stops tracking mouse position
    func stopTracking() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    /// Moves the cursor to the specified point on the virtual display
    nonisolated func moveCursor(to point: NSPoint) {
        guard let displayID = MainActor.assumeIsolated({ self.displayID }) else { return }
        CGDisplayMoveCursorToPoint(displayID, point)
    }

    // MARK: - Private Methods

    private func updateMouseLocation() {
        guard let displayID = displayID else {
            isWithinVirtualDisplay = false
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens

        // Find which screen contains the mouse
        let screenContainingMouse = screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        }

        // Check if it's the virtual display
        isWithinVirtualDisplay = screenContainingMouse?.displayID == displayID
    }
}
