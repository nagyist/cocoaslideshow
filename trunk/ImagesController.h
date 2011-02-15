/* ImagesController */

#import <Cocoa/Cocoa.h>

@class CocoaSlideShow;
@class CSSImageInfo;

@interface ImagesController : NSArrayController
{
	IBOutlet CocoaSlideShow *cocoaSlideShow;
    int imagesToSaveCounter;
    BOOL hasImagesToSave;
	BOOL importDone;
	unsigned inMemoryBitmapsNextIndex;
	NSMutableArray *inMemoryBitmapsContainers;
	NSArray *allowedExtensions;
	NSString *thumbsDir;
}

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
- (BOOL)atLeastOneImageWithGPSSelected;
- (IBAction)openGoogleMap:(id)sender;
- (NSArray *)modifiedObjects;
- (void)needSaveCSSImageInfo:(CSSImageInfo *)info;
- (void)didSaveCSSImageInfo:(CSSImageInfo *)info;


@end
