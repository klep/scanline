/*
     File: AppController.h
 */

#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>
#import <PDFKit/PDFKit.h>

#import "ScanConfiguration.h"

//------------------------------------------------------------------------------------------------------------------------------

@interface AppController : NSObject <ICDeviceBrowserDelegate, ICScannerDeviceDelegate>
{
    ScanConfiguration*              configuration;
    
    ICDeviceBrowser*                mDeviceBrowser;
    NSMutableArray*                 mScanners;
    NSMutableArray*                 mScannedDestinationURLs;
    
    NSTimer*                        mDeviceTimer;
}

@property(strong)                   NSMutableArray*     scanners;
@property (getter = isSuccessful)   BOOL                successful;

- (void)setArguments:(const char* [])argv withCount:(int)argc;
- (void)go;

// ICDeviceBrowser delegate methods
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing;
- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)removedDevice moreGoing:(BOOL)moreGoing;
- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeName:(ICDevice*)device;
- (void)deviceBrowser:(ICDeviceBrowser*)browser deviceDidChangeSharingState:(ICDevice*)device;
- (void)deviceBrowser:(ICDeviceBrowser*)browser requestsSelectDevice:(ICDevice*)device;

// ICDevice and ICScannerDevice delegate methods
- (void)didRemoveDevice:(ICDevice*)removedDevice;
- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error;
- (void)deviceDidBecomeReady:(ICScannerDevice*)device;
- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error;
- (void)deviceDidChangeName:(ICDevice*)device;
- (void)deviceDidChangeSharingState:(ICDevice*)device;
- (void)device:(ICDevice*)device didReceiveStatusInformation:(NSDictionary*)status;
- (void)device:(ICDevice*)device didEncounterError:(NSError*)error;
- (void)device:(ICDevice*)device didReceiveButtonPress:(NSString*)button;

- (void)scannerDeviceDidBecomeAvailable:(ICScannerDevice*)scanner;
- (void)scannerDevice:(ICScannerDevice*)scanner didSelectFunctionalUnit:(ICScannerFunctionalUnit*)functionalUnit error:(NSError*)error;
- (void)scannerDevice:(ICScannerDevice*)scanner didScanToURL:(NSURL*)url data:(NSData*)data;
- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteOverviewScanWithError:(NSError*)error;
- (void)scannerDevice:(ICScannerDevice*)scanner didCompleteScanWithError:(NSError*)error;

- (ICScannerDevice*)selectedScanner;
- (IBAction)openCloseSession:(id)sender;
- (IBAction)selectFunctionalUnit:(id)sender;
- (IBAction)startScan:(id)sender;
@end

//------------------------------------------------------------------------------------------------------------------------------
