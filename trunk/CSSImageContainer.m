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

- (void)loadBitmap {
	if(bitmap) return;
	
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSLog(@"-- will load bitmap with data %d", data != nil);
	CSSBitmapImageRep *bitmapImageRep = [[[CSSBitmapImageRep alloc] initWithData:data] autorelease];
	NSLog(@"-- did load bitmap %d", bitmapImageRep != nil);

	[bitmapImageRep setContainer:self];
	[bitmapImageRep setPath:path];
	
	[self setValue:bitmapImageRep forKey:@"bitmap"];
}

- (CSSBitmapImageRep *)bitmap {
	if(bitmap) return bitmap;
	
	//BOOL importDone = [[[NSApp delegate] valueForKeyPath:@"imagesController.importDone"] boolValue];
	BOOL isSaving = [[[NSApp delegate] valueForKey:@"isSaving"] boolValue];
	BOOL multipleImagesSelected = [[[NSApp delegate] valueForKeyPath:@"imagesController.multipleImagesSelected"] boolValue];
	BOOL isMap = [[[NSApp delegate] valueForKey:@"isMap"] boolValue];
	BOOL readOnMultiSelect = [[NSUserDefaults standardUserDefaults] boolForKey:@"MultipleSelectionAllowsEdition"];
	
	BOOL bitmapLoadingIsAllowed = [(CocoaSlideShow *)[NSApp delegate] bitmapLoadingIsAllowed];
	NSLog(@"-- %d %d", [(CocoaSlideShow *)[NSApp delegate] bitmapLoadingIsAllowed], bitmap != nil);
	
	//NSLog(@"-- %d %d %d %d", isSaving, multipleImagesSelected, isMap, readOnMultiSelect);
	if(!bitmapLoadingIsAllowed && (isSaving || (!readOnMultiSelect && multipleImagesSelected && !isMap))) {
		return nil;
	}

	if(bitmap != nil) {
		//NSLog(@"return bitmap");
		return bitmap;
	}
	//NSLog(@"read and return bitmap %@", path);

	[self loadBitmap];
	
	NSLog(@"-- self:%@ path:%@ bitmapPath:%@ setValue:%@", self, path, [bitmap path], bitmap);
	
	return bitmap;	
}

- (void)dealloc {
	[path release];
	[bitmap release];
	[super dealloc];
}

- (void)forgetBitmap {
	if(bitmap) {
		[bitmap release];
		bitmap = nil;
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
