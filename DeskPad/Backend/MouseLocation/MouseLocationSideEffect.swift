import Combine
import Foundation
import ReSwift

enum MouseLocationAction: Action {
    case located(isWithinScreen: Bool)
    case requestMove(toPoint: NSPoint)
}

@MainActor
final class MouseLocationSideEffect {
    private var timerCancellable: AnyCancellable?
    private var getState: (() -> AppState?)?
    private var dispatch: DispatchFunction?

    nonisolated init() {}

    func start(dispatch: @escaping DispatchFunction, getState: @escaping () -> AppState?) {
        self.dispatch = dispatch
        self.getState = getState

        guard timerCancellable == nil else { return }

        timerCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkMouseLocation()
            }
    }

    func handleAction(_ action: Action) {
        guard case let MouseLocationAction.requestMove(point) = action else {
            return
        }

        guard let displayID = getState?()?.screenConfigurationState.displayID else {
            return
        }

        CGDisplayMoveCursorToPoint(displayID, point)
    }

    private func checkMouseLocation() {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenContainingMouse = screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
        let isWithinScreen = screenContainingMouse?.displayID == getState?()?.screenConfigurationState.displayID
        dispatch?(MouseLocationAction.located(isWithinScreen: isWithinScreen))
    }
}

func mouseLocationSideEffect() -> SideEffect {
    let handler = MouseLocationSideEffect()
    return { action, dispatch, getState in
        Task { @MainActor in
            handler.start(dispatch: dispatch, getState: getState)
            handler.handleAction(action)
        }
    }
}
