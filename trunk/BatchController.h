//
//  ProgressController.h
//  CocoaSlideShow
//
//  Created by Pierrick Terrettaz on 15.02.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BatchController : NSObject {
    IBOutlet NSPanel *panel;
    IBOutlet NSTextField *title;
    IBOutlet NSTextField *status;
    IBOutlet NSProgressIndicator *progress;
}

- (void)executeBatchName:(NSString *)name onList:(NSArray *)list withSelector:(NSString *)selectorAsString modalForWindow:(NSWindow *)window withObject:(id)object;

@end
