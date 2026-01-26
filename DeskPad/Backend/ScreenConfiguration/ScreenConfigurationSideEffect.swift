import Combine
import Foundation
import ReSwift

enum ScreenConfigurationAction: Action {
    case set(resolution: CGSize, scaleFactor: CGFloat)
}

private var notificationCancellable: AnyCancellable?

func screenConfigurationSideEffect() -> SideEffect {
    return { _, dispatch, getState in
        // Set up notification observer on first action (runs on main thread via Combine)
        if notificationCancellable == nil {
            notificationCancellable = NotificationCenter.default
                .publisher(for: NSApplication.didChangeScreenParametersNotification, object: NSApplication.shared)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    guard let screen = NSScreen.screens.first(where: {
                        $0.displayID == getState()?.screenConfigurationState.displayID
                    }) else {
                        return
                    }

                    dispatch(ScreenConfigurationAction.set(
                        resolution: screen.frame.size,
                        scaleFactor: screen.backingScaleFactor
                    ))
                }
        }
    }
}
