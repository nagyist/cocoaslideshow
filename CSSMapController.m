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
	
	while((cssImageContainer = [e nextObject])) {
		//		NSLog(@"-- path: %@", [cssImageContainer path]);
		
		b = [cssImageContainer bitmap];
		
		NSString *filePath = [cssImageContainer path];
		NSString *fileName = [filePath lastPathComponent];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
		NSString *fileModDateString = fileAttributes ? [[fileAttributes objectForKey:NSFileModificationDate] description] : @"";
		
		NSString *js = [NSString stringWithFormat:@"addPoint(%@, %@, \"%@\", \"%@\", \"%@\");", [b prettyLatitude], [b prettyLongitude], fileName, filePath, fileModDateString];
		NSLog(@"-- js:%@", js);
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
	
	[webView stringByEvaluatingJavaScriptFromString:@"center();"];
	
}

#pragma KML File Export

- (NSString*) generateKML {
	
	NSEnumerator *e = [[imagesController selectedObjects] objectEnumerator];
	CSSImageContainer *cssImageContainer = nil;
	CSSBitmapImageRep *b = nil;
	NSString *XMLContainer = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Folder>\n%@</Folder>\n</kml>\n";
	
	NSMutableString *placemarkString = [[[NSMutableString alloc] init] autorelease];
	
	while((cssImageContainer = [e nextObject])) {
		b = [cssImageContainer bitmap];
		
		[placemarkString appendFormat:@"    <Placemark><name>%@</name><timestamp><when>%@</when></timestamp><Point><coordinates>%@,%@</coordinates></Point></Placemark>\n",
		 [[cssImageContainer path] lastPathComponent], [b exifDateTime], [b prettyLongitude], [b prettyLatitude]];
	}
	
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
