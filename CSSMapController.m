//
//  MapController.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 14.11.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

// TODO: remember map style

#import "CSSMapController.h"
#import "CSSImageContainer.h"

@implementation CSSMapController

- (void)clearMap {
	[[webView mainFrame] loadRequest:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if(object == imagesController && [keyPath isEqualToString:@"selectedObjects"]) {
		[self displayGoogleMapForSelection:self];
	}
}

- (IBAction)displayGoogleMapForSelection:(id)sender {

	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"gmap" ofType:@"html"];
	
	NSURL *url = [NSURL fileURLWithPath:filePath];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];

	[webView setFrameLoadDelegate:self];
	[[webView mainFrame] loadRequest:request];
}

#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	NSEnumerator *e = [[imagesController selectedObjects] objectEnumerator];
	CSSImageContainer *cssImageContainer = nil;
	CSSBitmapImageRep *b = nil;
	NSDictionary *gps = nil;
	while((cssImageContainer = [e nextObject])) {
//		NSLog(@"-- path: %@", [cssImageContainer path]);
		
		b = [cssImageContainer bitmap];
		
		gps = [b gps];
//		NSLog(@"gps: %@", gps);
		if(!gps) continue;
		
		NSNumber *latitude = [gps objectForKey:@"Latitude"];
		NSNumber *longitude = [gps objectForKey:@"Longitude"];
		if(!latitude || !longitude) continue;
		
		NSString *filePath = [cssImageContainer path];
		NSString *fileName = [filePath lastPathComponent];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
		NSString *fileModDateString = fileAttributes ? [[fileAttributes objectForKey:NSFileModificationDate] description] : @"";
		
		NSString *js = [NSString stringWithFormat:@"addPoint(%@, %@, \"%@\", \"%@\", \"%@\");", latitude, longitude, fileName, filePath, fileModDateString];
//		NSLog(@"-- js:%@", js);
		[webView stringByEvaluatingJavaScriptFromString:js];
	}

	[webView stringByEvaluatingJavaScriptFromString:@"center();"];
	
}

@end
