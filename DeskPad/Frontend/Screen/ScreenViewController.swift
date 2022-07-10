import Cocoa
import ReSwift

enum ScreenViewAction: Action {
    case setDisplayID(CGDirectDisplayID)
}

class ScreenViewController: SubscriberViewController<ScreenViewData> {
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    private var display: CGVirtualDisplay!
    private var stream: CGDisplayStream?
    private var isWindowHighlighted = false
    private var previousResolution: CGSize?

    override func viewDidLoad() {
        super.viewDidLoad()

        let desc = CGVirtualDisplayDescriptor()
        desc.setDispatchQueue(DispatchQueue.main)
        desc.name = "DeskPad Display"
        desc.maxPixelsWide = 1920
        desc.maxPixelsHigh = 1200
        desc.sizeInMillimeters = CGSize(width: 1600, height: 1000)
        desc.productID = 0x1234
        desc.vendorID = 0x3456
        desc.serialNum = 0x0001

        let display = CGVirtualDisplay(descriptor: desc)
        store.dispatch(ScreenViewAction.setDisplayID(display.displayID))
        self.display = display

        let settings = CGVirtualDisplaySettings()
        let sizes: [CGSize] = [
            CGSize(width: 1920, height: 1200),
            CGSize(width: 1680, height: 1050),
            CGSize(width: 1440, height: 900),
            CGSize(width: 1280, height: 800),
        ]
        let refreshRates: [CGFloat] = [
            60,
            50,
            30,
            25,
        ]
        let modes = refreshRates.flatMap { refreshRate in
            sizes.map { size in
                CGVirtualDisplayMode(
                    width: UInt(size.width),
                    height: UInt(size.height),
                    refreshRate: refreshRate
                )
            }
        }
        settings.modes = modes
        display.apply(settings)
    }

    override func update(with viewData: ScreenViewData) {
        if viewData.isWindowHighlighted != isWindowHighlighted {
            isWindowHighlighted = viewData.isWindowHighlighted
            view.window?.backgroundColor = isWindowHighlighted
                ? NSColor(named: "TitleBarActive")
                : NSColor(named: "TitleBarInactive")
            if isWindowHighlighted {
                view.window?.orderFrontRegardless()
            }
        }

        if viewData.resolution != .zero, viewData.resolution != previousResolution {
            previousResolution = viewData.resolution
            stream = nil
            view.window?.contentMinSize = viewData.resolution
            view.window?.contentMaxSize = viewData.resolution
            view.window?.setContentSize(viewData.resolution)
            view.window?.center()
            let stream = CGDisplayStream(
                dispatchQueueDisplay: display.displayID,
                outputWidth: Int(viewData.resolution.width),
                outputHeight: Int(viewData.resolution.height),
                pixelFormat: 1_111_970_369,
                properties: nil,
                queue: .main,
                handler: { [weak self] _, _, frameSurface, _ in
                    if let surface = frameSurface {
                        self?.view.layer?.contents = surface
                    }
                }
            )
            self.stream = stream
            stream?.start()
        }
    }
}
