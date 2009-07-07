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
#import "CSSBitmapImageRep.h"
#import "CocoaSlideShow.h"

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
	//CSSBitmapImageRep *b = nil;
	
	while((cssImageContainer = [e nextObject])) {		
		
		NSString *filePath = [cssImageContainer path];
		NSString *fileName = [filePath lastPathComponent];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
		NSString *fileModDateString = fileAttributes ? [[fileAttributes objectForKey:NSFileModificationDate] description] : @"";
		
		NSString *latitude = [cssImageContainer cachedLatitude];
		NSString *longitude = [cssImageContainer cachedLongitude];

		if(!latitude || !longitude) {
			[cssImageContainer loadNewBitmap];
			
			latitude = [cssImageContainer cachedLatitude];
			longitude = [cssImageContainer cachedLongitude];			
		}
		
		if(!latitude || !longitude) {
			//[cssImageContainer forgetBitmap]; // FIXME: does trigger KVO issue
			continue;
		}
		
		NSString *js = [NSString stringWithFormat:@"addPoint(%@, %@, \"%@\", \"%@\", \"%@\");", latitude, longitude, fileName, filePath, fileModDateString];
		//NSLog(@"-- js:%@", js);
		[webView stringByEvaluatingJavaScriptFromString:js];
				
		[imagesController retainOnlyAFewImagesAndReleaseTheRest];
	}
	
	[webView stringByEvaluatingJavaScriptFromString:@"center();"];
	
}

#pragma KML File Export

- (NSString*)generateKML {
	
	[(CocoaSlideShow *)[NSApp delegate] setBitmapLoadingIsAllowed:YES];
	
	NSEnumerator *e = [[imagesController selectedObjects] objectEnumerator];
	CSSImageContainer *cssImageContainer = nil;
	//CSSBitmapImageRep *b = nil;
	NSString *XMLContainer = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Folder>\n%@</Folder>\n</kml>\n";
	
	NSMutableString *placemarkString = [[[NSMutableString alloc] init] autorelease];
	
	while((cssImageContainer = [e nextObject])) {
		
		NSString *latitude = [cssImageContainer cachedLatitude];
		NSString *longitude = [cssImageContainer cachedLongitude];
		NSString *timestamp = [cssImageContainer cachedTimestamp];
		
		if(!latitude || !longitude) {
			//NSLog(@"--3");
			[cssImageContainer loadNewBitmap];
			latitude = [cssImageContainer cachedLatitude];
			longitude = [cssImageContainer cachedLongitude];
			timestamp = [cssImageContainer cachedTimestamp];
		}

		if(!latitude || !longitude) {
			continue;
		}
		
		[placemarkString appendFormat:@"    <Placemark><name>%@</name><timestamp><when>%@</when></timestamp><Point><coordinates>%@,%@</coordinates></Point></Placemark>\n",
		 [[cssImageContainer path] lastPathComponent], timestamp, longitude, latitude];
	}
	
	[(CocoaSlideShow *)[NSApp delegate] setBitmapLoadingIsAllowed:NO];
	
	return [NSString stringWithFormat:XMLContainer, placemarkString];
}

- (IBAction)exportKMLToFile:(id)sender {
	NSString *destFile = [self chooseFile];
	
	if(!destFile) return;
	
	NSError *error = nil;
	[[self generateKML] writeToFile:destFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
	if(error) [NSAlert alertWithError:error];
}

- (NSString *)chooseFile {
    NSSavePanel *sPanel = [NSSavePanel savePanel];
	
	[sPanel setRequiredFileType:@"kml"];
	[sPanel setCanCreateDirectories:YES];
	
	int runResult = [sPanel runModalForDirectory:NSHomeDirectory() file:@""];
	
	return (runResult == NSOKButton) ? [sPanel filename] : nil;
}

@end
