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

- (void)awakeFromNib {
	displayedImages = [[NSMutableSet alloc] initWithArray:[imagesController arrangedObjects]];
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"gmap" ofType:@"html"];	
	
	NSURL *url = [NSURL fileURLWithPath:filePath];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];

	[webView setFrameLoadDelegate:self];
	[[webView mainFrame] loadRequest:request];
	
	scriptObject = [webView windowScriptObject];
	[scriptObject setValue:self forKey:@"mapController"];
}
/*
+ (NSString *)webScriptNameForSelector:(SEL)sel {
	if (sel == @selector(setMapType:))
		return @"setMapType";	
	return nil;
}
*/
- (void)mapTypeDidChange:(id)mapType {
	NSLog(@"-- mapTypeDidChange:%@", mapType);
	
	if([[self mapStyles] containsObject:mapType]) {
		[[NSUserDefaults standardUserDefaults] setValue:mapType forKey:@"mapStyle"];
	}
}

- (void)zoomLevelDidChange:(id)zoomLevel {
	NSLog(@"-- zoomLevelDidChange:%@", zoomLevel);

	[[NSUserDefaults standardUserDefaults] setValue:zoomLevel forKey:@"mapZoom"];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector { return NO; }
+ (BOOL)isKeyExcludedFromWebScript:(const char *)name { return NO; }


- (NSArray *)mapStyles {
	return [NSArray arrayWithObjects:G_PHYSICAL_MAP, G_NORMAL_MAP, G_SATELLITE_MAP, G_HYBRID_MAP, nil];
}

- (void)clearMap {
	[[webView mainFrame] loadRequest:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if(object == imagesController && [keyPath isEqualToString:@"selectedObjects"]) {
		[self evaluateNewJavaScriptOnSelectedObjectsChange];
	} else if(object == imagesController && [keyPath isEqualToString:@"arrangedObjects"]) {
		[self evaluateNewJavaScriptOnArrangedObjectsChange];
	}
}

- (void)evaluateNewJavaScriptOnSelectedObjectsChange {
	NSLog(@"-- evaluateNewJavaScriptOnSelectedObjectsChange");

	NSMutableSet *toShow = [NSMutableSet setWithArray:[imagesController selectedObjects]];
	//[toShow minusSet:displayedImages];
	NSMutableSet *toHide = [displayedImages mutableCopy];
	[toHide minusSet:toShow];
	
	NSMutableArray *jsCommands = [NSMutableArray array];

	CSSImageInfo *imageInfo = nil;
	NSEnumerator *e = [toHide objectEnumerator];
	while((imageInfo = [e nextObject])) {
		NSString *jsHidePoint = [imageInfo jsHidePoint];
		if(!jsHidePoint) continue;
		[jsCommands addObject:jsHidePoint];
		[displayedImages removeObject:imageInfo];
	}

	e = [toShow objectEnumerator];
	while((imageInfo = [e nextObject])) {
		NSString *jsShowPoint = [imageInfo jsShowPoint];
		if(!jsShowPoint) continue;
		[jsCommands addObject:jsShowPoint];
		[displayedImages addObject:imageInfo];
	}
	
	[toHide release];

	NSString *zoom = [[NSUserDefaults standardUserDefaults] valueForKey:@"mapZoom"];
	if(zoom) {
		[jsCommands addObject:[NSString stringWithFormat:@"centerWithZoom(%@);", zoom]];
	} else {
		[jsCommands addObject:[NSString stringWithFormat:@"center();", zoom]];	
	}
	NSString *js = [jsCommands componentsJoinedByString:@"\n"];
	NSLog(@"-- %@", js);
	
	[webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)evaluateNewJavaScriptOnArrangedObjectsChange {
	NSLog(@"-- evaluateNewJavaScriptOnArrangedObjectsChange");
	
	NSMutableSet *toAdd = [NSMutableSet setWithArray:[imagesController arrangedObjects]];
	[toAdd minusSet:displayedImages];
	NSMutableSet *toRemove = [displayedImages mutableCopy];
	[toRemove minusSet:[imagesController arrangedObjects]];
	
	NSMutableArray *jsCommands = [NSMutableArray array];

	CSSImageInfo *imageInfo = nil;
	NSEnumerator *e = [toRemove objectEnumerator];
	while((imageInfo = [e nextObject])) {
		NSString *jsRemovePoint = [imageInfo jsRemovePoint];
		if(!jsRemovePoint) continue;
		[jsCommands addObject:jsRemovePoint];
		[displayedImages removeObject:imageInfo];
	}

	e = [toAdd objectEnumerator];
	while((imageInfo = [e nextObject])) {
		NSString *jsAddPoint = [imageInfo jsAddPoint];
		if(!jsAddPoint) continue;
		[jsCommands addObject:jsAddPoint];
		//[displayedImages removeObject:imageInfo];
	}
	
	e = [[imagesController selectedObjects] objectEnumerator];
	while((imageInfo = [e nextObject])) {
		NSString *jsShowPoint = [imageInfo jsShowPoint];
		if(!jsShowPoint) continue;
		[jsCommands addObject:jsShowPoint];
		[displayedImages addObject:imageInfo];
	}
	
	[toRemove release];
	/*
	NSString *zoom = [[NSUserDefaults standardUserDefaults] valueForKey:@"mapZoom"];
	if(zoom) {
		[jsCommands addObject:[NSString stringWithFormat:@"centerWithZoom(%@);", zoom]];
	} else {
		[jsCommands addObject:[NSString stringWithFormat:@"center();", zoom]];	
	}
	*/
	NSString *js = [jsCommands componentsJoinedByString:@"\n"];
	NSLog(@"-- %@", js);
	
	[webView stringByEvaluatingJavaScriptFromString:js];
	
	//[self evaluateNewJavaScriptOnSelectedObjectsChange];
}

#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	NSString *mapStyle = [[NSUserDefaults standardUserDefaults] stringForKey:@"mapStyle"];
	if(!mapStyle || ![[self mapStyles] containsObject:mapStyle]) {
		mapStyle = G_PHYSICAL_MAP;
		[[NSUserDefaults standardUserDefaults] setValue:mapStyle forKey:@"mapStyle"];
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setMapStyle(%@);", mapStyle]];

	[self evaluateNewJavaScriptOnArrangedObjectsChange];
	
	NSString *zoom = [[NSUserDefaults standardUserDefaults] valueForKey:@"mapZoom"];
	if(zoom) {
		[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"centerWithZoom(%@);", zoom]];
	} else {
		[webView stringByEvaluatingJavaScriptFromString:@"center();"];
	}
}

- (void)dealloc {
	[displayedImages release];
	[super dealloc];
}

@end
