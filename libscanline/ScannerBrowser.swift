//
//  ScannerBrowser.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//  Copyright © 2017 Scott J. Kleper. All rights reserved.
//

import Foundation
import ImageCaptureCore

public protocol ScannerBrowserDelegate: AnyObject {
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didFinishBrowsingWithScanner scanner: ICScannerDevice?)
    func scannerBrowser(_ scannerBrowser: ScannerBrowser, didUpdateAvailableScanners availableScanners: [String])
}

public class ScannerBrowser: NSObject, ICDeviceBrowserDelegate {
    let logger: Logger
    let deviceBrowser = ICDeviceBrowser()
    var selectedScanner: ICScannerDevice?
    public var configuration: ScanConfiguration
    var searching: Bool
    var availableScannerNames: [String] = []
    
    public weak var delegate: ScannerBrowserDelegate?
    
    public init(configuration: ScanConfiguration, logger: Logger) {
        self.configuration = configuration
        self.logger = logger
        self.searching = false
        
        super.init()
        
        deviceBrowser.delegate = self
        let mask = ICDeviceTypeMask(rawValue:
            ICDeviceTypeMask.scanner.rawValue |
                ICDeviceLocationTypeMask.local.rawValue |
                ICDeviceLocationTypeMask.bonjour.rawValue |
                ICDeviceLocationTypeMask.shared.rawValue)
        deviceBrowser.browsedDeviceTypeMask = mask!
    }
    
    public func browse() {
        logger.verbose("Browsing for scanners.")
        searching = true

        if configuration.config[ScanlineConfigOptionList] != nil {
            logger.log("Available scanners:")
        }
        deviceBrowser.start()
    }
    
    public func stopBrowsing() {
        guard searching else { return }
        logger.verbose("Done searching for scanners")

        delegate?.scannerBrowser(self, didFinishBrowsingWithScanner: selectedScanner)
        searching = false
    }
    
    private func deviceMatchesSpecified(device: ICScannerDevice) -> Bool {
        // If no name was specified, this is perforce an exact match
        guard let desiredName = configuration.config[ScanlineConfigOptionScanner] as? String else { return configuration.config[ScanlineConfigOptionList] == nil }
        guard let deviceName = device.name else { return false }
        
        // "Fuzzy" match -- case-free compare of prefix
        if configuration.config[ScanlineConfigOptionExactName] == nil &&
            deviceName.lowercased().starts(with: desiredName.lowercased()) {
            return true
        }
        
        if desiredName == deviceName {
            return true
        }
        
        return false
    }
    
    public func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        logger.verbose("Added device: \(device)")
        if configuration.config[ScanlineConfigOptionList] != nil {
            logger.log("* \(device.name ?? "[Nameless Device]")")
        }
        
        guard let scannerDevice = device as? ICScannerDevice else { return }

        if let scannerName = scannerDevice.name {
            availableScannerNames.append(scannerName)
            delegate?.scannerBrowser(self, didUpdateAvailableScanners: availableScannerNames)
        }
        
        if deviceMatchesSpecified(device: scannerDevice) {
            selectedScanner = scannerDevice
            stopBrowsing()
        }
    }
    
    public func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
        logger.verbose("Removed device: \(device)")
        guard let _ = device as? ICScannerDevice, let scannerName = device.name else { return }

        availableScannerNames.removeAll(where: { $0 == scannerName })
        delegate?.scannerBrowser(self, didUpdateAvailableScanners: availableScannerNames)
    }
}

