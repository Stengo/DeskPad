import Combine
import Foundation
import ReSwift

enum ScreenConfigurationAction: Action {
    case set(resolution: CGSize, scaleFactor: CGFloat)
}

@MainActor
final class ScreenConfigurationSideEffect {
    private var notificationCancellable: AnyCancellable?
    private var getState: (() -> AppState?)?
    private var dispatch: DispatchFunction?

    nonisolated init() {}

    func start(dispatch: @escaping DispatchFunction, getState: @escaping () -> AppState?) {
        self.dispatch = dispatch
        self.getState = getState

        guard notificationCancellable == nil else { return }

        notificationCancellable = NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification, object: NSApplication.shared)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleScreenParametersChange()
            }
    }

    private func handleScreenParametersChange() {
        guard let screen = NSScreen.screens.first(where: {
            $0.displayID == getState?()?.screenConfigurationState.displayID
        }) else {
            return
        }

        dispatch?(ScreenConfigurationAction.set(
            resolution: screen.frame.size,
            scaleFactor: screen.backingScaleFactor
        ))
    }
}

func screenConfigurationSideEffect() -> SideEffect {
    let handler = ScreenConfigurationSideEffect()
    return { _, dispatch, getState in
        Task { @MainActor in
            handler.start(dispatch: dispatch, getState: getState)
        }
    }
}
