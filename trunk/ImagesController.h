/* ImagesController */

#import <Cocoa/Cocoa.h>

#define IN_MEMORY_BITMAPS 5

@class CocoaSlideShow;
@class CSSImageContainer;

@interface ImagesController : NSArrayController
{
	IBOutlet CocoaSlideShow *cocoaSlideShow;
	BOOL importDone;
	unsigned inMemoryBitmapsNextIndex;
	NSMutableArray *inMemoryBitmapsContainers;
	NSArray *allowedExtensions;
}

- (void)bitmapWasLoadedInContainer:(CSSImageContainer *)c;
- (NSUndoManager *)undoManager;
- (NSIndexSet *)flaggedIndexes;
- (void)flagIndexes:(NSIndexSet *)indexSet;
- (IBAction)flag:(id)sender;
- (IBAction)unflag:(id)sender;
- (IBAction)toggleFlags:(id)sender;
- (IBAction)selectFlags:(id)sender;
- (IBAction)removeAllFlags:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)moveToTrash:(id)sender;
- (BOOL)containsPath:(NSString *)path;
- (BOOL)multipleImagesSelected;
- (void)selectPreviousImage;
- (void)selectNextImage;
- (void)addFiles:(NSArray *)filePaths;
- (void)addDirFiles:(NSString *)dir;
//- (void)forgetUnusedBitmaps;
//- (NSArray *)flagged;
//- (NSArray *)selectedObjectsWithGPS;
- (BOOL)atLeastOneImageWithGPSSelected;
- (IBAction)openGoogleMap:(id)sender;

@end
