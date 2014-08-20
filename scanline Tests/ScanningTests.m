//
//  ScanningTests.m
//  scanline
//
//  Created by Scott J. Kleper on 10/8/13.
//
//

#import <XCTest/XCTest.h>

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "DDFileLogger.h"

#import "ScanConfiguration.h"
#import "AppController.h"


@interface ScanningTests : XCTestCase

@end

@implementation ScanningTests

ScanConfiguration *config;
AppController *app;
DDFileLogger *fileLogger;

- (void)setUp
{
    [super setUp];

    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    fileLogger = [[DDFileLogger alloc] init];
    fileLogger.logFileManager.maximumNumberOfLogFiles = 0;
    
    [DDLog addLogger:fileLogger];
    ddLogLevel = LOG_LEVEL_VERBOSE;

    app = [[AppController alloc] init];
}

- (void)tearDown
{
    [fileLogger rollLogFile];
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testVirtualScannerExists
{
    const char* args[] = {"scanline", "-scanner", "Virtual Scanner EX/AF"};
    [app setArguments:args withCount:3];
    
    [app go];
    CFRunLoopRun();
    
    XCTAssertTrue([[[app selectedScanner] name] isEqualToString:@"Virtual Scanner EX/AF"]);
    XCTAssertTrue([app isSuccessful]);
}

- (void)testNoSuchScanner
{
    const char* args[] = {"scanline", "-scanner", "blah blah blah"};
    [app setArguments:args withCount:3];
    
    [app go];
    CFRunLoopRun();
    
    XCTAssertFalse([app isSuccessful]);
}

- (void)testList
{
    const char* args[] = {"scanline", "-list"};
    [app setArguments:args withCount:2];
    
    [app go];
    CFRunLoopRun();
    [DDLog flushLog];
    
    // search the log file for the list of scanners
    NSArray *logPaths = [[fileLogger logFileManager] sortedLogFilePaths];
    NSArray *taskArgs = [NSArray arrayWithObjects:@"Available scanners:", [logPaths objectAtIndex:0], nil];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/grep" arguments:taskArgs];
    [task waitUntilExit];
    XCTAssertTrue([task terminationStatus] == 0);

    taskArgs = [NSArray arrayWithObjects:@"* Virtual Scanner EX/AF", [logPaths objectAtIndex:0], nil];
    task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/grep" arguments:taskArgs];
    [task waitUntilExit];
    XCTAssertTrue([task terminationStatus] == 0);

    XCTAssertFalse([app isSuccessful]);
}

- (void)testBasicScanToPDF
{
    NSString* outputName = [NSString stringWithFormat:@"testBasicScanToPDF_%d", arc4random_uniform(1000000)];
    const char* args[] = {"scanline", "-dir", [NSTemporaryDirectory() UTF8String], "-name", [outputName UTF8String]};
    [app setArguments:args withCount:5];
    
    [app go];
    CFRunLoopRun();
    [DDLog flushLog];

    NSString* destinationDir = [NSString stringWithFormat:@"%@/%@.pdf", NSTemporaryDirectory(), outputName];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:destinationDir]);
    
    // clean up
    [[NSFileManager defaultManager] removeItemAtPath:destinationDir error:Nil];
}

- (void)testBasicScanToJPG
{
    NSString* outputName = [NSString stringWithFormat:@"testBasicScanToJPG_%d", arc4random_uniform(1000000)];
    const char* args[] = {"scanline", "-jpg", "-dir", [NSTemporaryDirectory() UTF8String], "-name", [outputName UTF8String]};
    [app setArguments:args withCount:6];
    
    [app go];
    CFRunLoopRun();
    [DDLog flushLog];
    
    NSString* destinationDir = [NSString stringWithFormat:@"%@/%@.jpg", NSTemporaryDirectory(), outputName];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:destinationDir]);
    
    // clean up
    [[NSFileManager defaultManager] removeItemAtPath:destinationDir error:Nil];
}

- (void)testLegalSizeScan
{
    NSString* outputName = [NSString stringWithFormat:@"testLegalSizeScan_%d", arc4random_uniform(1000000)];
    const char* args[] = {"scanline", "-legal", "-dir", [NSTemporaryDirectory() UTF8String], "-name", [outputName UTF8String]};
    [app setArguments:args withCount:6];
    
    [app go];
    CFRunLoopRun();
    [DDLog flushLog];
    
    NSString* destinationDir = [NSString stringWithFormat:@"%@/%@.pdf", NSTemporaryDirectory(), outputName];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:destinationDir]);
    
    NSSize documentSize;
    PDFDocument *myDocument = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:destinationDir]];
    PDFPage *firstPage = [myDocument pageAtIndex:0];
    NSRect bounds = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];
    NSSize pixelSize = bounds.size;
    documentSize.width = pixelSize.width / 72; documentSize.height = pixelSize.height / 72;
    XCTAssertTrue(documentSize.height == 14);
    
    // clean up
    [[NSFileManager defaultManager] removeItemAtPath:destinationDir error:Nil];
}

- (void)testVariousResolutionScans
{
    NSString* outputName = [NSString stringWithFormat:@"testVariousResolutionSizes_%d", arc4random_uniform(1000000)];
    const char* args[] = {"scanline", "-dir", [NSTemporaryDirectory() UTF8String], "-name", [outputName UTF8String], "-resolution", "0"};
    [app setArguments:args withCount:7];
    
    [app go];
    CFRunLoopRun();
    [DDLog flushLog];
    
    NSString* destinationFile = [NSString stringWithFormat:@"%@/%@.pdf", NSTemporaryDirectory(), outputName];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:destinationFile]);
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:destinationFile error:Nil];
    unsigned long long fileOneSize = attributes.fileSize;
    
    const char* args2[] = {"scanline", "-dir", [NSTemporaryDirectory() UTF8String], "-name", [[NSString stringWithFormat:@"%@_2", outputName] UTF8String], "-resolution", "300"};
    [app setArguments:args2 withCount:7];

    [app go];
    CFRunLoopRun();
    [DDLog flushLog];
    
    destinationFile = [NSString stringWithFormat:@"%@/%@_2.pdf", NSTemporaryDirectory(), outputName];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:destinationFile]);
    attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:destinationFile error:Nil];
    unsigned long long fileTwoSize = attributes.fileSize;

    XCTAssertTrue(fileTwoSize > fileOneSize);
}
- (void)testLetterSizeScanDefault
{
    NSString* outputName = [NSString stringWithFormat:@"testLetterSizeScanDefault_%d", arc4random_uniform(1000000)];
    const char* args[] = {"scanline", "-dir", [NSTemporaryDirectory() UTF8String], "-name", [outputName UTF8String]};
    [app setArguments:args withCount:5];
    
    [app go];
    CFRunLoopRun();
    [DDLog flushLog];
    
    NSString* destinationDir = [NSString stringWithFormat:@"%@/%@.pdf", NSTemporaryDirectory(), outputName];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:destinationDir]);
    
    NSSize documentSize;
    PDFDocument *myDocument = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:destinationDir]];
    PDFPage *firstPage = [myDocument pageAtIndex:0];
    NSRect bounds = [firstPage boundsForBox:kPDFDisplayBoxMediaBox];
    NSSize pixelSize = bounds.size;
    documentSize.width = pixelSize.width / 72; documentSize.height = pixelSize.height / 72;
    XCTAssertTrue(documentSize.height == 11);
    
    // clean up
    [[NSFileManager defaultManager] removeItemAtPath:destinationDir error:Nil];
}


@end
