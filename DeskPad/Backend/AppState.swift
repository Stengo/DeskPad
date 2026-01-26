import ReSwift

struct AppState: Equatable, Sendable {
    let mouseLocationState: MouseLocationState
    let screenConfigurationState: ScreenConfigurationState

    static var initialState: AppState {
        AppState(
            mouseLocationState: .initialState,
            screenConfigurationState: .initialState
        )
    }
}

func appReducer(action: Action, state: AppState?) -> AppState {
    let state = state ?? .initialState

    return AppState(
        mouseLocationState: mouseLocationReducer(action: action, state: state.mouseLocationState),
        screenConfigurationState: screenConfigurationReducer(action: action, state: state.screenConfigurationState)
    )
}
