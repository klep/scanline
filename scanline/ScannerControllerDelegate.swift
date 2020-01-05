//
//  This code is part of scanline and published under MIT license.
//

import Foundation

protocol ScannerControllerDelegate: class {
    func scannerControllerDidFail(_ scannerController: ScannerController)
    func scannerControllerDidSucceed(_ scannerController: ScannerController)
}
