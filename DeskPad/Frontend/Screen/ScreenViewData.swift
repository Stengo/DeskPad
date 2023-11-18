import Foundation

struct ScreenViewData: ViewDataType {
    struct StateFragment: Equatable {
        let mouseLocationState: MouseLocationState
        let screenConfiguration: ScreenConfigurationState
    }

    static func fragment(of appState: AppState) -> StateFragment {
        return StateFragment(
            mouseLocationState: appState.mouseLocationState,
            screenConfiguration: appState.screenConfigurationState
        )
    }

    let isWindowHighlighted: Bool
    let resolution: CGSize
    let scaleFactor: CGFloat

    init(for fragment: StateFragment) {
        isWindowHighlighted = fragment.mouseLocationState.isWithinScreen
        resolution = fragment.screenConfiguration.resolution
        scaleFactor = fragment.screenConfiguration.scaleFactor
    }
}
