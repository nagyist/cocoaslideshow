//
//  ProgressController.m
//  CocoaSlideShow
//
//  Created by Pierrick Terrettaz on 15.02.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BatchController.h"
#import "CSSImageInfo.h"


@implementation BatchController

- (void)executeBatchName:(NSString *)name onList:(NSArray *)list withSelector:(NSString *)selectorAsString modalForWindow:(NSWindow *)window withObject:(id)object {
    [title setStringValue:name];
    [progress setMinValue:0];
    [progress setMaxValue:[list count]];
    [progress setDoubleValue:0];
    NSArray *args = [NSArray arrayWithObjects:list, selectorAsString, nil];
    if (!object) object = [NSArray array];

    NSDictionary *context = 
    [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:object, args, nil] 
                                forKeys:[NSArray arrayWithObjects:@"object", @"args", nil]];
    
    [NSApp beginSheet:panel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];
    [NSThread detachNewThreadSelector:@selector(executeBatchWithListOnSeparateThread:) 
                             toTarget:self 
                           withObject:context];
}

- (void)executeBatchWithListOnSeparateThread:(NSDictionary *)context {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id object = [context objectForKey:@"object"];
    NSArray *args = [context objectForKey:@"args"];
    
    NSArray *list = [args objectAtIndex:0];
    SEL selector = NSSelectorFromString([args objectAtIndex:1]);
    
    for (CSSImageInfo *info in list) {
        [self performSelectorOnMainThread:@selector(willStartCSSImageInfo:) withObject:info waitUntilDone:YES];
        [info performSelector:selector withObject:object];
        [self performSelectorOnMainThread:@selector(didStartCSSImageInfo:) withObject:info waitUntilDone:YES];
    }
    
    [self performSelectorOnMainThread:@selector(didFinish) withObject:nil waitUntilDone:NO];
    [pool release];
}

- (void)willStartCSSImageInfo:(CSSImageInfo *)info {
    [status setStringValue:[info fileName]];
}

- (void)didStartCSSImageInfo:(CSSImageInfo *)info {
    [progress incrementBy:1.0];
    [status setStringValue:@""];
}

- (void)didFinish {
    [panel orderOut:nil];
    [NSApp endSheet:panel];
}

@end
