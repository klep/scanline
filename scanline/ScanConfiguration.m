//
//  ScanConfiguration.m
//  scanline
//
//  Created by Scott J. Kleper on 9/26/13.
//
//

#import "ScanConfiguration.h"
#import "DDLog.h"

int ddLogLevel = LOG_LEVEL_INFO;

@implementation ScanConfiguration

+ (NSDictionary*)configOptions
{
    return @{
             ScanlineConfigOptionDuplex: @{
                     @"type": @"flag",
                     @"synonyms": @[@"dup"],
                     @"setter": @"duplex",
                     @"description": @"Duplex (two-sided) scanning mode, for scanners that support it."
                     },
             ScanlineConfigOptionBatch: @{
                     @"type": @"flag",
                     @"description": @"scanline will pause after each page, allowing you to continue to scan additional pages until you say you're done."
                     },
             ScanlineConfigOptionList: @{
                     @"description": @"List all available scanners, then exit."
                     },
             ScanlineConfigOptionFlatbed: @{
                     @"synonyms": @[@"fb"],
                     @"description": @"Scan from the scanner's flatbed (default is paper feeder)"
                     },
             ScanlineConfigOptionJPEG: @{
                     @"synonyms": @[@"jpg"],
                     @"description": @"Scan to a JPEG file (default is PDF)"
                     },
             ScanlineConfigOptionLegal: @{
                     @"description": @"Scan a legal size page"
                     },
             ScanlineConfigOptionLetter: @{
                     @"description": @"Scan a letter size page"
                     },
             ScanlineConfigOptionMono: @{
                     @"synonyms": @[@"bw"],
                     @"description": @"Scan in monochrome (black and white)"
                     },
             ScanlineConfigOptionOpen: @{
                     @"description": @"Open the scanned image when done."
                     },
             ScanlineConfigOptionDir: @{
                     @"synonyms": @[@"folder"],
                     @"type": @"string",
                     @"description": @"Specify a directory where the files should go."
                     },
             ScanlineConfigOptionName: @{
                     @"type": @"string",
                     @"description": @"Specify a name for the output file."
                     },
             ScanlineConfigOptionVerbose: @{
                     @"synonyms": @[@"v"],
                     @"description": @"Provide verbose logging."
                     },
             ScanlineConfigOptionScanner: @{
                     @"synonyms": @[@"s"],
                     @"description": @"Specify which scanner to use (use -list to list available scanners).",
                     @"type": @"string"
                     },
             ScanlineConfigOptionResolution: @{
                     @"synonyms": @[@"res", @"minResolution"],
                     @"type": @"string",
                     @"description": @"Specify minimum resolution at which to scan (in dpi)",
                     @"default": @"150"
                     }
             };
}

- (id)init
{
    if (self = [super init]) {
        _tags = [NSMutableArray arrayWithCapacity:0];
        _duplex = NO;
        _batch = NO;
        _list = NO;
        _flatbed = NO;
        _jpeg = NO;
        _legal = NO;
        _dir = [NSString stringWithFormat:@"%@/Documents/Archive", NSHomeDirectory()];
        _name = nil;
        _scanner = nil;
        _resolution = 150;
        _mono = NO;
        _open = NO;
        
        [self loadConfigurationDefaults];
        [self loadConfigurationFromFile];
    }
    return self;
}

- (id)initWithArguments:(NSArray *)inArguments
{
    if (self = [self init]) {
        [self loadConfigurationFromArguments:inArguments];
    }
    return self;
}

- (void)help
{
    NSDictionary *configOptions = [ScanConfiguration configOptions];
    
    for (NSString *key in configOptions.keyEnumerator) {
        NSLog(@"-%@:\t%@", key, configOptions[key][@"description"]);
    }
}

- (void)loadConfigurationDefaults
{
    [self setDuplex:NO];
}

- (void)print
{
    DDLogInfo(@"fList: %d", _list);
    DDLogInfo(@"fFlatbed: %d", _flatbed);
    DDLogInfo(@"fBatch: %d", _batch);
    DDLogInfo(@"fDuplex: %d", _duplex);
    DDLogInfo(@"fJpeg: %d", _jpeg);
    DDLogInfo(@"fLegal: %d", _legal);
    DDLogInfo(@"mName: %@", _name);
    DDLogInfo(@"mDir: %@", _dir);
    DDLogInfo(@"mScanner: %@", _scanner);
    DDLogInfo(@"mTags: %@", _tags);
    DDLogInfo(@"mResolution: %d", _resolution);
    DDLogInfo(@"fMono: %d", _mono);
    DDLogInfo(@"fOpen: %d", _open);
}

- (NSString*)configFilePath
{
    return [NSString stringWithFormat:@"%@/.scanline.conf", NSHomeDirectory()];
}

- (void)loadConfigurationFromFile
{
    NSString* configPath = [self configFilePath];
    DDLogVerbose(@"configPath: %@", configPath);
    
    if ([[NSFileManager defaultManager] isReadableFileAtPath:configPath]) {
        NSString* valueString = [NSString stringWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
        NSArray* values = [valueString componentsSeparatedByString:@"\n"];
        [self loadConfigurationFromArguments:values];
    }
}

- (void)loadConfigurationFromArguments:(NSArray*)inArguments
{
    DDLogVerbose(@"loading config from arguments: %@", inArguments);
    for (int i = 0; i < [inArguments count]; i++) {
        NSString* theArg = [inArguments objectAtIndex:i];

        if ([theArg isEqualToString:@"-help"]) {
            [self help]; // haha self help!
        } else if([theArg isEqualToString:@"-duplex"]) {
            [self setDuplex:YES];
        } else if ([theArg isEqualToString:@"-list"]) {
            _list = YES;
        } else if ([theArg isEqualToString:@"-batch"]) {
            [self setBatch:YES];
        } else if ([theArg isEqualToString:@"-flatbed"]) {
            [self setFlatbed:YES];
        } else if ([theArg isEqualToString:@"-jpeg"] || [theArg isEqualToString:@"-jpg"]) {
            [self setJpeg:YES];
        } else if ([theArg isEqualToString:@"-legal"]) {
            [self setLegal:YES];
        } else if ([theArg isEqualToString:@"-letter"]) {
            [self setLegal:NO];
        } else if ([theArg isEqualToString:@"-mono"] || [theArg isEqualToString:@"-bw"]) {
            [self setMono:YES];
        } else if ([theArg isEqualToString:@"-open"]) {
            [self setOpen:YES];
        } else if ([theArg isEqualToString:@"-dir"] || [theArg isEqualToString:@"-folder"]) {
            if (i < [inArguments count] && [inArguments objectAtIndex:i+1] != nil) {
                i++;
                [self setDir:[NSString stringWithString:[inArguments objectAtIndex:i]]];
            }
        } else if ([theArg isEqualToString:@"-name"]) {
            if (i < [inArguments count] && [inArguments objectAtIndex:i+1] != nil) {
                i++;
                [self setName:[NSString stringWithString:[inArguments objectAtIndex:i]]];
            }
        } else if ([theArg isEqualToString:@"-v"] || [theArg isEqualToString:@"-verbose"]) {
            ddLogLevel = LOG_LEVEL_VERBOSE;
            DDLogVerbose(@"Verbose logging enabled.");
        } else if ([theArg isEqualToString:@"-scanner"]) {
            if (i < [inArguments count] && [inArguments objectAtIndex:i+1] != nil) {
                i++;
                [self setScanner:[NSString stringWithString:[inArguments objectAtIndex:i]]];
            }
        } else if ([theArg isEqualToString:@"-resolution"] || [theArg isEqualToString:@"-minResolution"] || [theArg isEqualToString:@"-res"]) {
            if (i < [inArguments count] && [inArguments objectAtIndex:i+1] != nil) {
                i++;
                [self setResolution:[[inArguments objectAtIndex:i] intValue]];
                if (self.resolution == 0) {
                    DDLogError(@"WARNING: Scanning at resolution of 0. This will scan at the scanner's lowest possible resolution.");
                }
            }
        } else if (![theArg isEqualToString:@""]) {
            DDLogVerbose(@"Adding tag: %@", theArg);
            [_tags addObject:theArg];
            [self print];
        }
    }
}

@end





















