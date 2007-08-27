#import "CocoaSlideShow.h"
#import "AppleRemote.h"

#import "NSFileManager+CSS.h"
#import "VersionChecker.h"
#import "CSSBitmapImageRep.h"
#import "CSSImageContainer.h"

#define IN_MEMORY_BITMAPS 10

@implementation CocoaSlideShow

- (id)init {
	self = [super init];
	images = [[NSMutableArray alloc] init];
	inMemoryBitmapsPaths = [[NSMutableArray alloc] initWithCapacity:IN_MEMORY_BITMAPS];
	isFullScreen = NO;
	takeFilesFromDefault = YES;
	return self;
}

- (void)dealloc {
	[images release];
	[remoteControl autorelease];
	[inMemoryBitmapsPaths release];
	[super dealloc];
}

- (NSImage *)rotateIndividualImage:(NSImage *)image clockwise:(BOOL)clockwise {
	// from http://swik.net/User:marc/Chipmunk+Ninja+Technical+Articles/Rotating+an+NSImage+object+in+Cocoa/zgha
    
	NSImage *existingImage = image;
    NSSize existingSize;

    /**
     * Get the size of the original image in its raw bitmap format.
     * The bestRepresentationForDevice: nil tells the NSImage to just
     * give us the raw image instead of it's wacky DPI-translated version.
     */
    existingSize.width = [[existingImage bestRepresentationForDevice: nil] pixelsWide];
    existingSize.height = [[existingImage bestRepresentationForDevice: nil] pixelsHigh];

    NSSize newSize = NSMakeSize(existingSize.height, existingSize.width);
    NSImage *rotatedImage = [[NSImage alloc] initWithSize:newSize];

    [rotatedImage lockFocus];

    /**
     * Apply the following transformations:
     *
     * - bring the rotation point to the centre of the image instead of
     *   the default lower, left corner (0,0).
     * - rotate it by 90 degrees, either clock or counter clockwise.
     * - re-translate the rotated image back down to the lower left corner
     *   so that it appears in the right place.
     */
    NSAffineTransform *rotateTF = [NSAffineTransform transform];
    NSPoint centerPoint = NSMakePoint(newSize.width / 2, newSize.height / 2);

    [rotateTF translateXBy: centerPoint.x yBy: centerPoint.y];
    [rotateTF rotateByDegrees: (clockwise) ? - 90 : 90];
    [rotateTF translateXBy: -centerPoint.y yBy: -centerPoint.x];
    [rotateTF concat];

    /**
     * We have to get the image representation to do its drawing directly,
     * because otherwise the stupid NSImage DPI thingie bites us in the butt
     * again.
     */
    NSRect r1 = NSMakeRect(0, 0, newSize.height, newSize.width);
    [[existingImage bestRepresentationForDevice: nil] drawInRect: r1];

    [rotatedImage unlockFocus];

    return [rotatedImage autorelease];
}

- (BOOL)imagesControllerContainsPath:(NSString *)path {

	NSEnumerator *e = [images objectEnumerator];
	CSSImageContainer *container;
	while(( container = [e nextObject] )) {
		if([[container path] isEqualToString:path]) {
			return YES;
		}
	}
	return NO;
}	


- (void)addFiles:(NSArray *)filePaths {

	importDone = NO;

	NSEnumerator *e = [filePaths objectEnumerator];
	NSString *path;
	NSArray *allowedExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"tif", @"tiff", @"psd", @"gif", @"png", @"bmp", nil];
	NSArray *dirContent;
	while(( path = [e nextObject] )) {
		NSString *ext = [path pathExtension];
		
		dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:path recursive:YES];
		if(dirContent) {
			[self addFiles:dirContent];
		}
		
		if([path hasPrefix:@"."] || ![allowedExtensions containsObject:[ext lowercaseString]]) {
			continue;
		}
		
		if(![self imagesControllerContainsPath:path]) {
			CSSImageContainer *container = [[CSSImageContainer alloc] init];
			[container setValue:path forKey:@"path"];
			[imagesController addObject:[container autorelease]];
		}
	}

	importDone = YES;
}

- (void)addDirFiles:(NSString *)dir {
	[self addFiles:[NSArray arrayWithObject:dir]];
}

- (void)setupImagesControllerWithDir:(NSString *)dir recursive:(BOOL)isRecursive {
	[images removeAllObjects];

	NSArray *dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:dir recursive:isRecursive];
	[self addFiles:dirContent];

	[imagesController setSelectionIndex:0];
}

- (void)awakeFromNib {
	remoteControl = [[[AppleRemote alloc] initWithDelegate: self] retain];
	
	[mainWindow registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	
	[imageView setDelegate:self];
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
		[[NSUserDefaults standardUserDefaults] setValue:dir forKey:@"ImagesDirectory"];
	}
}

- (IBAction)addDirectory:(id)sender {
	NSString *dir = [self chooseDirectory];
	if(dir) {
		[self addDirFiles:dir];
	}
}

- (IBAction)exportToDirectory:(id)sender {
	NSString *destDirectory = [self chooseDirectory];
	if(!destDirectory) {
		return;
	}

	CSSImageContainer *container;
	NSString *destPath;
	NSEnumerator *e = [[imagesController selectedObjects] objectEnumerator];
	NSFileManager *fm = [NSFileManager defaultManager];
	while(( container = [e nextObject] )) {
		destPath = [destDirectory stringByAppendingPathComponent:[[container path] lastPathComponent]];
		if ([fm fileExistsAtPath:[container path]]) {
			[fm copyPath:[container path] toPath:destPath handler:nil];
		}
	}
}

- (void)rotate:(NSImageView *)iv clockwise:(BOOL)cw {
	[iv setImage:[self rotateIndividualImage:[iv image] clockwise:cw]];
}

- (IBAction)rotateLeft:(id)sender {
	NSImageView *iv = isFullScreen ? panelImageView : imageView;
	[self rotate:iv clockwise:NO];
}

- (IBAction)rotateRight:(id)sender {
	NSImageView *iv = isFullScreen ? panelImageView : imageView;
	[self rotate:iv clockwise:YES];
}

- (IBAction)moveToTrash:(id)sender {
	NSArray *selectedObjects = [imagesController selectedObjects];
	NSString *imagePath;
	NSEnumerator *e = [selectedObjects objectEnumerator];
	NSString *trashPath;
	
	[imagesController removeObjectsAtArrangedObjectIndexes:[imagesController selectionIndexes]];

	while( imagePath = [e nextObject] ) {
		trashPath = [@"~/.Trash/" stringByAppendingPathComponent:[imagePath lastPathComponent]];
		[[NSFileManager defaultManager] movePath:imagePath toPath:trashPath handler:nil];
	}
}

- (IBAction)fullScreenMode:(id)sender {
	// from http://cocoadevcentral.com/articles/000028.php
	
	if(isFullScreen) {
		return;
	}

	[mainWindow makeFirstResponder:tableView];
	//return;

	[NSCursor hide];
	//[NSCursor setHiddenUntilMouseMoves:YES];
		
    int windowLevel;
    NSRect screenRect;

    // Capture the main display
    if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
        NSLog( @"Couldn't capture the main display!" );
        // Note: you'll probably want to display a proper error dialog here
    }

    // Get the shielding window level
    windowLevel = CGShieldingWindowLevel();
		
    // Get the screen rect of our main display
    screenRect = [[NSScreen mainScreen] frame];

    // Put up a new window
    mainWindow = [[NSWindow alloc] initWithContentRect:screenRect
											 styleMask:NSBorderlessWindowMask
											   backing:NSBackingStoreBuffered
                                                 defer:NO screen:[NSScreen mainScreen]];

    [mainWindow setLevel:windowLevel];

    [mainWindow setBackgroundColor:[NSColor blackColor]];
    [mainWindow makeKeyAndOrderFront:nil];
	
    // Load our content view
    [slideShowPanel setFrame:screenRect display:YES];
	
    [mainWindow setContentView:[slideShowPanel contentView]];
	
	[self willChangeValueForKey:@"isFullScreen"];
	isFullScreen = YES;
	[self didChangeValueForKey:@"isFullScreen"];
}

- (IBAction)exitFullScreen:(id)sender {
	if(!isFullScreen) {
		return;
	}
	
	[NSCursor unhide];
	
	[mainWindow orderOut:self];
	// Release the display(s)
	if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
		NSLog( @"Couldn't release the display(s)!" );
		// Note: if you display an error dialog here, make sure you set
		// its window level to the same one as the shield window level,
		// or the user won't see anything.
	}
	
	[self willChangeValueForKey:@"isFullScreen"];
	isFullScreen = NO;
	[self didChangeValueForKey:@"isFullScreen"];
}

- (IBAction)toggleFullScreen:(id)sender {
	if(isFullScreen) {
		[self exitFullScreen:nil];
	} else {
		[self fullScreenMode:nil];	
	}
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self exitFullScreen:self];
}

- (void)selectPreviousImage {
	if([imagesController canSelectPrevious]) {
		[imagesController selectPrevious:self];
	}
}

- (void)selectNextImage {
	if([imagesController canSelectNext]) {
		[imagesController selectNext:self];
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
			if (pressedDown) pressed = @"(down)"; else pressed = @"(up)";
			break;
		case kRemoteButtonMinus:
			buttonName = @"Volume down";
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
			[self rotateRight:self];
			break;			
		case kRemoteButtonRight:	
			buttonName = @"Right";
			[self selectNextImage];
			break;			
		case kRemoteButtonLeft:
			buttonName = @"Left";
			[self selectPreviousImage];
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
		NSString *defaultValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"ImagesDirectory"];
		if(defaultValue) {
			defaultDir = defaultValue;
		}
		[self setupImagesControllerWithDir:defaultDir recursive:NO];
	}
	
    [[VersionChecker sharedInstance] checkUpdate:self];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	if([filenames count] > 0) {
		int numberOfImagesBefore = [[imagesController arrangedObjects] count];
		[self addFiles:filenames];
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

#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return NSDragOperationLink;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
 
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
		int numberOfImagesBefore = [[imagesController arrangedObjects] count];
		[self addFiles:files];
		int numberOfImagesAfter = [[imagesController arrangedObjects] count];
		if(numberOfImagesAfter > numberOfImagesBefore) {
			[imagesController setSelectionIndex:numberOfImagesBefore];
		}		
    }
    return YES;
}

- (IBAction)revealInFinder:(id)sender {
	NSArray *selectedObjects = [imagesController selectedObjects];
	NSString *imagePath;
	NSEnumerator *e = [selectedObjects objectEnumerator];
	NSString *topFolderPath;
	
	while( imagePath = [[e nextObject] path] ) {
		topFolderPath = [imagePath stringByDeletingLastPathComponent];
		[[NSWorkspace sharedWorkspace] openFile:topFolderPath];
	}
}

- (BOOL)multipleImagesSelected {
	return [[imagesController selectedObjects] count] > 1;
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	isSaving = YES;
	return YES;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
	isSaving = NO;
}

- (void) retainOnlyAFewImagesAndReleaseTheRest {
	if([[imagesController selectedObjects] count] != 1) {
		return;
	}
	
	CSSImageContainer *c = [[imagesController selectedObjects] lastObject];
	
	if(![inMemoryBitmapsPaths containsObject:c]) {
		if([inMemoryBitmapsPaths count] == IN_MEMORY_BITMAPS) {
			CSSImageContainer *oldContainer = [inMemoryBitmapsPaths objectAtIndex:0];
			[oldContainer forgetBitmap];
			[inMemoryBitmapsPaths removeObject:oldContainer];
		}
		[inMemoryBitmapsPaths addObject:c];	
	}
}

#pragma mark NSTableView delegate

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self retainOnlyAFewImagesAndReleaseTheRest];
}

@end
