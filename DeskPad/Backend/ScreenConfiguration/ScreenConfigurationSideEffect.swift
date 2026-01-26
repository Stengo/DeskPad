import Combine
import Foundation
import ReSwift

enum ScreenConfigurationAction: Action {
    case set(resolution: CGSize, scaleFactor: CGFloat)
}

private var notificationCancellable: AnyCancellable?

func screenConfigurationSideEffect() -> SideEffect {
    return { action, dispatch, getState in
        // Set up notification observer on first action
        if notificationCancellable == nil {
            notificationCancellable = NotificationCenter.default
                .publisher(for: NSApplication.didChangeScreenParametersNotification, object: NSApplication.shared)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    updateScreenConfiguration(dispatch: dispatch, getState: getState)
                }
        }

        // When displayID is set, query the initial screen configuration
        // This handles the case where the notification fired before the observer was set up
        if case ScreenViewAction.setDisplayID = action {
            // Use async to allow the virtual display to fully initialize
            DispatchQueue.main.async {
                updateScreenConfiguration(dispatch: dispatch, getState: getState)
            }
        }
    }
}

private func updateScreenConfiguration(dispatch: @escaping DispatchFunction, getState: @escaping () -> AppState?) {
    guard let displayID = getState()?.screenConfigurationState.displayID,
          let screen = NSScreen.screens.first(where: { $0.displayID == displayID })
    else {
        return
    }

    dispatch(ScreenConfigurationAction.set(
        resolution: screen.frame.size,
        scaleFactor: screen.backingScaleFactor
    ))
}
