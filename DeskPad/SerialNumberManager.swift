import Cocoa

class SerialNumberManager {
    static let shared = SerialNumberManager()

    private(set) var claimedSerial: UInt32?

    private let fileCoordinator = NSFileCoordinator()
    private let registryURL: URL

    private init() {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Could not find Application Support directory.")
        }

        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.YourAppBundleID"
        let appDirectoryURL = appSupportURL.appendingPathComponent(bundleID, isDirectory: true)

        try? fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        registryURL = appDirectoryURL.appendingPathComponent("serials.json", isDirectory: false)
    }

    func claimSerial() {
        var coordinationError: NSError?

        fileCoordinator.coordinate(writingItemAt: registryURL, options: .forMerging, error: &coordinationError) { url in
            var activeSerials = [pid_t: UInt32]()
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([pid_t: UInt32].self, from: data)
            {
                activeSerials = decoded
            }

            for (pid, _) in activeSerials {
                if NSRunningApplication(processIdentifier: pid) == nil {
                    activeSerials.removeValue(forKey: pid)
                }
            }

            let usedSerials = Set<UInt32>(activeSerials.values)
            var newSerial: UInt32 = 1
            while usedSerials.contains(newSerial) {
                newSerial += 1
            }

            let myPID = ProcessInfo.processInfo.processIdentifier
            activeSerials[myPID] = newSerial
            self.claimedSerial = newSerial

            if let data = try? JSONEncoder().encode(activeSerials) {
                try? data.write(to: url, options: .atomic)
            }
        }

        if let error = coordinationError {
            print("🚨 Coordination Error during claim: \(error)")
        }
    }

    func releaseSerial() {
        var coordinationError: NSError?

        fileCoordinator.coordinate(writingItemAt: registryURL, options: .forMerging, error: &coordinationError) { url in
            guard let data = try? Data(contentsOf: url),
                  var activeSerials = try? JSONDecoder().decode([pid_t: Int].self, from: data)
            else {
                return
            }

            let myPID = ProcessInfo.processInfo.processIdentifier
            if activeSerials.removeValue(forKey: myPID) != nil {
                if let data = try? JSONEncoder().encode(activeSerials) {
                    try? data.write(to: url, options: .atomic)
                }
            }
        }

        if let error = coordinationError {
            print("🚨 Coordination Error during release: \(error)")
        }
    }
}
