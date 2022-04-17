import Cocoa

class ViewController: NSViewController {
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    private var display: CGVirtualDisplay?
    private var stream: CGDisplayStream?

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
        self.display = display

        let settings = CGVirtualDisplaySettings()
        settings.hiDPI = 2
        settings.modes = [
            CGVirtualDisplayMode(width: 1920, height: 1200, refreshRate: 60),
        ]
        display.apply(settings)

        let stream = CGDisplayStream(
            dispatchQueueDisplay: display.displayID,
            outputWidth: 1920,
            outputHeight: 1200,
            pixelFormat: 1_111_970_369, // BGRA
            properties: nil,
            queue: .main,
            handler: { [weak self] _, _, frameSurface, _ in
                if let surface = frameSurface {
                    self?.view.layer?.contents = surface
                }
            }
        )
        self.stream = stream
        if let error = stream?.start() {
            print(error)
        }
    }
}
