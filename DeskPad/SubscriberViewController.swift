import AppKit
import ReSwift

@MainActor
class SubscriberViewController<ViewData: ViewDataType>: NSViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = ViewData.StateFragment

    override func viewWillAppear() {
        super.viewWillAppear()

        store.subscribe(self) { subscription in
            subscription
                .select(ViewData.fragment(of:))
                .skipRepeats()
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        store.unsubscribe(self)
    }

    nonisolated func newState(state: ViewData.StateFragment) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.update(with: ViewData(for: state))
        }
    }

    func update(with _: ViewData) {
        assertionFailure("Please override the SubscriberViewController update method.")
    }
}

protocol ViewDataType {
    associatedtype StateFragment: Equatable

    static func fragment(of appState: AppState) -> StateFragment

    init(for fragment: StateFragment)
}
