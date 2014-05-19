/*
     File: AppController.m
 */

#import "AppController.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

/*
 *****
 *
 *****
 KLEP TODO:
   x current problem -- can't select functional unit
        x timing issue?
        x what if you select it again after it selects the wrong one?
   x multipage scan doesn't work -- maybe need to wait for scancomplete message
   x increase default scan resolution
   x make it possible to configure scanner through command line options (flatbed, etc.)
   x make it possible to do double sided scanning or whatever it's called
   x clean it up!
   x -name option should also be used for aliases
   x allow customization of Archive directory, or provide sensible default that doesn't include "klep"
   x allow a .scanline.conf file to provide defaults
   x have log levels so you don't see tons of stuff scrolling on every scan
   x config unit tests
   x actual scanning unit tests
   x get rid of UI cruft
   x exit cfrunloop properly (timer?)
   x quit if no scanners are detected in a certain time period
   * add an option for scan resolution
   x scanner listing/selection (support for multiple scanners)
   x jpeg mode?
   x NEED TO FLUSH LOG BEFORE EXITING
   * need to delete temp scan file because a failed scan will copy over the same file
   * in fact, failed scans (such as feeder clogs) should be detected and errors reported
   * HELP mode, with -h or with no options at command line
   * Legal size scan mode if possible
 */

//---------------------------------------------------------------------------------------------------------------- AppController

@implementation AppController

@synthesize scanners = mScanners;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)setArguments:(const char* [])argv withCount:(int)argc
{
    NSMutableArray *argArray = [NSMutableArray arrayWithCapacity:argc];
    for (int i = 1; i < argc; i++) {
        [argArray addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
    }
    configuration = [[ScanConfiguration alloc] initWithArguments:argArray];
    mScannedDestinationURLs = [NSMutableArray arrayWithCapacity:1];
}

//------------------------------------------------------------------------------------------------------------------- initialize

+ (void)initialize
{
}

//----------------------------------------------------------------------------------------------- applicationDidFinishLaunching:

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    mScanners = [[NSMutableArray alloc] initWithCapacity:0];
    _successful = NO;

    mDeviceBrowser = [[ICDeviceBrowser alloc] init];
    mDeviceBrowser.delegate = self;
    mDeviceBrowser.browsedDeviceTypeMask = ICDeviceLocationTypeMaskLocal|ICDeviceLocationTypeMaskRemote|ICDeviceTypeMaskScanner;
    if ([configuration listOnly]) {
        DDLogInfo(@"Available scanners:");
    }
    [mDeviceBrowser start];
    
    DDLogVerbose(@"Looking for available scanners...");
    mDeviceTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(noDevicesFound:) userInfo:nil repeats:NO];
}

- (void)noDevicesFound:(NSTimer*)theTimer
{
    DDLogInfo(@"No scanners found.");
    [self exit];
}

//---------------------------------------------------------------------------------------------------- applicationWillTerminate:

- (void)exit
{
    [DDLog flushLog];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)applicationWillTerminate:(NSNotification*)notification
{
}

#pragma mark -
#pragma mark ICDeviceBrowser delegate methods

//------------------------------------------------------------------------------------------------------------------------------
// Please refer to the header files in ImageCaptureCore.framework for documentation about the following delegate methods.

//--------------------------------------------------------------------------------------- deviceBrowser:didAddDevice:moreComing:

- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{
    DDLogVerbose(@"Found scanner: %@", addedDevice.name);
    
    if ( (addedDevice.type & ICDeviceTypeMaskScanner) == ICDeviceTypeScanner )
    {
        if (mDeviceTimer) {
            [mDeviceTimer invalidate];
            mDeviceTimer = nil;
        }
        [mScanners addObject:addedDevice];
        addedDevice.delegate = self;
        if ([configuration listOnly]) {
            DDLogInfo(@"* %@", [addedDevice name]);
        }
    }
    
    if (!moreComing) {
        DDLogVerbose(@"All devices have been added.");
        if ([configuration listOnly]) {
            [self exit];
        } else {
            [self openCloseSession:nil];
        }
    }
}

//------------------------------------------------------------------------------------- deviceBrowser:didRemoveDevice:moreGoing:

- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)removedDevice moreGoing:(BOOL)moreGoing;
{
    DDLogVerbose( @"deviceBrowser:didRemoveDevice: \n%@\n", removedDevice );
}

//------------------------------------------------------------------------------------------- deviceBrowser:deviceDidChangeName:

- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeName:(ICDevice*)device;
{
    DDLogVerbose( @"deviceBrowser:\n%@\ndeviceDidChangeName: \n%@\n", browser, device );
}

//----------------------------------------------------------------------------------- deviceBrowser:deviceDidChangeSharingState:

- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeSharingState:(ICDevice*)device;
{
    DDLogVerbose( @"deviceBrowser:\n%@\ndeviceDidChangeSharingState: \n%@\n", browser, device );
}

//--------------------------------------------------------------------------------- deviceBrowser:didReceiveButtonPressOnDevice:

- (void)deviceBrowser:(ICDeviceBrowser*)browser requestsSelectDevice:(ICDevice*)device
{
    DDLogVerbose( @"deviceBrowser:\n%@\nrequestsSelectDevice: \n%@\n", browser, device );
}

#pragma mark -
#pragma mark ICDevice & ICScannerDevice delegate methods
//------------------------------------------------------------------------------------------------------------- didRemoveDevice:

- (void)didRemoveDevice:(ICDevice*)removedDevice
{
    DDLogVerbose( @"didRemoveDevice: \n%@\n", removedDevice );
}

//---------------------------------------------------------------------------------------------- device:didOpenSessionWithError:

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error
{
    DDLogVerbose( @"device:didOpenSessionWithError: \n" );
    DDLogVerbose( @"  error : %@\n", error );
    
    [self selectFunctionalUnit:0];
}

//-------------------------------------------------------------------------------------------------------- deviceDidBecomeReady:

- (void)deviceDidBecomeReady:(ICScannerDevice*)scanner
{
}

//--------------------------------------------------------------------------------------------- device:didCloseSessionWithError:

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error
{
    DDLogVerbose( @"device:didCloseSessionWithError: \n" );
    DDLogVerbose( @"  error : %@\n", error );
}

//--------------------------------------------------------------------------------------------------------- deviceDidChangeName:

- (void)deviceDidChangeName:(ICDevice*)device;
{
    DDLogVerbose( @"deviceDidChangeName: \n%@\n", device );
}

//------------------------------------------------------------------------------------------------- deviceDidChangeSharingState:

- (void)deviceDidChangeSharingState:(ICDevice*)device
{
    DDLogVerbose( @"deviceDidChangeSharingState: \n%@\n", device );
}

//------------------------------------------------------------------------------------------ device:didReceiveStatusInformation:

- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status
{
    DDLogVerbose( @"device: \n%@\ndidReceiveStatusInformation: \n%@\n", device, status );
    
    if ( [[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmingUp] )
    {
        DDLogInfo(@"Scanner warming up...");
    }
    else if ( [[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmUpDone] )
    {
        DDLogInfo(@"Scanner done warming up.");
    }
}

//---------------------------------------------------------------------------------------------------- device:didEncounterError:

- (void)device:(ICDevice*)device didEncounterError:(NSError*)error
{
    DDLogVerbose( @"device: \n%@\ndidEncounterError: \n%@\n", device, error );
}

//----------------------------------------------------------------------------------------- scannerDevice:didReceiveButtonPress:

- (void)device:(ICDevice*)device didReceiveButtonPress:(NSString*)button
{
    DDLogVerbose( @"device: \n%@\ndidReceiveButtonPress: \n%@\n", device, button );
}

//--------------------------------------------------------------------------------------------- scannerDeviceDidBecomeAvailable:

- (void)scannerDeviceDidBecomeAvailable:(ICScannerDevice*)scanner;
{
    DDLogVerbose( @"scannerDeviceDidBecomeAvailable: \n%@\n", scanner );
    [scanner requestOpenSession];
}

//--------------------------------------------------------------------------------- scannerDevice:didSelectFunctionalUnit:error:

- (void)scannerDevice:(ICScannerDevice*)scanner didSelectFunctionalUnit:(ICScannerFunctionalUnit*)functionalUnit error:(NSError*)error
{
    DDLogVerbose( @"  selected functionalUnitType: %ld\n", scanner.selectedFunctionalUnit.type);

    BOOL correctFunctionalUnit = ([configuration isFlatbed] && scanner.selectedFunctionalUnit.type == ICScannerFunctionalUnitTypeFlatbed) || (![configuration isFlatbed] && scanner.selectedFunctionalUnit.type == ICScannerFunctionalUnitTypeDocumentFeeder);
    if (correctFunctionalUnit && error == NULL) {
        DDLogInfo(@"Starting scan...");
        [self startScan:self];
    } else {
        DDLogVerbose( @"  error:          %@\n", error );
       [self selectFunctionalUnit:self];
    }

}

//--------------------------------------------------------------------------------------------- scannerDevice:didScanToURL:data:

- (void)scannerDevice:(ICScannerDevice*)scanner didScanToURL:(NSURL*)url data:(NSData*)data
{
    DDLogInfo(@"Scan complete.");
    DDLogVerbose( @"scannerDevice:didScanToURL:data: \n" );
    DDLogVerbose( @"  url:     %@", url );
    DDLogVerbose( @"  data:    %p\n", data );
    
    [mScannedDestinationURLs addObject:url];
}

//------------------------------------------------------------------------------ scannerDevice:didCompleteOverviewScanWithError:

- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteOverviewScanWithError:(NSError*)error;
{
    DDLogVerbose( @"scannerDevice: \n%@\ndidCompleteOverviewScanWithError: \n%@\n", scanner, error );
}

//-------------------------------------------------------------------------------------- scannerDevice:didCompleteScanWithError:

- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteScanWithError:(NSError*)error;
{
    DDLogVerbose( @"scannerDevice: \n%@\ndidCompleteScanWithError: \n%@\n", scanner, error );

    if ([configuration isBatch]) {
        DDLogError(@"Press RETURN to scan next page or S to stop");
        int userInput;
        userInput = getchar();
        if (userInput != 's' && userInput != 'S')
        {
            [self startScan:self];
            return;
        }
    }
    
    /*NSURL* scannedDestinationURL;
    if ([mScannedDestinationURLs count] > 1) {
        scannedDestinationURL = [self combinedScanDestinations];
    } else {
        scannedDestinationURL = [mScannedDestinationURLs objectAtIndex:0];
    }*/
    
    if ([configuration isJpeg]) {
        // need to loop through all the scanned jpegs and output each of them
        for (NSURL* scannedFile in mScannedDestinationURLs) {
            [self outputAndTagFile:scannedFile];
        }
    } else {
        // Combine the JPEGs into a single PDF
        NSURL* scannedDestinationURL = [self combinedScanDestinations];
        [self outputAndTagFile:scannedDestinationURL];
    }

    _successful = YES;
    [self exit];
}

#pragma mark -
//------------------------------------------------------------------------------------------------------------ openCloseSession:

- (void)outputAndTagFile:(NSURL*) scannedURL
{
    if (scannedURL == NULL) {
        DDLogError(@"No document was scanned.");
        [self exit];
    }
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:(NSYearCalendarUnit | NSHourCalendarUnit  | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    NSInteger year = [dateComponents year];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    // If there's a tag, move the file to the first tag location
    
    DDLogVerbose(@"creating directory");
    NSString* path = [configuration dir];
    if ([[configuration tags] count] > 0) {
        path = [NSString stringWithFormat:@"%@/%@/%ld", [configuration dir], [[configuration tags] objectAtIndex:0], year];
    }
    DDLogVerbose(@"path: %@", path);
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString* destinationFileExtension = ([configuration isJpeg] ? @"jpg" : @"pdf");
    NSString* destinationFileRoot = ([configuration name] == nil) ? [NSString stringWithFormat:@"%@/scan_%02ld%02ld%02ld", path, hour, minute, second] :
    [NSString stringWithFormat:@"%@/%@", path, [configuration name]];
    NSString* destinationFile = [NSString stringWithFormat:@"%@.%@", destinationFileRoot, destinationFileExtension];
    DDLogVerbose(@"destinationFileRoot: %@", destinationFileRoot);
    int i = 0;
    while ([fm fileExistsAtPath:destinationFile]) {
        destinationFile = [NSString stringWithFormat:@"%@_%d.%@", destinationFileRoot, i, destinationFileExtension];
        DDLogVerbose(@"destinationFile: %@", destinationFile);
        i++;
    }
    
    DDLogVerbose(@"about to copy %@ to %@", scannedURL, [NSURL fileURLWithPath:destinationFile]);
    [fm copyItemAtURL:scannedURL toURL:[NSURL fileURLWithPath:destinationFile] error:nil];
    DDLogVerbose(@"file copied");
    DDLogInfo(@"Scanned to: %@", destinationFile);
    
    // alias to all the other tag locations
    for (int i = 1; i < [[configuration tags] count]; i++) {
        DDLogVerbose(@"aliasing to tag: %@", [[configuration tags] objectAtIndex:i]);
        NSString* aliasDirPath = [NSString stringWithFormat:@"%@/%@/%ld", [configuration dir], [[configuration tags] objectAtIndex:i], year];
        [fm createDirectoryAtPath:aliasDirPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString* aliasFileRoot = ([configuration name] == nil) ? [NSString stringWithFormat:@"%@/scan_%02ld%02ld%02ld", aliasDirPath, hour, minute, second] :
        [NSString stringWithFormat:@"%@/%@", aliasDirPath, [configuration name]];
        NSString* aliasFilePath = [NSString stringWithFormat:@"%@.%@", aliasFileRoot, destinationFileExtension];
        int suffix = 0;
        while ([fm fileExistsAtPath:aliasFilePath]) {
            aliasFilePath = [NSString stringWithFormat:@"%@_%d.%@", aliasFileRoot, i, destinationFileExtension];
            suffix++;
        }
        DDLogVerbose(@"aliasing to %@", aliasFilePath);
        [fm createSymbolicLinkAtPath:aliasFilePath withDestinationPath:destinationFile error:nil];
        DDLogInfo(@"Aliased to: %@", aliasFilePath);
    }
}

- (NSURL*)combinedScanDestinations
{
    if ([mScannedDestinationURLs count] == 0) return NULL;
    
    PDFDocument *outputDocument = [[PDFDocument alloc] init];
    NSUInteger pageIndex = 0;
    for (NSURL* inputDocument in mScannedDestinationURLs) {
/*
        PDFDocument *inputPDF = [[PDFDocument alloc] initWithURL:inputDocument];
        for (int i = 0; i < [inputPDF pageCount]; i++) {
            [outputDocument insertPage:[inputPDF pageAtIndex:i] atIndex:pageIndex++];
        }
        [inputPDF release];*/
        // TODO: big memory leak here (?)
        PDFPage *thePage = [[PDFPage alloc] initWithImage:[[NSImage alloc] initByReferencingURL:inputDocument]];
        [outputDocument insertPage:thePage atIndex:pageIndex++];
    }
    
    // save the document
    NSString* tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"scan.pdf"];
    DDLogVerbose(@"writing to tempFile: %@", tempFile);
    [outputDocument writeToFile:tempFile];
    return [[NSURL alloc] initFileURLWithPath:tempFile];
}

- (void)go
{
    DDLogVerbose( @"go");
    
    [self applicationDidFinishLaunching:nil];
    
    // wait
  /*  while ([mScanners count] == 0) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        DDLogVerbose(@"waiting...");
    }*/
}

- (IBAction)openCloseSession:(id)sender
{
    if ( [self selectedScanner].hasOpenSession )
        [[self selectedScanner] requestCloseSession];
    else
        [[self selectedScanner] requestOpenSession];
}

//-------------------------------------------------------------------------------------------------------- selectFunctionalUnit:

- (IBAction)selectFunctionalUnit:(id)sender
{
    DDLogVerbose(@"setting functional unit");
    ICScannerDevice* scanner = [mScanners objectAtIndex:0];

    /*  ICScannerFunctionalUnit* unit = [[scanner availableFunctionalUnitTypes] objectAtIndex:0];
    
    for (int i = 0; i < [[scanner availableFunctionalUnitTypes] count]; i++) {
        ICScannerFunctionalUnit* thisUnit = [[scanner availableFunctionalUnitTypes] objectAtIndex:i];
        DDLogVerbose(@"this unit: %@", thisUnit);
        if (fFlatbed && thisUnit != nil && thisUnit.type == ICScannerFunctionalUnitTypeFlatbed) {
            DDLogVerbose(@"found flatbed");
            unit = thisUnit;
        } else if (!fFlatbed && thisUnit != nil && thisUnit.type == ICScannerFunctionalUnitTypeDocumentFeeder) {
            DDLogVerbose(@"FOUND DOC FEEDER!");
            unit = thisUnit;
        }
    }*/
  
   // DDLogVerbose( @"  scanner: %@", scanner );

//    DDLogVerbose(@"unit: %@", unit);
   
    DDLogVerbose(@"current functional unit: %ld", scanner.selectedFunctionalUnit.type);
    DDLogVerbose(@"doc feeder is %d", ICScannerFunctionalUnitTypeDocumentFeeder);
    DDLogVerbose(@"flatbed is %d", ICScannerFunctionalUnitTypeFlatbed);
  
//    [scanner requestSelectFunctionalUnit:(long)[[scanner availableFunctionalUnitTypes] objectAtIndex:1]];
    [scanner requestSelectFunctionalUnit:(ICScannerFunctionalUnitType) ([configuration isFlatbed] ? ICScannerFunctionalUnitTypeFlatbed : ICScannerFunctionalUnitTypeDocumentFeeder) ];
//    if (scanner.selectedFunctionalUnit.type != unit.type) {
  //      [scanner requestSelectFunctionalUnit:unit.type];
    //}
    // klepklep uncomment to go back to doc feeder
    //   [scanner requestSelectFunctionalUnit:ICScannerFunctionalUnitTypeDocumentFeeder];
}


//-------------------------------------------------------------------------------------------------------------- selectedScanner

- (ICScannerDevice*)selectedScanner
{
    for (ICScannerDevice *scanner in mScanners) {
        if ([[scanner name] isEqualToString:[configuration scanner]] || [configuration scanner] == nil) {
            return scanner;
        }
    }

    DDLogInfo(@"Unable to find scanner named \"%@\"", [configuration scanner]);
    [self exit];
    return nil;
}

//------------------------------------------------------------------------------------------------------------ startOverviewScan

- (IBAction)startOverviewScan:(id)sender
{
    ICScannerDevice*          scanner = [self selectedScanner];
    ICScannerFunctionalUnit*  fu      = scanner.selectedFunctionalUnit;
    
    if ( fu.canPerformOverviewScan && ( fu.scanInProgress == NO ) && ( fu.overviewScanInProgress == NO ) )
    {
        fu.overviewResolution = [fu.supportedResolutions indexGreaterThanOrEqualToIndex:72];
        [scanner requestOverviewScan];
    }
    else
        [scanner cancelScan];
}

//------------------------------------------------------------------------------------------------------------ startOverviewScan

- (IBAction)startScan:(id)sender
{
    ICScannerDevice*          scanner = [self selectedScanner];
    ICScannerFunctionalUnit*  fu      = scanner.selectedFunctionalUnit;
   
  //  [self selectFunctionalUnit:nil];
    
    DDLogVerbose(@"starting scan");
    
    if ( ( fu.scanInProgress == NO ) && ( fu.overviewScanInProgress == NO ) )
    {
        if ( fu.type == ICScannerFunctionalUnitTypeDocumentFeeder )
        {
            ICScannerFunctionalUnitDocumentFeeder* dfu = (ICScannerFunctionalUnitDocumentFeeder*)fu;
            
            dfu.documentType  = ICScannerDocumentTypeUSLetter;
            dfu.duplexScanningEnabled = [configuration isDuplex];
        }
        else
        {
            NSSize s;
            
            fu.measurementUnit  = ICScannerMeasurementUnitInches;
            if ( fu.type == ICScannerFunctionalUnitTypeFlatbed )
                s = ((ICScannerFunctionalUnitFlatbed*)fu).physicalSize;
            else if ( fu.type == ICScannerFunctionalUnitTypePositiveTransparency )
                s = ((ICScannerFunctionalUnitPositiveTransparency*)fu).physicalSize;
            else
                s = ((ICScannerFunctionalUnitNegativeTransparency*)fu).physicalSize;
            fu.scanArea         = NSMakeRect( 0.0, 0.0, s.width, s.height );
        }
        
     
        fu.resolution                   = [fu.supportedResolutions indexGreaterThanOrEqualToIndex:150];
        fu.bitDepth                     = ICScannerBitDepth8Bits;
        fu.pixelDataType                = ICScannerPixelDataTypeRGB;
        
        scanner.transferMode            = ICScannerTransferModeFileBased;
        scanner.downloadsDirectory      = [NSURL fileURLWithPath:NSTemporaryDirectory()];
//        scanner.downloadsDirectory      = [NSURL fileURLWithPath:[@"~/Pictures" stringByExpandingTildeInPath]];
        scanner.documentName            = @"Scan";
//        scanner.documentUTI             = (id)kUTTypePDF;
        scanner.documentUTI             = (id)kUTTypeJPEG;


 //       DDLogVerbose(@"current scanner: %@", scanner);
        DDLogVerbose(@"final functional unit before scanning: %d", (int)scanner.selectedFunctionalUnit.type);
     //  exit(0); // TODO. this quits before scanning. remove to actually scan.

        [scanner requestScan];
    }
    else
        [scanner cancelScan];
}

//------------------------------------------------------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------------------------------------------------------

