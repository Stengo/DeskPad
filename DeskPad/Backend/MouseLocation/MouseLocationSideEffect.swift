import Foundation
import ReSwift

private var timer: Timer?

enum MouseLocationAction: Action {
    case located(isWithinScreen: Bool)
}

func mouseLocationSideEffect() -> SideEffect {
    return { _, dispatch, getState in
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                let mouseLocation = NSEvent.mouseLocation
                let screens = NSScreen.screens
                let screenContainingMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
                let isWithinScreen = screenContainingMouse?.displayID == getState()?.screenConfigurationState.displayID
                dispatch(MouseLocationAction.located(isWithinScreen: isWithinScreen))
            }
        }
    }
}
