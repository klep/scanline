//
//  This code is part of scanline and published under MIT license.
//

import Foundation

class Logger: NSObject {
    let configuration: ScanConfiguration
    
    init(configuration: ScanConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    func verbose(_ message: String) {
        guard configuration.verbose else { return }
        print(message)
    }
    
    func log(_ message: String) {
        print(message)
    }
}
