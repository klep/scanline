/*
     File: AppController.m
 */

#import "AppController.h"

/*
 *****
 *
 *****
 KLEP TODO:
   x current problem -- can't select functional unit
        x timing issue?
        x what if you select it again after it selects the wrong one?
   x multipage scan doesn't work -- maybe need to wait for scancomplete message
   * increase default scan resolution
   x make it possible to configure scanner through command line options (flatbed, etc.)
   x make it possible to do double sided scanning or whatever it's called
   * clean it up!
   * -name option should also be used for aliases
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
    NSLog(@"Received %d arguments", argc);
    
    fDuplex = NO;
    fBatch = NO;
    fFlatbed = NO;
    mDir = @"/Users/klep/Documents/Archive";
    mName = nil;
    
    mTags = [NSMutableArray arrayWithCapacity:(argc-1)];

    for (int i = 1; i < argc; i++) {
        NSString* theArg = [NSString stringWithFormat:@"%s", argv[i]];
        if ([theArg isEqualToString:@"-duplex"]) {
            NSLog(@"Duplex");
            fDuplex = YES;
        } else if ([theArg isEqualToString:@"-batch"]) {
            NSLog(@"Batch");
            fBatch = YES;
        } else if ([theArg isEqualToString:@"-flatbed"]) {
            NSLog(@"Flatbed");
            fFlatbed = YES;
        } else if ([theArg isEqualToString:@"-dir"]) {
            NSLog(@"Dir");
            if (i < argc && argv[i+1] != nil) {
                i++;
                mDir = [NSString stringWithFormat:@"%s", argv[i]];
                NSLog(@"Dir: %@", mDir);
            }
        } else if ([theArg isEqualToString:@"-name"]) {
            NSLog(@"Name");
            if (i < argc && argv[i+1] != nil) {
                i++;
                mName = [NSString stringWithFormat:@"%s", argv[i]];
                NSLog(@"Name: %@", mName);
            }
        } else {
            NSLog(@"Tag: %s", argv[i]);
            [mTags addObject:theArg];
        }
    }
    
    mScannedDestinationURLs = [NSMutableArray arrayWithCapacity:1];
}

//------------------------------------------------------------------------------------------------------------------- initialize

+ (void)initialize
{
  //  CGImageRefToNSImageTransformer *imageTransformer = [[CGImageRefToNSImageTransformer alloc] init];
  //  [NSValueTransformer setValueTransformer:imageTransformer forName:@"NSImageFromCGImage"];
}

//----------------------------------------------------------------------------------------------- applicationDidFinishLaunching:

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    mScanners = [[NSMutableArray alloc] initWithCapacity:0];
    [mScannersController setSelectsInsertedObjects:NO];

    mDeviceBrowser = [[ICDeviceBrowser alloc] init];
    mDeviceBrowser.delegate = self;
    mDeviceBrowser.browsedDeviceTypeMask = ICDeviceLocationTypeMaskLocal|ICDeviceLocationTypeMaskRemote|ICDeviceTypeMaskScanner;
    NSLog(@"starting device browser...");
    [mDeviceBrowser start];
    
//    [mFunctionalUnitMenu removeAllItems];
//    [mFunctionalUnitMenu setEnabled:NO];
}

//---------------------------------------------------------------------------------------------------- applicationWillTerminate:

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
  //  NSLog( @"deviceBrowser:didAddDevice:moreComing: \n%@\n", addedDevice );
    
    if ( (addedDevice.type & ICDeviceTypeMaskScanner) == ICDeviceTypeScanner )
    {
        [self willChangeValueForKey:@"scanners"];
        [mScanners addObject:addedDevice];
        [self didChangeValueForKey:@"scanners"];
        addedDevice.delegate = self;
    }
    
    if (!moreComing) {
        NSLog(@"All devices have been added.");
        [self openCloseSession:nil];
 //       [self selectFunctionalUnit:0];
    }
}

//------------------------------------------------------------------------------------- deviceBrowser:didRemoveDevice:moreGoing:

- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)removedDevice moreGoing:(BOOL)moreGoing;
{
    NSLog( @"deviceBrowser:didRemoveDevice: \n%@\n", removedDevice );
    [mScannersController removeObject:removedDevice];
}

//------------------------------------------------------------------------------------------- deviceBrowser:deviceDidChangeName:

- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeName:(ICDevice*)device;
{
    NSLog( @"deviceBrowser:\n%@\ndeviceDidChangeName: \n%@\n", browser, device );
}

//----------------------------------------------------------------------------------- deviceBrowser:deviceDidChangeSharingState:

- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeSharingState:(ICDevice*)device;
{
    NSLog( @"deviceBrowser:\n%@\ndeviceDidChangeSharingState: \n%@\n", browser, device );
}

//--------------------------------------------------------------------------------- deviceBrowser:didReceiveButtonPressOnDevice:

- (void)deviceBrowser:(ICDeviceBrowser*)browser requestsSelectDevice:(ICDevice*)device
{
    NSLog( @"deviceBrowser:\n%@\nrequestsSelectDevice: \n%@\n", browser, device );
}

#pragma mark -
#pragma mark ICDevice & ICScannerDevice delegate methods
//------------------------------------------------------------------------------------------------------------- didRemoveDevice:

- (void)didRemoveDevice:(ICDevice*)removedDevice
{
    NSLog( @"didRemoveDevice: \n%@\n", removedDevice );
    [mScannersController removeObject:removedDevice];
}

//---------------------------------------------------------------------------------------------- device:didOpenSessionWithError:

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error
{
    NSLog( @"device:didOpenSessionWithError: \n" );
//    NSLog( @"  device: %@\n", device );
    NSLog( @"  error : %@\n", error );
 //   [self startScan:self];
    
    [self selectFunctionalUnit:0];
}

//-------------------------------------------------------------------------------------------------------- deviceDidBecomeReady:

- (void)deviceDidBecomeReady:(ICScannerDevice*)scanner
{
    NSArray*                    availabeTypes   = [scanner availableFunctionalUnitTypes];
    ICScannerFunctionalUnit*    functionalUnit  = scanner.selectedFunctionalUnit;
        
 //   NSLog( @"scannerDeviceDidBecomeReady: \n%@\n", scanner );
        
//    [mFunctionalUnitMenu removeAllItems];
//    [mFunctionalUnitMenu setEnabled:NO];
  /*  
    if ( [availabeTypes count] )
    {
        NSMenu*     menu = [[NSMenu alloc] init];
        NSMenuItem* menuItem;
        
        [mFunctionalUnitMenu setEnabled:YES];
        for ( NSNumber* n in availabeTypes )
        {
            switch ( [n intValue] )
            {
                case ICScannerFunctionalUnitTypeFlatbed:
                    menuItem = [[NSMenuItem alloc] initWithTitle:@"Flatbed" action:@selector(selectFunctionalUnit:) keyEquivalent:@""];
                    [menuItem setTarget:self];
                    [menuItem setTag:ICScannerFunctionalUnitTypeFlatbed];
                    [menu addItem:menuItem];
                    break;
                case ICScannerFunctionalUnitTypePositiveTransparency:
                    menuItem = [[NSMenuItem alloc] initWithTitle:@"Postive Transparency" action:@selector(selectFunctionalUnit:) keyEquivalent:@""];
                    [menuItem setTarget:self];
                    [menuItem setTag:ICScannerFunctionalUnitTypePositiveTransparency];
                    [menu addItem:menuItem];
                    break;
                case ICScannerFunctionalUnitTypeNegativeTransparency:
                    menuItem = [[NSMenuItem alloc] initWithTitle:@"Negative Transparency" action:@selector(selectFunctionalUnit:) keyEquivalent:@""];
                    [menuItem setTarget:self];
                    [menuItem setTag:ICScannerFunctionalUnitTypeNegativeTransparency];
                    [menu addItem:menuItem];
                    break;
                case ICScannerFunctionalUnitTypeDocumentFeeder:
                    menuItem = [[NSMenuItem alloc] initWithTitle:@"Document Feeder" action:@selector(selectFunctionalUnit:) keyEquivalent:@""];
                    [menuItem setTarget:self];
                    [menuItem setTag:ICScannerFunctionalUnitTypeDocumentFeeder];
                    [menu addItem:menuItem];
                    break;
            }
        }
        
        [mFunctionalUnitMenu setMenu:menu];
    }
    */
 //   NSLog( @"observeValueForKeyPath - functionalUnit: %@\n", functionalUnit );
    
//    [self selectFunctionalUnit:nil];
    // TODO: I think we need to manually select a functional unit
//    if ( functionalUnit )

        // [mFunctionalUnitMenu selectItemWithTag:functionalUnit.type];
}

//--------------------------------------------------------------------------------------------- device:didCloseSessionWithError:

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error
{
    NSLog( @"device:didCloseSessionWithError: \n" );
 //   NSLog( @"  device: %@\n", device );
    NSLog( @"  error : %@\n", error );
}

//--------------------------------------------------------------------------------------------------------- deviceDidChangeName:

- (void)deviceDidChangeName:(ICDevice*)device;
{
    NSLog( @"deviceDidChangeName: \n%@\n", device );
}

//------------------------------------------------------------------------------------------------- deviceDidChangeSharingState:

- (void)deviceDidChangeSharingState:(ICDevice*)device
{
    NSLog( @"deviceDidChangeSharingState: \n%@\n", device );
}

//------------------------------------------------------------------------------------------ device:didReceiveStatusInformation:

- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status
{
    NSLog( @"device: \n%@\ndidReceiveStatusInformation: \n%@\n", device, status );
    
    if ( [[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmingUp] )
    {
        [mProgressIndicator setDisplayedWhenStopped:YES];
        [mProgressIndicator setIndeterminate:YES];
        [mProgressIndicator startAnimation:NULL];
        [mStatusText setStringValue:[status objectForKey:ICLocalizedStatusNotificationKey]];
    }
    else if ( [[status objectForKey:ICStatusNotificationKey] isEqualToString:ICScannerStatusWarmUpDone] )
    {
        [mStatusText setStringValue:@""];
        [mProgressIndicator stopAnimation:NULL];
        [mProgressIndicator setIndeterminate:NO];
        [mProgressIndicator setDisplayedWhenStopped:NO];
    }
}

//---------------------------------------------------------------------------------------------------- device:didEncounterError:

- (void)device:(ICDevice*)device didEncounterError:(NSError*)error
{
    NSLog( @"device: \n%@\ndidEncounterError: \n%@\n", device, error );
}

//----------------------------------------------------------------------------------------- scannerDevice:didReceiveButtonPress:

- (void)device:(ICDevice*)device didReceiveButtonPress:(NSString*)button
{
    NSLog( @"device: \n%@\ndidReceiveButtonPress: \n%@\n", device, button );
}

//--------------------------------------------------------------------------------------------- scannerDeviceDidBecomeAvailable:

- (void)scannerDeviceDidBecomeAvailable:(ICScannerDevice*)scanner;
{
    NSLog( @"scannerDeviceDidBecomeAvailable: \n%@\n", scanner );
    [scanner requestOpenSession];
}

//--------------------------------------------------------------------------------- scannerDevice:didSelectFunctionalUnit:error:

- (void)scannerDevice:(ICScannerDevice*)scanner didSelectFunctionalUnit:(ICScannerFunctionalUnit*)functionalUnit error:(NSError*)error
{
 //   NSLog( @"scannerDevice:didSelectFunctionalUnit:error:contextInfo:\n" );
  //  NSLog( @"  scanner:        %@:\n", scanner );
 //   NSLog( @"  functionalUnit: %@:\n", functionalUnit );
 //   NSLog( @"  functionalUnit: %@:\n", scanner.selectedFunctionalUnit );
    NSLog( @"  selected functionalUnitType: %ld\n", scanner.selectedFunctionalUnit.type);

    BOOL correctFunctionalUnit = (fFlatbed && scanner.selectedFunctionalUnit.type == ICScannerFunctionalUnitTypeFlatbed) || (!fFlatbed && scanner.selectedFunctionalUnit.type == ICScannerFunctionalUnitTypeDocumentFeeder);
    if (correctFunctionalUnit && error == NULL) {
       [self startScan:self];
    } else {
        NSLog( @"  error:          %@\n", error );
       [self selectFunctionalUnit:self];
    }

}

//--------------------------------------------------------------------------------------------- scannerDevice:didScanToURL:data:

- (void)scannerDevice:(ICScannerDevice*)scanner didScanToURL:(NSURL*)url data:(NSData*)data
{
    NSLog( @"scannerDevice:didScanToURL:data: \n" );
//    NSLog( @"  scanner: %@", scanner );
    NSLog( @"  url:     %@", url );
    NSLog( @"  data:    %p\n", data );
    
    [mScannedDestinationURLs addObject:url];
    
    
}

//------------------------------------------------------------------------------ scannerDevice:didCompleteOverviewScanWithError:

- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteOverviewScanWithError:(NSError*)error;
{
    NSLog( @"scannerDevice: \n%@\ndidCompleteOverviewScanWithError: \n%@\n", scanner, error );
    [mProgressIndicator setHidden:YES];
}

//-------------------------------------------------------------------------------------- scannerDevice:didCompleteScanWithError:

- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteScanWithError:(NSError*)error;
{
    NSLog( @"scannerDevice: \n%@\ndidCompleteScanWithError: \n%@\n", scanner, error );

    if (fBatch) {
        NSLog(@"Press RETURN to scan next page or S to stop");
        int userInput;
        userInput = getchar();
        if (userInput != 's' && userInput != 'S')
        {
            [self startScan:self];
            return;
        }
//        NSFileHandle *input = [NSFileHandle fileHandleWithStandardInput];
  //      NSData *inputData = [NSData dataWithData:[input readDataToEndOfFile]];
    //    NSString *inputString = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
    }
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorian components:(NSYearCalendarUnit | NSHourCalendarUnit  | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:[NSDate date]];
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    NSInteger second = [dateComponents second];
    NSInteger year = [dateComponents year];
    [gregorian release];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    // If there's a tag, move the file to the first tag location

    NSLog(@"creating directory");
    NSString* path = mDir;
    if ([mTags count] > 0) {
        path = [NSString stringWithFormat:@"%@/%@/%ld", mDir, [mTags objectAtIndex:0], year];
    }
    NSLog(@"path: %@", path);
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

    NSString* destinationFileRoot = (mName == nil) ? [NSString stringWithFormat:@"%@/scan_%02ld%02ld%02ld", path, hour, minute, second] :
                                                     [NSString stringWithFormat:@"%@/%@", path, mName];
    NSString* destinationFile = [NSString stringWithFormat:@"%@.pdf", destinationFileRoot];
    NSLog(@"destinationFileRoot: %@", destinationFileRoot   );
    int i = 0;
    while ([fm fileExistsAtPath:destinationFile]) {
        destinationFile = [NSString stringWithFormat:@"%@_%d.pdf", destinationFileRoot, i];
        NSLog(@"destinationFile: %@", destinationFile);
        i++;
    }
    
    /*NSURL* scannedDestinationURL;
    if ([mScannedDestinationURLs count] > 1) {
        scannedDestinationURL = [self combinedScanDestinations];
    } else {
        scannedDestinationURL = [mScannedDestinationURLs objectAtIndex:0];
    }*/
    // NOTE: Since we're now scanning JPEGs, this will turn any number of JPEGs into a single PDF.
    NSURL* scannedDestinationURL = [self combinedScanDestinations];
    if (scannedDestinationURL == NULL) {
        NSLog(@"No document was scanned.");
        exit(0);
    }
    
    NSLog(@"about to copy %@ to %@", scannedDestinationURL, [NSURL fileURLWithPath:destinationFile]);
    [fm copyItemAtURL:scannedDestinationURL toURL:[NSURL fileURLWithPath:destinationFile] error:nil];
    NSLog(@"file copied");
    
    // alias to all the other tag locations
    for (int i = 1; i < [mTags count]; i++) {
        NSLog(@"aliasing to tag: %@", [mTags objectAtIndex:i]);
        NSString* aliasDirPath = [NSString stringWithFormat:@"%@/%@/%ld", mDir, [mTags objectAtIndex:i], year];
        [fm createDirectoryAtPath:aliasDirPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString* aliasFilePath = [NSString stringWithFormat:@"%@/scan_%02ld%02ld%02ld.pdf", aliasDirPath, hour, minute, second];
        int suffix = 0;
        while ([fm fileExistsAtPath:aliasFilePath]) {
            aliasFilePath = [NSString stringWithFormat:@"%@/scan_%02ld%02ld%02ld_%d.pdf", aliasDirPath, hour, minute, second, suffix];
            suffix++;
        }
        NSLog(@"aliasing to %@", aliasFilePath);
        [fm createSymbolicLinkAtPath:aliasFilePath withDestinationPath:destinationFile error:nil];
    }

    exit(0);
    [mProgressIndicator setHidden:YES];
}

#pragma mark -
//------------------------------------------------------------------------------------------------------------ openCloseSession:

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
    NSLog(@"writing to tempFile: %@", tempFile);
    [outputDocument writeToFile:tempFile];
    return [[NSURL alloc] initFileURLWithPath:tempFile];
}

- (void)go
{
    NSLog( @"go");
    
    [self applicationDidFinishLaunching:nil];
    
    // wait
  /*  while ([mScanners count] == 0) {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        NSLog(@"waiting...");
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
    NSLog(@"setting functional unit");
    ICScannerDevice* scanner = [mScanners objectAtIndex:0];

    /*  ICScannerFunctionalUnit* unit = [[scanner availableFunctionalUnitTypes] objectAtIndex:0];
    
    for (int i = 0; i < [[scanner availableFunctionalUnitTypes] count]; i++) {
        ICScannerFunctionalUnit* thisUnit = [[scanner availableFunctionalUnitTypes] objectAtIndex:i];
        NSLog(@"this unit: %@", thisUnit);
        if (fFlatbed && thisUnit != nil && thisUnit.type == ICScannerFunctionalUnitTypeFlatbed) {
            NSLog(@"found flatbed");
            unit = thisUnit;
        } else if (!fFlatbed && thisUnit != nil && thisUnit.type == ICScannerFunctionalUnitTypeDocumentFeeder) {
            NSLog(@"FOUND DOC FEEDER!");
            unit = thisUnit;
        }
    }*/
  
   // NSLog( @"  scanner: %@", scanner );

//    NSLog(@"unit: %@", unit);
   
    NSLog(@"current functional unit: %ld", scanner.selectedFunctionalUnit.type);
    NSLog(@"doc feeder is %d", ICScannerFunctionalUnitTypeDocumentFeeder);
    NSLog(@"flatbed is %d", ICScannerFunctionalUnitTypeFlatbed);
  
//    [scanner requestSelectFunctionalUnit:(long)[[scanner availableFunctionalUnitTypes] objectAtIndex:1]];
    [scanner requestSelectFunctionalUnit:(ICScannerFunctionalUnitType) (fFlatbed ? ICScannerFunctionalUnitTypeFlatbed : ICScannerFunctionalUnitTypeDocumentFeeder) ];
//    if (scanner.selectedFunctionalUnit.type != unit.type) {
  //      [scanner requestSelectFunctionalUnit:unit.type];
    //}
    // klepklep uncomment to go back to doc feeder
    //   [scanner requestSelectFunctionalUnit:ICScannerFunctionalUnitTypeDocumentFeeder];
}


//-------------------------------------------------------------------------------------------------------------- selectedScanner

- (ICScannerDevice*)selectedScanner
{
    return [mScanners objectAtIndex:0];
/*    ICScannerDevice*  device          = NULL;
    id                selectedObjects = [mScannersController selectedObjects];
    
    if ( [selectedObjects count] )
        device = [selectedObjects objectAtIndex:0];
        
    return device;*/
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
        [mProgressIndicator setHidden:NO];
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
    
    NSLog(@"starting scan");
    
    if ( ( fu.scanInProgress == NO ) && ( fu.overviewScanInProgress == NO ) )
    {
        if ( fu.type == ICScannerFunctionalUnitTypeDocumentFeeder )
        {
            ICScannerFunctionalUnitDocumentFeeder* dfu = (ICScannerFunctionalUnitDocumentFeeder*)fu;
            
            dfu.documentType  = ICScannerDocumentTypeUSLetter;
            dfu.duplexScanningEnabled = fDuplex;
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


 //       NSLog(@"current scanner: %@", scanner);
        NSLog(@"final functional unit before scanning: %d", (int)scanner.selectedFunctionalUnit.type);
     //  exit(0); // TODO. this quits before scanning. remove to actually scan.

        [scanner requestScan];
        [mProgressIndicator setHidden:NO];
    }
    else
        [scanner cancelScan];
}

//------------------------------------------------------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------------------------------------------------------

