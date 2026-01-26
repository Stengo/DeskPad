import Combine
import Foundation
import ReSwift

enum MouseLocationAction: Action {
    case located(isWithinScreen: Bool)
    case requestMove(toPoint: NSPoint)
}

private var timerCancellable: AnyCancellable?

func mouseLocationSideEffect() -> SideEffect {
    return { action, dispatch, getState in
        // Set up timer on first action (runs on main thread via Combine)
        if timerCancellable == nil {
            timerCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    let mouseLocation = NSEvent.mouseLocation
                    let screens = NSScreen.screens
                    let screenContainingMouse = screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
                    let isWithinScreen = screenContainingMouse?.displayID == getState()?.screenConfigurationState.displayID
                    dispatch(MouseLocationAction.located(isWithinScreen: isWithinScreen))
                }
        }

        // Handle move cursor action
        if case let MouseLocationAction.requestMove(point) = action,
           let displayID = getState()?.screenConfigurationState.displayID
        {
            CGDisplayMoveCursorToPoint(displayID, point)
        }
    }
}
