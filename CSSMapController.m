//
//  MapController.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 14.11.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

// TODO: remember map style

#import "CSSMapController.h"
#import "CSSImageInfo.h"
#import "CocoaSlideShow.h"
#import "NSImage+CSS.h"

NSString *const G_NORMAL_MAP = @"G_NORMAL_MAP";
NSString *const G_HYBRID_MAP = @"G_HYBRID_MAP";
NSString *const G_SATELLITE_MAP = @"G_SATELLITE_MAP";
NSString *const G_PHYSICAL_MAP = @"G_PHYSICAL_MAP";

@implementation CSSMapController

- (NSArray *)mapStyles {
	return [NSArray arrayWithObjects:G_PHYSICAL_MAP, G_NORMAL_MAP, G_SATELLITE_MAP, G_HYBRID_MAP, nil];
}

- (void)clearMap {
	[[webView mainFrame] loadRequest:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if(object == imagesController && [keyPath isEqualToString:@"selectedObjects"]) {
		[self displayGoogleMapForSelection:self];
	}
}

// TODO: don't reload map each time, simply adjust the content
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
	CSSImageInfo *cssImageInfo = nil;
	
	NSString *mapStyle = [[NSUserDefaults standardUserDefaults] stringForKey:@"mapStyle"];
	if(!mapStyle || ![[self mapStyles] containsObject:mapStyle]) {
		mapStyle = G_PHYSICAL_MAP;
		[[NSUserDefaults standardUserDefaults] setValue:mapStyle forKey:@"mapStyle"];
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setMapStyle(%@);", mapStyle]];

	while((cssImageInfo = [e nextObject])) {		
		
		NSString *filePath = [cssImageInfo path];
		NSString *fileName = [filePath lastPathComponent];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
		NSString *fileModDateString = fileAttributes ? [[fileAttributes objectForKey:NSFileModificationDate] description] : @"";
		
		NSString *latitude = [cssImageInfo prettyLatitude];
		NSString *longitude = [cssImageInfo prettyLongitude];
		
		if(!latitude || !longitude) {
			continue;
		}
		
//		NSString *js = [NSString stringWithFormat:@"addPoint(%@, %@, \"%@\", \"%@\", \"%@\");", latitude, longitude, fileName, filePath, fileModDateString];
		NSString *js = [NSString stringWithFormat:@"addPoint(%@, %@, \"%@\", \"%@\", \"%@\", %d);", latitude, longitude, fileName, filePath, fileModDateString, [cssImageInfo orientationDegrees]];
		//NSLog(@"-- js:%@", js);
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
	
	[webView stringByEvaluatingJavaScriptFromString:@"center();"];
	
}

@end
