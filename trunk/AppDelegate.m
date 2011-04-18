#import "AppDelegate.h"
#import "AppleRemote.h"

#import "NSFileManager+CSS.h"
#import <Sparkle/SUUpdater.h>

#import "CSSBorderlessWindow.h"

#import <Carbon/Carbon.h>

#import "NSImage+CSS.h"

#import "CSSImageInfo.h"

static NSString *const kImagesDirectory = @"ImagesDirectory";
static NSString *const kKMLThumbnailsRemoteURLs = @"KMLThumbnailsRemoteURLs";
static NSString *const kRemoteKMLThumbnails = @"RemoteKMLThumbnails";
static NSString *const kSlideShowSpeed = @"SlideShowSpeed";
static NSString *const kThumbsExportSizeTag = @"ThumbsExportSizeTag";
static NSString *const kThumbsExportSizeHeight = @"ThumbsExportSizeHeight";
static NSString *const kThumbsExportSizeWidth = @"ThumbsExportSizeWidth";
static NSString *const kSlideshowIsFullscreen = @"SlideshowIsFullscreen";

@implementation AppDelegate

- (id)init {
	self = [super init];
	
	images = [[NSMutableArray alloc] init];
	isFullScreen = NO;
	takeFilesFromDefault = YES;
		
	undoManager = [[NSUndoManager alloc] init];
	[undoManager setLevelsOfUndo:10];

	return self;
}

- (ImagesController *)imagesController {
	return imagesController;
}

- (void)dealloc {
	[mainWindow release];
	[imagesController release];
	[images release];
	[remoteControl autorelease];
	[undoManager release];

	[super dealloc];
}

- (void)playSuccessSound {
	NSString *soundPath = @"/System/Library/Sounds/Hero.aiff";
	if([[NSFileManager defaultManager] fileExistsAtPath:soundPath]) {
		NSSound *sound = [[NSSound alloc] initWithContentsOfFile:soundPath byReference:YES];
		[sound play];
		[sound release];
	}
}

- (NSUndoManager *)undoManager {
	return undoManager;
}

- (BOOL)isMap {
	return [tabView selectedTabViewItem] == mapTabViewItem;
}

- (void)setupImagesControllerWithDir:(NSString *)dir recursive:(BOOL)isRecursive {
	[images removeAllObjects];

	NSArray *dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:dir recursive:isRecursive];
	
	dirContent = [dirContent sortedArrayUsingSelector:@selector(numericCompare:)];
	
	[imagesController addFiles:dirContent];
	if([dirContent count] > 0) [imagesController setSelectionIndex:0];
}

- (void)setupToolbar {
    toolbar = [[[NSToolbar alloc] initWithIdentifier:@"mainToolbar"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [mainWindow setToolbar:toolbar];
}

- (void)awakeFromNib {
	remoteControl = [[AppleRemote alloc] initWithDelegate: self];
	
	[mainWindow registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	
	[self setupToolbar];
	
	[[userCommentTextField cell] setSendsActionOnEndEditing:YES];
	[[keywordsTokenField cell] setSendsActionOnEndEditing:YES];
	
	[imagesController setAutomaticallyPreparesContent:YES];
	
	NSTableColumn *flagColumn = [tableView tableColumnWithIdentifier:@"flag"];
	NSImage *flagHeaderImage = [NSImage imageNamed:@"FlaggedHeader.png"];
	NSImageCell *flagHeaderImageCell = [flagColumn headerCell];
	[flagHeaderImageCell setImage:flagHeaderImage];
	[flagColumn setHeaderCell:flagHeaderImageCell];
	
	[tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
	[tableView setDraggingSourceOperationMask:NSDragOperationNone forLocal:YES];
	
	//[imageView setDelegate:self];
	[mainWindow setDelegate:self];
	
	[progressIndicator setHidden:YES];

	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:1.0], @"SlideShowSpeed",
	    [NSNumber numberWithBool:YES], @"SlideshowIsFullscreen", nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
#ifndef NSAppKitVersionNumber10_5
#define NSAppKitVersionNumber10_5 949
#endif

	unsigned int _NSImageScaleProportionallyUpOrDown = 3;
	
	if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_5) {
		[panelImageView setImageScaling:_NSImageScaleProportionallyUpOrDown];
	}
}

- (NSString *)chooseDirectory {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseFiles:NO];
    [oPanel setCanChooseDirectories:YES];

    int result = [oPanel runModalForDirectory:nil
                                         file:nil
                                        types:nil];
    NSString *dir = nil;
	
	if (result == NSOKButton) {
		dir = [[oPanel filenames] lastObject];
    }
	
	return dir;
}

- (IBAction)open:(id)sender {
	NSString *dir = [self chooseDirectory];
	if(dir) {
		[self setupImagesControllerWithDir:dir recursive:YES];
	}
}

- (IBAction)setDirectory:(id)sender {
	NSString *dir = [self chooseDirectory];
	if(dir) {
		[self setupImagesControllerWithDir:dir recursive:YES];
		[[NSUserDefaults standardUserDefaults] setValue:dir forKey:kImagesDirectory];
	}
}

- (IBAction)addDirectory:(id)sender {
	NSString *dir = [self chooseDirectory];
	if(dir) {
		[imagesController addDirFiles:dir];
	}
}

- (IBAction)exportToDirectory:(id)sender {
	NSString *destDirectory = [self chooseDirectory];
	if(!destDirectory) {
		return;
	}

	[[imagesController selectedObjects] makeObjectsPerformSelector:@selector(copyToDirectory:) withObject:destDirectory];
	[self playSuccessSound];
}

- (BOOL)isFullScreen {
	return isFullScreen;
}

- (void)rotate:(NSImageView *)iv clockwise:(BOOL)cw {
	[iv setImage:[[iv image] rotatedWithAngle: cw ? -90 : 90]];
	
	SEL selector = cw ? @selector(rotateLeft) : @selector(rotateRight);
	[[imagesController selectedObjects] makeObjectsPerformSelector:selector];
}

- (IBAction)rotateLeft:(id)sender {
	NSImageView *iv = isFullScreen ? panelImageView : imageView;
	[self rotate:iv clockwise:NO];
}

- (IBAction)rotateRight:(id)sender {
	NSImageView *iv = isFullScreen ? panelImageView : imageView;
	[self rotate:iv clockwise:YES];
}

- (IBAction)fullScreenMode:(id)sender {
	
	if(isFullScreen) return;

	[NSCursor setHiddenUntilMouseMoves:YES];

	SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
		
	NSScreen *screen = [mainWindow screen];

	[slideShowPanel setContentSize:[screen frame].size];
    [slideShowPanel setFrame:[screen frame] display:YES];

	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isFullScreen"];
}

- (IBAction)undo:(id)sender {
	[undoManager undo];
}

- (IBAction)redo:(id)sender {
	[undoManager redo];
}

- (void)invalidateTimer {
	if([timer isValid]) {
		[timer invalidate];
		timer = nil;
	}	
}

- (IBAction)exitFullScreen:(id)sender {

	if(!isFullScreen) return;
	
	SetSystemUIMode(kUIModeNormal, 0);
	
	[self invalidateTimer];

	[NSCursor unhide];
	
	[slideShowPanel orderOut:self];

	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isFullScreen"];
}

- (IBAction)toggleFullScreen:(id)sender {
	if(isFullScreen) {
		[self exitFullScreen:nil];
	} else {
		[self fullScreenMode:nil];	
	}
}

- (void)timerNextTick {
	if(![imagesController canSelectNext]) {
		[self invalidateTimer];
	}
	[imagesController selectNextImage]; 
}

- (IBAction)toggleSlideShow:(id)sender {
	if([timer isValid]) {
		[self invalidateTimer];
	} else {
		timer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] valueForKey:kSlideShowSpeed] floatValue]
												  target:self
												selector:@selector(timerNextTick)
												userInfo:NULL
												repeats:YES];
	}
}

- (IBAction)startSlideShow:(id)sender {
	if([[NSUserDefaults standardUserDefaults] boolForKey:kSlideshowIsFullscreen]) {
		[self fullScreenMode:self];
	}
	[self toggleSlideShow:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self exitFullScreen:self];
}

- (void)hideGoogleMap {
	[tabView selectTabViewItem:imageTabViewItem];
	[imagesController removeObserver:mapController forKeyPath:@"selectedObjects"];
	[imagesController removeObserver:mapController forKeyPath:@"arrangedObjects"];
	[mapController clearMap];
}

- (void)showGoogleMap {
	[tabView selectTabViewItem:mapTabViewItem];
	[imagesController addObserver:mapController forKeyPath:@"selectedObjects" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:NULL];
	[imagesController addObserver:mapController forKeyPath:@"arrangedObjects" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:NULL];
	[mapController evaluateNewJavaScriptOnArrangedObjectsChange];
}

- (IBAction)toggleGoogleMap:(id)sender {
	if([tabView selectedTabViewItem] == mapTabViewItem) {
		[self hideGoogleMap];
	} else {
		[self showGoogleMap];
	}
}

- (void) sendRemoteButtonEvent: (RemoteControlEventIdentifier) event pressedDown: (BOOL) pressedDown remoteControl: (RemoteControl*) remoteControl {
	//NSLog(@"Button %d pressed down %d", event, pressedDown);
	
	NSString* buttonName=nil;
	NSString* pressed=@"";
	
	if(!pressedDown) {
		return;
	}
	
	switch(event) {
		case kRemoteButtonPlus:
			buttonName = @"Volume up";
			[self rotateRight:self];
			
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";			
			break;
		case kRemoteButtonMinus:
			buttonName = @"Volume down";
			[self rotateLeft:self];
			
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";
			break;			
		case kRemoteButtonMenu:
			buttonName = @"Menu";
			if(isFullScreen) {
				[self exitFullScreen:self];
			} else {
				[self fullScreenMode:self];
			}
			break;			
		case kRemoteButtonPlay:
			buttonName = @"Play";
			
			if(isFullScreen) {
				[self toggleSlideShow:self];
			} else {
				[self startSlideShow:self];
			}
			
			break;			
		case kRemoteButtonRight:	
			buttonName = @"Right";
			[imagesController selectNextImage];
			break;			
		case kRemoteButtonLeft:
			buttonName = @"Left";
			[imagesController selectPreviousImage];
			break;			
		case kRemoteButtonRight_Hold:
			buttonName = @"Right holding";	
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";
			break;	
		case kRemoteButtonLeft_Hold:
			buttonName = @"Left holding";		
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";
			break;			
		case kRemoteButtonPlay_Hold:
			buttonName = @"Play (sleep mode)";
			break;			
		case kRemoteButtonMenu_Hold:
			buttonName = @"Menu (long)";
			break;
		case kRemoteControl_Switched:
			buttonName = @"Remote Control Switched";
			break;
		default:
			//NSLog(@"Unmapped event for button %d", event); 
			break;
	}
	
	//NSLog(@"buttonName %@", buttonName);
}

#pragma mark NSApplication Delegates

- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
    [remoteControl startListening: self];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
    [remoteControl stopListening: self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if(takeFilesFromDefault) {
		NSString *defaultDir = [NSString pathWithComponents:[NSArray arrayWithObjects:NSHomeDirectory(), @"Pictures", nil]];
		NSString *defaultValue = [[NSUserDefaults standardUserDefaults] valueForKey:kImagesDirectory];
		if(defaultValue) {
			defaultDir = defaultValue;
		}
		[self setupImagesControllerWithDir:defaultDir recursive:NO];
	}
	
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	if([filenames count] > 0) {
		int numberOfImagesBefore = [[imagesController arrangedObjects] count];
		[imagesController addFiles:filenames];
		int numberOfImagesAfter = [[imagesController arrangedObjects] count];
		if(numberOfImagesAfter > numberOfImagesBefore) {
			[imagesController setSelectionIndex:numberOfImagesBefore];
		}
		takeFilesFromDefault = NO;
	}
}

#pragma mark NSWindow delegates

- (void)windowWillClose:(NSNotification *)aNotification {
	[NSApp terminate:self];
}

#pragma mark NSDraggingSource

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSArray *files = [[[imagesController arrangedObjects] objectsAtIndexes:rowIndexes] valueForKey:@"path"];
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
    [pboard setPropertyList:files forType:NSFilenamesPboardType];
    return YES;
}

#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	//NSLog(@"%s", __FUNCTION__);
	return NSDragOperationLink;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	//NSLog(@"%s", __FUNCTION__);
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	//NSLog(@"%s", __FUNCTION__);
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];

		int numberOfImagesBefore = [[imagesController arrangedObjects] count];

		//NSLog(@"CocoaSlidesShow.m | performDragOperation | add files: %@", files);
		[imagesController addFiles:files];
		
		int numberOfImagesAfter = [[imagesController arrangedObjects] count];
		if(numberOfImagesAfter > numberOfImagesBefore) {
			[imagesController setSelectionIndex:numberOfImagesBefore];
		}
    }
    return YES;
}

- (IBAction)revealInFinder:(id)sender {
	[[imagesController selectedObjects] makeObjectsPerformSelector:@selector(revealInFinder)];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	isSaving = YES;
	return YES;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	isSaving = NO;
}

#pragma mark NSTableView delegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {	
	if([tabView selectedTabViewItem] == mapTabViewItem && [[imagesController selectedObjects] count] == 0) {
		[self hideGoogleMap];
	}
}

- (void)prepareProgressIndicator:(unsigned int)count {
	[progressIndicator setHidden:NO];
	[progressIndicator setMinValue:(double)0.0];
	[progressIndicator setMaxValue:(double)count];
	[progressIndicator setDoubleValue:0.0];
}

- (void)exportFinished {
	[self playSuccessSound];
	
	[progressIndicator setDoubleValue:1.0];
	[progressIndicator setHidden:YES];
	[progressIndicator setDoubleValue:0.0];
	
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isExporting"];
}

#pragma mark KML export

- (void)updateExportProgress:(NSNumber *)n {
	[progressIndicator setDoubleValue:[n doubleValue]];
}

#pragma KML File Export

- (void)generateKMLWithThumbsDirInSeparateThread:(NSDictionary *)options {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSArray *exportImages = [options objectForKey:@"images"];
	NSString *kmlFilePath = [options objectForKey:@"kmlFilePath"];
	BOOL addThumbnails = [[options objectForKey:@"addThumbnails"] boolValue];
	NSString *thumbsDir = nil;
	if(addThumbnails) thumbsDir = [[kmlFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"images"];
	
	NSEnumerator *e = [exportImages objectEnumerator];
	CSSImageInfo *cssImageInfo = nil;
	NSString *XMLContainer = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> <kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Folder>\n%@</Folder>\n</kml>\n";
	
	BOOL useRemoteBaseURL = [[NSUserDefaults standardUserDefaults] boolForKey:kRemoteKMLThumbnails];
	NSString *baseURL = @"images/";
	if(useRemoteBaseURL) {
		baseURL = [[NSUserDefaults standardUserDefaults] valueForKey:kKMLThumbnailsRemoteURLs];
		if(![baseURL hasSuffix:@"/"]) {
			baseURL = [baseURL stringByAppendingString:@"/"];
		}
	}
	
	NSMutableString *placemarkString = [[NSMutableString alloc] init];
	
	//NSDate *d1 = [NSDate date];
	
	unsigned int count = 0;
	while((cssImageInfo = [e nextObject])) {
		count++;

		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSString *latitude = [cssImageInfo prettyLatitude];
		NSString *longitude = [cssImageInfo prettyLongitude];
		NSString *timestamp = [cssImageInfo exifDateTime];
		
		NSString *imageName = [[[cssImageInfo path] lastPathComponent] lowercaseString];
		
		if([latitude length] == 0 || [longitude length] == 0) {
			[pool release];
			continue;
		}
		
		[placemarkString appendFormat:@"    <Placemark><name>%@</name><timestamp><when>%@</when></timestamp><Point><coordinates>%@,%@</coordinates></Point>", imageName, timestamp, longitude, latitude];
		
		if(addThumbnails) {
			NSString *imageName = [[[cssImageInfo path] lastPathComponent] lowercaseString];
			[placemarkString appendFormat:@"<description>&lt;img src=\"%@%@\" /&gt;</description><Style><text>$[description]</text></Style> ", baseURL, imageName];
		}

		[placemarkString appendFormat:@"</Placemark>\n"];
		
		if(addThumbnails) {
			[self performSelectorOnMainThread:@selector(updateExportProgress:) withObject:[NSNumber numberWithInt:count] waitUntilDone:NO];
			NSString *thumbPath = [[thumbsDir stringByAppendingPathComponent:[[cssImageInfo path] lastPathComponent]] lowercaseString];

			BOOL success = useRemoteBaseURL ? [NSImage scaleAndSaveJPEGThumbnailFromFile:[cssImageInfo path] toPath:thumbPath boundingBox:NSMakeSize(300.0, 225.0) rotation:[cssImageInfo orientationDegrees]] :
											  [NSImage scaleAndSaveJPEGThumbnailFromFile:[cssImageInfo path] toPath:thumbPath boundingBox:NSMakeSize(510.0, 360.0) rotation:[cssImageInfo orientationDegrees]];			
			
			if(!success) NSLog(@"Could not scale and save as jpeg into %@", thumbPath);
		}
		[pool release];
	}
	
	//NSLog(@"-- TIME %f", [[NSDate date] timeIntervalSinceDate:d1]);
	
	NSString *kml = [NSString stringWithFormat:XMLContainer, placemarkString];
	[placemarkString release];
	
	NSError *error = nil;
	[kml writeToFile:kmlFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
	if(error) [[NSAlert alertWithError:error] runModal];
	
	[self performSelectorOnMainThread:@selector(exportFinished) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (NSString *)chooseKMLExportDirectory {
    NSSavePanel *sPanel = [NSSavePanel savePanel];
	
	[sPanel setAccessoryView:kmlSavePanelAccessoryView];
	[sPanel setCanCreateDirectories:YES];
	
	NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];

	int runResult = [sPanel runModalForDirectory:desktopPath file:@"KMLExport"];
	
	return (runResult == NSOKButton) ? [sPanel filename] : nil;
}

- (IBAction)exportKMLToFile:(id)sender {
	if(isExporting) return;

	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isExporting"];

	NSString *thumbsDir = nil;
	
	NSString *dir = [self chooseKMLExportDirectory];
	if(!dir) return;

	BOOL addThumbnails = [[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeThumbsInKMLExport"];

	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:dir attributes:nil];
	if(!success) {
		NSLog(@"Error: can't create dir at path %@", dir);
		//return;
	}
	
	NSString *kmlFilePath = [dir stringByAppendingPathComponent:@"CocoaSlideShow.kml"];

	if(addThumbnails) {
		thumbsDir = [dir stringByAppendingPathComponent:@"images"];
		success = [[NSFileManager defaultManager] createDirectoryAtPath:thumbsDir attributes:nil];
		if(!success) {
			NSLog(@"Error: can't create dir at path %@", thumbsDir);
			//return;
		}
	}
	
	NSArray *kmlImages = [[[imagesController selectedObjects] copy] autorelease];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:kmlImages, @"images", kmlFilePath, @"kmlFilePath", [NSNumber numberWithBool:addThumbnails], @"addThumbnails", nil];
		
	if(addThumbnails) {
		[self prepareProgressIndicator:[kmlImages count]];
	}
	
	[NSThread detachNewThreadSelector:@selector(generateKMLWithThumbsDirInSeparateThread:) toTarget:self withObject:options];
}

#pragma mark thumbnails export

- (void)resizeJPEGsOnSeparateThread:(NSDictionary *)options {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
	NSArray *theImages = [options objectForKey:@"Images"];
	NSString *exportDir = [options objectForKey:@"ExportDir"];
	NSNumber *width = [options objectForKey:@"Width"];
	NSNumber *height = [options objectForKey:@"Height"];
	NSSize bbox = NSMakeSize([width floatValue], [height floatValue]);
	
	CSSImageInfo *imageInfo = nil;
	NSEnumerator *e = [theImages objectEnumerator];
	unsigned int count = 0;
	while((imageInfo = [e nextObject])) {
		count++;
		if(![imageInfo isJpeg]) continue;
		NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
		
		[self performSelectorOnMainThread:@selector(updateExportProgress:) withObject:[NSNumber numberWithInt:count] waitUntilDone:NO];
		NSString *thumbPath = [[exportDir stringByAppendingPathComponent:[[imageInfo path] lastPathComponent]] lowercaseString];
		BOOL success = [NSImage scaleAndSaveJPEGThumbnailFromFile:[imageInfo path] toPath:thumbPath boundingBox:bbox rotation:[imageInfo orientationDegrees]];
		if(!success) NSLog(@"Could not scale and save as jpeg into %@", thumbPath);

		[subPool release];
	}

	[self performSelectorOnMainThread:@selector(exportFinished) withObject:nil waitUntilDone:NO];

	[pool release];
}

- (NSString *)chooseThumbsExportDirectory {

    NSSavePanel *sPanel = [NSSavePanel savePanel];
	
	[sPanel setAccessoryView:thumbnailsExportAccessoryView];
	[sPanel setCanCreateDirectories:YES];
	
	NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];

	int runResult = [sPanel runModalForDirectory:desktopPath file:@"ResizedImages"];
	
	return (runResult == NSOKButton) ? [sPanel filename] : nil;
}

- (IBAction)resizeJPEGs:(id)sender {
	if(isExporting) return;
	
	NSString *exportDir = [self chooseThumbsExportDirectory];
	if(!exportDir) return;
	
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:exportDir attributes:nil];
	if(!success) NSLog(@"Error: can't create dir at path %@", exportDir);
	//return;
	
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isExporting"];
	
	NSArray *theImages = [[[imagesController selectedObjects] copy] autorelease];

	[self prepareProgressIndicator:[theImages count]];
	
	int tag = [[NSUserDefaults standardUserDefaults] integerForKey:kThumbsExportSizeTag];
	
	int w = 0;
	int h = 0;
	
	if(tag == 0) {
		w = 300; h = 255;
	} else if (tag == 1) {
		w = 640; h = 480;		
	} else if (tag == 2) {
		w = 800; h = 600;
	} else if (tag == 3) {
		w = [[[NSUserDefaults standardUserDefaults] stringForKey:kThumbsExportSizeWidth] intValue];
		h = [[[NSUserDefaults standardUserDefaults] stringForKey:kThumbsExportSizeHeight] intValue];	
	}

	NSNumber *width = [NSNumber numberWithInt:w];
	NSNumber *height = [NSNumber numberWithInt:h];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:exportDir, @"ExportDir", theImages, @"Images", width, @"Width", height, @"Height", nil];
	[NSThread detachNewThreadSelector:@selector(resizeJPEGsOnSeparateThread:) toTarget:self withObject:options];
}

@end
