//
//  ScanConfiguration.h
//  scanline
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

static NSString * const ScanlineConfigOptionDuplex = @"duplex";
static NSString * const ScanlineConfigOptionBatch = @"batch";
static NSString * const ScanlineConfigOptionList = @"list";
static NSString * const ScanlineConfigOptionFlatbed = @"flatbed";
static NSString * const ScanlineConfigOptionJPEG = @"jpeg";
static NSString * const ScanlineConfigOptionLegal = @"legal";
static NSString * const ScanlineConfigOptionLetter = @"letter";
static NSString * const ScanlineConfigOptionMono = @"mono";
static NSString * const ScanlineConfigOptionOpen = @"open";
static NSString * const ScanlineConfigOptionDir = @"dir";
static NSString * const ScanlineConfigOptionName = @"name";
static NSString * const ScanlineConfigOptionVerbose = @"verbose";
static NSString * const ScanlineConfigOptionScanner = @"scanner";
static NSString * const ScanlineConfigOptionResolution = @"resolution";

@interface ScanConfiguration : NSObject

@property (getter = isDuplex)   BOOL               duplex;
@property (getter = isBatch)    BOOL               batch;
@property (getter = isFlatbed)  BOOL               flatbed;
@property (getter = listOnly)   BOOL               list;
@property (getter = isJpeg)     BOOL               jpeg;
@property (getter = isLegal)    BOOL               legal;
@property (getter = isMono)     BOOL               mono;
@property                       BOOL               open;
@property (strong)              NSString*          dir;
@property (strong)              NSString*          name;
@property (strong)              NSMutableArray*    tags;
@property (strong)              NSString*          scanner;
@property                       int                resolution;

- (id)init;
- (id)initWithArguments:(NSArray *)inArguments;
- (void)print;

- (NSString*)configFilePath;
+ (NSDictionary*)configOptions;

@end

extern int ddLogLevel;
