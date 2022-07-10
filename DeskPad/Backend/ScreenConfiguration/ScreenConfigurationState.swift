import Foundation
import ReSwift

struct ScreenConfigurationState: Equatable {
    let resolution: CGSize

    static var initialState: ScreenConfigurationState {
        return ScreenConfigurationState(resolution: .zero)
    }
}

func screenConfigurationReducer(action: Action, state: ScreenConfigurationState) -> ScreenConfigurationState {
    switch action {
    case let ScreenConfigurationAction.setResolution(resolution):
        return ScreenConfigurationState(resolution: resolution)

    default:
        return state
    }
}
