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
@end
