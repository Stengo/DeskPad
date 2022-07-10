import Foundation
import ReSwift

private var isObserving = false

enum ScreenConfigurationAction: Action {
    case setResolution(CGSize)
}

func screenConfigurationSideEffect() -> SideEffect {
    return { _, dispatch, getState in
        if isObserving == false {
            isObserving = true
            NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: NSApplication.shared,
                queue: .main
            ) { _ in
                guard let screen = NSScreen.screens.first(where: {
                    $0.displayID == getState()?.screenConfigurationState.displayID
                }) else {
                    return
                }
                dispatch(ScreenConfigurationAction.setResolution(screen.frame.size))
            }
        }
    }
}
