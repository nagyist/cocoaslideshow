#import "ImagesController.h"
#import "CSSImageInfo.h"
#import "NSFileManager+CSS.h"
#import "CocoaSlideShow.h"
#import "NSImage+CSS.h"

static NSString *const kApplyNaturalSortOrder = @"ApplyNaturalSortOrder";

static NSComparisonResult naturalCompare( CSSImageInfo *img1, CSSImageInfo *img2, void *context ) {
	NSString *str1 = [img1 fileName];
	NSString *str2 = [img2 fileName];
	
	return [str1 compare:str2 options:NSNumericSearch];
}

@implementation ImagesController

- (void)awakeFromNib {

	allowedExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"jpe", @"tif", @"tiff", @"gif", @"png", @"pct", @"pict", @"pic",
								  //@"pdf", @"eps", @"epi", @"epsf", @"epsi", @"ps",
								  @"ico", @"icns",  @"bmp", @"bmpf",
								  @"dng", @"cr2", @"crw", @"fpx", @"fpix", @"raf", @"dcr", @"ptng", @"pnt", @"mac", @"mrw", @"nef",
								  @"orf", @"exr", @"psd", @"qti", @"qtif", @"hdr", @"sgi", @"srf", @"targa", @"tga", @"cur", @"xbm", nil];
	imagesToSaveCounter = 0;
    hasImagesToSave = NO;
    [allowedExtensions retain];	
}

- (void)dealloc {
	[inMemoryBitmapsContainers release];
	[allowedExtensions release];
	[super dealloc];
}

- (NSUndoManager *)undoManager {
	return [cocoaSlideShow undoManager];
}

- (NSIndexSet *)flaggedIndexes {
	NSMutableIndexSet *flaggedIndexes = [[NSMutableIndexSet alloc] init];
	
	NSEnumerator *e = [[self arrangedObjects] objectEnumerator];
	CSSImageInfo *container;
	while(( container = [e nextObject] )) {
		if([container isFlagged]) {
			[flaggedIndexes addIndex:[[self arrangedObjects] indexOfObject:container]];
		}
	}
	[self setSelectionIndexes:flaggedIndexes];
	return [flaggedIndexes autorelease];
}

- (void)flagIndexes:(NSIndexSet *)indexSet {
	[[[self arrangedObjects] objectsAtIndexes:indexSet] makeObjectsPerformSelector:@selector(flag)]; 
}

- (IBAction)flag:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] unflag:self];
	[[self selectedObjects] makeObjectsPerformSelector:@selector(flag)];
}

- (IBAction)unflag:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] flag:self];
	[[self selectedObjects] makeObjectsPerformSelector:@selector(unflag)];
}

- (IBAction)toggleFlags:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] toggleFlags:self];
	[[self selectedObjects] makeObjectsPerformSelector:@selector(toggleFlag)];
}

- (IBAction)selectFlags:(id)sender {
    [(NSArrayController *)[[self undoManager] prepareWithInvocationTarget:self] setSelectionIndexes:[self selectionIndexes]];
	[self setSelectionIndexes:[self flaggedIndexes]];
}

- (IBAction)removeAllFlags:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] flagIndexes:[self flaggedIndexes]];
	[[self arrangedObjects] makeObjectsPerformSelector:@selector(removeFlag)];
}

- (IBAction)remove:(id)sender {
	[[[self undoManager] prepareWithInvocationTarget:self] performSelector:@selector(addFiles:) withObject:[self valueForKeyPath:@"selectedObjects.path"]];
	[super remove:sender];
}

- (void)selectPreviousImage {
	
	if([self canSelectPrevious]) {
		[[[self undoManager] prepareWithInvocationTarget:self] selectNext:self];
		[self selectPrevious:self];
	}
}

- (void)selectNextImage {

	if([self canSelectNext]) {
		[[[self undoManager] prepareWithInvocationTarget:self] selectPrevious:self];
		[self selectNext:self];
	}
}

- (BOOL)multipleImagesSelected {
	return [[self selectedObjects] count] > 1;
}

- (BOOL)containsPath:(NSString *)path {
	NSArray *paths = [self valueForKeyPath:@"arrangedObjects.path"];
	return [paths containsObject:path];
}

- (BOOL)extensionIsAllowed:(NSString *)path {
	return [allowedExtensions containsObject:[[path pathExtension] lowercaseString]];
}

- (void)addFiles:(NSArray *)filePaths {
	NSEnumerator *e = [filePaths objectEnumerator];
	NSString *path;
	
	NSMutableArray *imagesInfoToAdd = [NSMutableArray array];
	
	unsigned int count = 0;
	
	while(( path = [e nextObject] )) {
		count++;
		
		if([[NSFileManager defaultManager] isDirectory:path]) {
			NSArray *dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:path recursive:YES];
			[self addFiles:dirContent];
			continue;
		}
		
		if([path hasPrefix:@"."] || ![self extensionIsAllowed:path]) {
			continue;
		}
		
		[imagesInfoToAdd addObject:[CSSImageInfo containerWithPath:path andController:self]];
	}
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:kApplyNaturalSortOrder]) {
		[imagesInfoToAdd sortUsingFunction:&naturalCompare context:nil];
	}
	
	[self addObjects:imagesInfoToAdd];
}

- (void)addDirFiles:(NSString *)dir {
	//NSLog(@"-- addDirFiles: %@", dir);
	[self addFiles:[NSArray arrayWithObject:dir]];
	[[[self undoManager] prepareWithInvocationTarget:self] remove:self];
}

- (IBAction)moveToTrash:(id)sender {
	[[self selectedObjects] makeObjectsPerformSelector:@selector(moveToTrash)];
	[self removeObjectsAtArrangedObjectIndexes:[self selectionIndexes]];
}

- (NSArray *)modifiedObjects {
    NSMutableArray *objects = [NSMutableArray array];
    for (CSSImageInfo *info in [self arrangedObjects]) {
        if ([info isModified]) [objects addObject:info];
    }
    return [NSArray arrayWithArray:objects];
}

- (void)needSaveCSSImageInfo:(CSSImageInfo *)info {
    [self setValue:[NSNumber numberWithBool:++imagesToSaveCounter > 0] forKey:@"hasImagesToSave"];
}

- (void)didSaveCSSImageInfo:(CSSImageInfo *)info {
    [self setValue:[NSNumber numberWithBool:--imagesToSaveCounter > 0] forKey:@"hasImagesToSave"];
}

/*
- (NSArray *)flagged {
	NSPredicate *p = [NSPredicate predicateWithFormat:@"flagged == YES"];
	NSMutableArray *ma = [[self arrangedObjects] mutableCopy];
	[ma filterUsingPredicate:p];
	return [ma autorelease];
}
*/

#pragma mark GPS

- (BOOL)atLeastOneImageWithGPSSelected {
	
	NSEnumerator *e = [[self selectedObjects] objectEnumerator];
	CSSImageInfo *container = nil;

	while((container = [e nextObject])) {
		if([container gps] != nil) return YES;
	}

	return NO;
}

- (IBAction)openGoogleMap:(id)sender {
	if(![[self selectedObjects] count]) return;
	CSSImageInfo *i = [[self selectedObjects] lastObject];
	NSURL *url = [i googleMapsURL];
	if(!url) return;
	[[NSWorkspace sharedWorkspace] openURL:url];
}

@end


