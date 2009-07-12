//
//  ImageResizer.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 07.09.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ImageResizer.h"


@implementation ImageResizer

- (void)setView:(NSView *)aView {
	[view autorelease];
	view = [aView retain];
}

- (void)dealloc {
	[view release];
	[super dealloc];
}

+ (Class)transformedValueClass {
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (id)transformedValue:(NSImage *)value {
	/*
	if(![[[NSApp delegate] valueForKey:@"isFullScreen"] boolValue]) {
		NSLog(@"transformedValue exit");
		return nil;
	}
	*/
	NSSize viewSize = ((NSRect)[view bounds]).size;
	NSSize imageSize = [value size];

	float rx = viewSize.width / imageSize.width;
	float ry = viewSize.height / imageSize.height;
	float r = rx > ry ? rx : ry;
	float w = imageSize.width * r;
	float h = imageSize.height * r;

	[value setSize:NSMakeSize(w,h)];
	return value;
}

@end
