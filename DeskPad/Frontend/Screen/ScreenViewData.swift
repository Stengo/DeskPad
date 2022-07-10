import Foundation

struct ScreenViewData: ViewDataType {
    struct StateFragment: Equatable {
        let mouseLocationState: MouseLocationState
        let resolution: CGSize
    }

    static func fragment(of appState: AppState) -> StateFragment {
        return StateFragment(
            mouseLocationState: appState.mouseLocationState,
            resolution: appState.screenConfigurationState.resolution
        )
    }

    let isWindowHighlighted: Bool
    let resolution: CGSize

    init(for fragment: StateFragment) {
        isWindowHighlighted = fragment.mouseLocationState.isWithinScreen
        resolution = fragment.resolution
    }
}
