import Foundation
import ReSwift

struct ScreenConfigurationState: Equatable {
    let resolution: CGSize
    let displayID: CGDirectDisplayID?

    static var initialState: ScreenConfigurationState {
        return ScreenConfigurationState(
            resolution: .zero,
            displayID: nil
        )
    }
}

func screenConfigurationReducer(action: Action, state: ScreenConfigurationState) -> ScreenConfigurationState {
    switch action {
    case let ScreenConfigurationAction.setResolution(resolution):
        return ScreenConfigurationState(resolution: resolution, displayID: state.displayID)

    case let ScreenViewAction.setDisplayID(displayID):
        return ScreenConfigurationState(resolution: state.resolution, displayID: displayID)

    default:
        return state
    }
}
