//
//  KeywordsField.m
//  CocoaSlideShow
//
//  Created by Pierrick Terrettaz on 20.02.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "KeywordsField.h"
#import "ImagesController.h"

@implementation KeywordsField

- (void)keyUp:(NSEvent *)theEvent {
    if ([theEvent keyCode] == 125) { // ArrowUp
        [imageController selectNextImage];
    } else if ([theEvent keyCode] == 126) { // ArrowDown
        [imageController selectPreviousImage];
    } else {
        [super keyUp:theEvent];
    }
}

@end
