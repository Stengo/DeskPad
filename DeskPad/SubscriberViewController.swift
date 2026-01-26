import AppKit
import ReSwift

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

    func newState(state: ViewData.StateFragment) {
        // ReSwift calls this on the same thread as dispatch (main thread in this app)
        // Use async to avoid potential re-entrancy issues during dispatch
        DispatchQueue.main.async { [weak self] in
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
