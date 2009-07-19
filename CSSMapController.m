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
	
	NSString *mapStyle = [[NSUserDefaults standardUserDefaults] stringForKey:@"mapStyle"];
	if(!mapStyle || ![[self mapStyles] containsObject:mapStyle]) {
		mapStyle = G_PHYSICAL_MAP;
		[[NSUserDefaults standardUserDefaults] setValue:mapStyle forKey:@"mapStyle"];
	}
	[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setMapStyle(%@);", mapStyle]];

	while((cssImageContainer = [e nextObject])) {		
		
		NSString *filePath = [cssImageContainer path];
		NSString *fileName = [filePath lastPathComponent];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:YES];
		NSString *fileModDateString = fileAttributes ? [[fileAttributes objectForKey:NSFileModificationDate] description] : @"";
		
		NSString *latitude = [cssImageContainer prettyLatitude];
		NSString *longitude = [cssImageContainer prettyLongitude];
		
		if(!latitude || !longitude) {
			continue;
		}
		
		NSString *js = [NSString stringWithFormat:@"addPoint(%@, %@, \"%@\", \"%@\", \"%@\");", latitude, longitude, fileName, filePath, fileModDateString];
		//NSLog(@"-- js:%@", js);
		[webView stringByEvaluatingJavaScriptFromString:js];
	}
	
	[webView stringByEvaluatingJavaScriptFromString:@"center();"];
	
}

- (void)updateExportProgress:(NSNumber *)n {
	NSLog(@"-- updateExportProgress %@", n);
}

- (void)exportFinished {
	NSLog(@"-- exportFinished");
}

#pragma KML File Export

// TODO: when 10.5 only, use http://www.entropy.ch/software/macosx/#epegwrapper
- (void)generateKMLWithThumbsDirInSeparateThread:(NSDictionary *)options {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *kmlFilePath = [options objectForKey:@"kmlFilePath"];
	BOOL addThumbnails = [[options objectForKey:@"addThumbnails"] boolValue];
	NSString *thumbsDir = nil;
	if(addThumbnails) thumbsDir = [[kmlFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"images"];
	
	unsigned int imagesCount = [[imagesController selectedObjects] count];
	int count = 0;
	NSEnumerator *e = [[imagesController selectedObjects] objectEnumerator];
	CSSImageContainer *cssImageContainer = nil;
	NSString *XMLContainer = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Folder>\n%@</Folder>\n</kml>\n";
	
	NSMutableString *placemarkString = [[[NSMutableString alloc] init] autorelease];
	
	while((cssImageContainer = [e nextObject])) {
		NSLog(@"-- will add %@", [cssImageContainer path]);
		// TODO: call main thread
		count++;

		NSString *latitude = [cssImageContainer prettyLatitude];
		NSString *longitude = [cssImageContainer prettyLongitude];
		NSString *timestamp = [cssImageContainer exifDateTime];
		
		NSString *imageName = [[cssImageContainer path] lastPathComponent];
		
		if([latitude length] == 0 || [longitude length] == 0) {
			continue;
		}

		[placemarkString appendFormat:@"    <Placemark><name>%@</name><timestamp><when>%@</when></timestamp><Point><coordinates>%@,%@</coordinates></Point>", imageName, timestamp, longitude, latitude];
		
		if(addThumbnails) {
			NSString *imageName = [[[cssImageContainer path] lastPathComponent] lowercaseString];
			[placemarkString appendFormat:@"<description>&lt;img src=\"images/%@\" /&gt;</description><Style><text>$[description]</text></Style> ", imageName];
		}

		[placemarkString appendFormat:@"</Placemark>\n"];
		
		if(addThumbnails) {
			[self performSelectorOnMainThread:@selector(updateExportProgress:) withObject:[NSNumber numberWithFloat:(float)count/imagesCount] waitUntilDone:NO];
			NSString *thumbPath = [thumbsDir stringByAppendingPathComponent:[[cssImageContainer path] lastPathComponent]];
			BOOL success = [NSImage scaleAndSaveAsJPEG:[cssImageContainer path] maxwidth:640.0 maxheight:480.0 quality:0.75 saveTo:thumbPath];
			if(!success) NSLog(@"Could not scale and save as jpeg into %@", thumbPath);
		}
	}
	
	NSLog(@"-- finished!");
		
	NSString *kml = [NSString stringWithFormat:XMLContainer, placemarkString];
	
	NSError *error = nil;
	[kml writeToFile:kmlFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
	if(error) [[NSAlert alertWithError:error] runModal];
	
	[pool release];
}

- (NSString *)chooseKMLExportDirectory {
    NSSavePanel *sPanel = [NSSavePanel savePanel];
	
	[sPanel setAccessoryView:kmlSavePanelAccessoryView];
	
	[sPanel setRequiredFileType:@""];
	[sPanel setCanCreateDirectories:YES];
	
	NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];

	int runResult = [sPanel runModalForDirectory:desktopPath file:@"CocoaSlideShow"];
	
	return (runResult == NSOKButton) ? [sPanel filename] : nil;
}

- (IBAction)exportKMLToFile:(id)sender {
	NSString *kmlFilePath = nil;
	NSString *thumbsDir = nil;
	
	NSString *dir = [self chooseKMLExportDirectory];
	if(!dir) return;

	BOOL addThumbnails = [[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeThumbsInKMLExport"];

	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:dir attributes:nil];
	if(!success) {
		NSLog(@"Error: can't create dir at path %@", dir);
		return;
	}
	
	kmlFilePath = [dir stringByAppendingPathComponent:@"CocoaSlideShow.kml"];

	if(addThumbnails) {
		thumbsDir = [dir stringByAppendingPathComponent:@"images"];
		success = [[NSFileManager defaultManager] createDirectoryAtPath:thumbsDir attributes:nil];
		if(!success) {
			NSLog(@"Error: can't create dir at path %@", thumbsDir);
			return;
		}
	}
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:kmlFilePath, @"kmlFilePath", [NSNumber numberWithBool:addThumbnails], @"addThumbnails", nil];
	
	[NSThread detachNewThreadSelector:@selector(generateKMLWithThumbsDirInSeparateThread:) toTarget:self withObject:options];
}


@end
