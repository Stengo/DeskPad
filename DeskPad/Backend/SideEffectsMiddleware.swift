import Foundation
import ReSwift

typealias SideEffect = (Action, @escaping DispatchFunction, @escaping () -> AppState?) -> Void

private let sideEffects: [SideEffect] = [
]

let sideEffectsMiddleware: Middleware<AppState> = { dispatch, getState in
    { originalDispatch in
        { action in
            originalDispatch(action)
            for sideEffect in sideEffects {
                sideEffect(action, dispatch, getState)
            }
        }
    }
}
