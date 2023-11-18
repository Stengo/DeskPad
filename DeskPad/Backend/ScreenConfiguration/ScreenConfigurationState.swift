import Foundation
import ReSwift

struct ScreenConfigurationState: Equatable {
    let resolution: CGSize
    let scaleFactor: CGFloat
    let displayID: CGDirectDisplayID?

    static var initialState: ScreenConfigurationState {
        return ScreenConfigurationState(
            resolution: .zero,
            scaleFactor: 1,
            displayID: nil
        )
    }
}

func screenConfigurationReducer(action: Action, state: ScreenConfigurationState) -> ScreenConfigurationState {
    switch action {
    case let ScreenConfigurationAction.set(resolution, scaleFactor):
        return ScreenConfigurationState(
            resolution: resolution,
            scaleFactor: scaleFactor,
            displayID: state.displayID
        )

    case let ScreenViewAction.setDisplayID(displayID):
        return ScreenConfigurationState(
            resolution: state.resolution,
            scaleFactor: state.scaleFactor,
            displayID: displayID
        )

    default:
        return state
    }
}
