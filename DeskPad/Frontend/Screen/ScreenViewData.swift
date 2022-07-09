import Foundation

struct ScreenViewData: ViewDataType {
    struct StateFragment: Equatable {
        let mouseLocationState: MouseLocationState
    }

    static func fragment(of appState: AppState) -> StateFragment {
        return StateFragment(
            mouseLocationState: appState.mouseLocationState
        )
    }

    let isWindowHighlighted: Bool

    init(for fragment: StateFragment) {
        isWindowHighlighted = fragment.mouseLocationState.isWithinScreen
    }
}
