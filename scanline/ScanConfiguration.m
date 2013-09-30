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

- (id)init
{
    if (self = [super init]) {
        _tags = [NSMutableArray array];
        _duplex = NO;
        _batch = NO;
        _flatbed = NO;
        _dir = [NSString stringWithFormat:@"%@/Documents/Archive", NSHomeDirectory()];
        _name = nil;
        
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

- (void)loadConfigurationDefaults
{
    [self setDuplex:NO];
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
    for (int i = 0; i < [inArguments count]; i++) {
        NSString* theArg = [inArguments objectAtIndex:i];

        if ([theArg isEqualToString:@"-duplex"]) {
            [self setDuplex:YES];
        } else if ([theArg isEqualToString:@"-batch"]) {
            [self setBatch:YES];
        } else if ([theArg isEqualToString:@"-flatbed"]) {
            [self setFlatbed:YES];
        } else if ([theArg isEqualToString:@"-dir"]) {
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
        } else {
            [_tags addObject:theArg];
        }
    }
}

@end
