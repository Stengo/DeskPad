import Combine
import Foundation

/// Tracks mouse position and handles cursor movement
final class MouseTracker: ObservableObject {
    // MARK: - Published State

    @Published private(set) var isWithinVirtualDisplay = false

    // MARK: - Private Properties

    private var timer: Timer?
    private var displayID: CGDirectDisplayID?
    private let trackingInterval: TimeInterval = 0.25

    // MARK: - Initialization

    init() {}

    deinit {
        stopTracking()
    }

    // MARK: - Public Methods

    /// Starts tracking mouse position relative to the virtual display
    func startTracking(displayID: CGDirectDisplayID) {
        self.displayID = displayID

        // Stop any existing timer
        stopTracking()

        // Start polling timer
        timer = Timer.scheduledTimer(withTimeInterval: trackingInterval, repeats: true) { [weak self] _ in
            self?.updateMouseLocation()
        }
    }

    /// Stops tracking mouse position
    func stopTracking() {
        timer?.invalidate()
        timer = nil
    }

    /// Moves the cursor to the specified point on the virtual display
    func moveCursor(to point: NSPoint) {
        guard let displayID = displayID else { return }
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
