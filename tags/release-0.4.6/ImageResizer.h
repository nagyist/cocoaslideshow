//
//  ImageResizer.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 07.09.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageResizer : NSValueTransformer {
	NSView *view;
}

- (void)setView:(NSView *)aView;

@end
