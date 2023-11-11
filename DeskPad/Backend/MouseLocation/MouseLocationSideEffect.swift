import Foundation
import ReSwift

private var timer: Timer?

enum MouseLocationAction: Action {
    case located(isWithinScreen: Bool)
    case requestMove(toPoint: NSPoint)
}

func mouseLocationSideEffect() -> SideEffect {
    return { action, dispatch, getState in
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                let mouseLocation = NSEvent.mouseLocation
                let screens = NSScreen.screens
                let screenContainingMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
                let isWithinScreen = screenContainingMouse?.displayID == getState()?.screenConfigurationState.displayID
                dispatch(MouseLocationAction.located(isWithinScreen: isWithinScreen))
            }
        }
        switch action {
        case let MouseLocationAction.requestMove(point):
            guard let displayID = getState()?.screenConfigurationState.displayID else {
                return
            }
            CGDisplayMoveCursorToPoint(displayID, point)
        default:
            return
        }
    }
}
