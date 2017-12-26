//
//  main.swift
//  scanline
//
//  Created by Scott J. Kleper on 12/2/17.
//  Copyright © 2017 Scott J. Kleper. All rights reserved.
//

import Foundation

let appController = ScanlineAppController(arguments: CommandLine.arguments)
appController.go()

CFRunLoopRun()

print("Done")
