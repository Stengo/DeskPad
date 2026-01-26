import Foundation

extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            assertionFailure("Failed to get display ID from NSScreen")
            return 0
        }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }
}
