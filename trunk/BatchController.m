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

- (void)executeBatchName:(NSString *)name 
                  onList:(NSArray *)list 
            withSelector:(NSString *)selectorAsString 
          modalForWindow:(NSWindow *)window 
              withObject:(id)object
            withDelegate:(id)delegate
             withContext:(NSDictionary *)aContext{
    
    [title setStringValue:name];
    [progress setMinValue:0];
    [progress setMaxValue:[list count]];
    [progress setDoubleValue:0];
    NSArray *args = [NSArray arrayWithObjects:list, selectorAsString, nil];
    if (!object) object = [NSArray array];

    NSDictionary *dict2 = 
    [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:object, args, name, nil] 
                                forKeys:[NSArray arrayWithObjects:@"object", @"args", @"name", nil]];
    
    NSMutableDictionary *context = [NSMutableDictionary dictionaryWithDictionary:dict2];
    
    if (delegate) {
        [context setObject:delegate forKey:@"delegate"];
    }
    if (aContext) {
        [context addEntriesFromDictionary:aContext];
    }
    
    [NSApp beginSheet:panel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];
    [NSThread detachNewThreadSelector:@selector(executeBatchWithListOnSeparateThread:) 
                             toTarget:self 
                           withObject:context];
}

- (void)executeBatchName:(NSString *)name 
                  onList:(NSArray *)list 
            withSelector:(NSString *)selectorAsString 
          modalForWindow:(NSWindow *)window 
              withObject:(id)object{
    
    [self executeBatchName:name 
                    onList:list 
              withSelector:selectorAsString 
            modalForWindow:window 
                withObject:object 
              withDelegate:nil 
               withContext:nil];

}

- (void)executeBatchWithListOnSeparateThread:(NSDictionary *)context {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id object = [context objectForKey:@"object"];
    NSArray *args = [context objectForKey:@"args"];
    NSArray *name = [context objectForKey:@"name"];
    
    NSLog(@"Preparing batch: %@", name);
    
    NSArray *list = [args objectAtIndex:0];
    SEL selector = NSSelectorFromString([args objectAtIndex:1]);
    
    for (CSSImageInfo *info in list) {
        [self performSelectorOnMainThread:@selector(willProcessCSSImageInfo:) withObject:info waitUntilDone:YES];
        [info performSelector:selector withObject:object];
        [self performSelectorOnMainThread:@selector(didProcessCSSImageInfo:) withObject:info waitUntilDone:YES];
    }
    
    [self performSelectorOnMainThread:@selector(didFinish:) withObject:context waitUntilDone:NO];
    [pool release];
    
    NSLog(@"Batch: %@ Ended", name);
}

- (void)willProcessCSSImageInfo:(CSSImageInfo *)info {
    [status setStringValue:[info fileName]];
}

- (void)didProcessCSSImageInfo:(CSSImageInfo *)info {
    [progress incrementBy:1.0];
}

- (void)didFinish:(NSDictionary *)context {
    [status setStringValue:@""];
    [panel orderOut:nil];
    [NSApp endSheet:panel];
    
    id delegate = [context objectForKey:@"delegate"];
    if (delegate) {
        [delegate performSelector:@selector(didFinishBatch:) withObject:context];
    }
}

@end
