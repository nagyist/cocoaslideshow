//
//  CSSImageContainer.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CSSImageContainer.h"
#import "NSString+CSS.h"
#import "CocoaSlideShow.h"

@implementation CSSImageContainer

/*
- (id)init {
	self = [super init];
	NSLog(@"init %@", self);
	return self;
}
*/

- (NSString *)cachedLatitude {
	return cachedLatitude;
}

- (NSString *)cachedLongitude {
	return cachedLongitude;
}

- (NSString *)cachedTimestamp {
	return cachedTimestamp;
}

- (void)setCachedLatitude:(NSString *)s {
	if([s isEqualToString:cachedLatitude]) return;
	
	[cachedLatitude release];
	cachedLatitude = s;
	[cachedLatitude retain];
}

- (void)setCachedLongitude:(NSString *)s {
	if([s isEqualToString:cachedLongitude]) return;
	
	[cachedLongitude release];
	cachedLongitude = s;
	[cachedLongitude retain];
}

- (void)setCachedTimestamp:(NSString *)s {
	if([s isEqualToString:cachedTimestamp]) return;
	
	[cachedTimestamp release];
	cachedTimestamp = s;
	[cachedTimestamp retain];	
}

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"isFlagged", nil] triggerChangeNotificationsForDependentKey:@"flagIcon"];
}

- (NSString *)fileName {
	return [path lastPathComponent];
}

- (void)setFileName:(NSString *)s {
	NSString *newPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:s];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:newPath]) return;

	if([[NSFileManager defaultManager] movePath:path toPath:newPath handler:nil]) {
		[self setValue:newPath forKey:@"path"];
	}
}

- (void)loadNewBitmap {
	if(bitmap) return;
	
	NSData *data = [NSData dataWithContentsOfFile:path];

	CSSBitmapImageRep *bitmapImageRep = [[CSSBitmapImageRep alloc] initWithData:data];
	[bitmapImageRep setContainer:self]; // TODO: unelegant..
	[bitmapImageRep setPath:path];

	[self willChangeValueForKey:@"bitmap"];
	[bitmap autorelease];
	bitmap = bitmapImageRep;

	[self didChangeValueForKey:@"bitmap"];
}

/*
 x observes b
 
 b is cached
 
 def b:
	 willChangeValueForKey:b		# this makes the observers call b again -> infinite loop
	 load b
	 didChangeValueForKey:b
*/

- (CSSBitmapImageRep *)bitmap {
	if(isLoadingCache || bitmap) return bitmap;
	
	BOOL isSaving = [[[NSApp delegate] valueForKey:@"isSaving"] boolValue];
	BOOL multipleImagesSelected = [[[NSApp delegate] valueForKeyPath:@"imagesController.multipleImagesSelected"] boolValue];
	BOOL isMap = [[[NSApp delegate] valueForKey:@"isMap"] boolValue];
	BOOL readOnMultiSelect = [[NSUserDefaults standardUserDefaults] boolForKey:@"MultipleSelectionAllowsEdition"];
	
	BOOL bitmapLoadingIsAllowed = [(CocoaSlideShow *)[NSApp delegate] bitmapLoadingIsAllowed];

	if(!bitmapLoadingIsAllowed && (isSaving || (!readOnMultiSelect && multipleImagesSelected && !isMap))) {
		return nil;
	}
	
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	CSSBitmapImageRep *bitmapImageRep = [[CSSBitmapImageRep alloc] initWithData:data];
	[bitmapImageRep setContainer:self]; // FIXME: unelegant..
	[bitmapImageRep setPath:path];
		
	if(!isLoadingCache) {
		isLoadingCache = YES;
	}
	
	[self willChangeValueForKey:@"bitmap"];
	[bitmap release];
	bitmap = bitmapImageRep;
	[self didChangeValueForKey:@"bitmap"];

	if(isLoadingCache) {
		isLoadingCache = NO;
	}
	
	return bitmap;
}

- (void)dealloc {
	NSLog(@"-- dealloc %@", path);
	[cachedLatitude release];
	[cachedLongitude release];
	[cachedTimestamp release];
	
	[path release];
	[self willChangeValueForKey:@"bitmap"];
	[bitmap release];
	[self didChangeValueForKey:@"bitmap"];
	[super dealloc];
}

- (void)forgetBitmap {
	NSLog(@"-- forgetBitmap %@", [self path]);

	if(bitmap) {
		NSLog(@"-- release %@", path);
		[self willChangeValueForKey:@"bitmap"];
		[bitmap release];
		bitmap = nil;
		[self didChangeValueForKey:@"bitmap"];
	}
}

- (void)flag {
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isFlagged"];
}

- (void)unflag {
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFlagged"];
}

- (void)toggleFlag {
	[self setValue:[NSNumber numberWithBool:!isFlagged] forKey:@"isFlagged"];
}

- (void)removeFlag {
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFlagged"];	
}

- (BOOL)isFlagged {
	return isFlagged;
}

- (NSImage *)flagIcon {
	return isFlagged ? [NSImage imageNamed:@"Flagged.png"] : nil;
}

- (void)copyToDirectory:(NSString *)destDirectory {
	NSString *destPath = [destDirectory stringByAppendingPathComponent:[path lastPathComponent]];
	NSFileManager *fm = [NSFileManager defaultManager];

	if ([fm fileExistsAtPath:path]) {
		[fm copyPath:path toPath:destPath handler:nil];
	}
}

- (void)moveToTrash {
	NSString *trashPath = [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent:[path lastPathComponent]];
	[[NSFileManager defaultManager] movePath:path toPath:trashPath handler:nil];
}

- (void)revealInFinder {
	[[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (void)setPath:(NSString *)aPath {
	//NSLog(@"-- %@", aPath);
	if(aPath == nil) {
		NSLog(@"-- aPath is nil :-(");
		return;
	}
	if(aPath != nil && path != aPath) {
		[path release];
		path = [aPath retain];
	}
}

- (id)initWithPath:(NSString *)aPath {
	self = [super init];
	[self setPath:aPath];
	return self;
}

+ (CSSImageContainer *)containerWithPath:(NSString *)aPath {
	return [[[CSSImageContainer alloc] initWithPath:aPath] autorelease];
}

- (NSString *)path {
	//NSLog(@"path %@", path);
	return path;
}

@end
