//
//  main.m
//  scanline
//
//  Created by Scott J. Kleper on 9/8/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppController.h"

int main (int argc, const char * argv[])
{

    @autoreleasepool {

        AppController* appController = [[AppController alloc] init];
        [appController setArguments:argv withCount:argc];
        [appController go];
        
        CFRunLoopRun();
    }
    return 0;
}

