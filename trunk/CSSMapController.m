//
//  MapController.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 14.11.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import "CSSMapController.h"
#import "CSSImageContainer.h"

@implementation CSSMapController


- (BOOL)mapNeedsResizing {
	return mapNeedsResizing;
}

- (void)setMapNeedsResizing:(BOOL)flag {
	mapNeedsResizing = YES;
}

- (IBOutlet)displayGoogleMapForSelection:(id)sender {
	
	NSMutableString *markers = [[NSMutableString alloc] init];
	
	int count = 1;
	NSEnumerator *e = [[imagesController selectedObjects] objectEnumerator];
	CSSImageContainer *cssImageContainer = nil;
	CSSBitmapImageRep *b = nil;
	NSString *s;
	while((cssImageContainer = [e nextObject])) {
		//NSLog(@" marker %d", count);
		b = [cssImageContainer bitmap];
		//NSLog(@"b: %d", b != nil);
		s = [b gmapMarkerWithIndex:count];
		if(s) {
			[markers appendString:s];
			count++;
		} else {
			NSLog(@"no marker");
		}
	}
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"gmap" ofType:@"html"];
	
	NSError *error = nil;
	NSStringEncoding encoding = NSUTF8StringEncoding;
	
	NSMutableString *htmlString = [NSMutableString stringWithContentsOfFile:filePath usedEncoding:&encoding error:&error];
	if(error) {
		NSLog(@"error: %@", [error description]);
	}
	
	NSRect frame = [[[webView mainFrame] frameView] frame];
	NSString *width = [NSString stringWithFormat:@"%d", (int)frame.size.width - 17];
	NSString *height = [NSString stringWithFormat:@"%d", (int)frame.size.height - 17];
	
	[htmlString replaceOccurrencesOfString:@"__WIDTH__" withString:width options:NSCaseInsensitiveSearch range:NSMakeRange(0, [htmlString length])];
	[htmlString replaceOccurrencesOfString:@"__HEIGHT__" withString:height options:NSCaseInsensitiveSearch range:NSMakeRange(0, [htmlString length])];
	
	[htmlString replaceOccurrencesOfString:@"__MARKERS__" withString:markers options:NSCaseInsensitiveSearch range:NSMakeRange(0, [htmlString length])];
	
	[[webView mainFrame] loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"http://maps.google.com"]];
	
	mapNeedsResizing = NO;
	
	return nil;
}



@end
