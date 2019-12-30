//
//  ScannerControllerDelegate.swift
//  scanline
//
//  Created by Florian Dreier on 12/30/19.
//  Copyright © 2019 Scott J. Kleper. All rights reserved.
//

import Foundation

protocol ScannerControllerDelegate: class {
    func scannerControllerDidFail(_ scannerController: ScannerController)
    func scannerControllerDidSucceed(_ scannerController: ScannerController)
}
