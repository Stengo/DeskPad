import ReSwift

struct AppState: Equatable {
    let mouseLocationState: MouseLocationState

    static var initialState: AppState {
        return AppState(
            mouseLocationState: .initialState
        )
    }
}

func appReducer(action: Action, state: AppState?) -> AppState {
    let state = state ?? .initialState

    return AppState(
        mouseLocationState: mouseLocationReducer(action: action, state: state.mouseLocationState)
    )
}
