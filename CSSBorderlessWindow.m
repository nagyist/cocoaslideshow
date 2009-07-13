//
//  CSSBorderlessWindow.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 13.07.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "CSSBorderlessWindow.h"


@implementation CSSBorderlessWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	
	NSWindow *result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	
	[result setBackgroundColor:[NSColor blackColor]];
	
	[result setLevel:NSStatusWindowLevel];
	
	return result;
}

@end
