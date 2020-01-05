//
//  This code is part of scanline and published under MIT license.
//

import Foundation

let appController = ScanlineAppController(arguments: CommandLine.arguments)
appController.go()

CFRunLoopRun()
