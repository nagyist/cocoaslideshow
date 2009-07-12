#import "CocoaSlideShow.h"
#import "AppleRemote.h"

#import "NSFileManager+CSS.h"
#import "Updater.h"
#import "CSSBitmapImageRep.h"
#import "CSSImageContainer.h"

@implementation CocoaSlideShow

- (id)init {
	self = [super init];
	images = [[NSMutableArray alloc] init];
	isFullScreen = NO;
	takeFilesFromDefault = YES;
	
	undoManager = [[NSUndoManager alloc] init];
	[undoManager setLevelsOfUndo:10];
	
    ir = [[[ImageResizer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:ir forName:@"ImageResizer"];
	
	return self;
}

- (void)dealloc {
	[mainWindow release];
	[imagesController release];
	[images release];
	[remoteControl autorelease];
	[undoManager release];
	[fullScreenWindow release];
	[super dealloc];
}

- (NSUndoManager *)undoManager {
	return undoManager;
}

- (NSImage *)rotateIndividualImage:(NSImage *)image clockwise:(BOOL)clockwise {
	// from http://swik.net/User:marc/Chipmunk+Ninja+Technical+Articles/Rotating+an+NSImage+object+in+Cocoa/zgha
	// TODO (NST) remember the rotation angle in the same session
    
	NSImage *existingImage = image;
    NSSize existingSize;
		
	/**
     * Get the size of the original image in its raw bitmap format.
     * The bestRepresentationForDevice: nil tells the NSImage to just
     * give us the raw image instead of it's wacky DPI-translated version.
     */
    existingSize.width = [existingImage size].width;//[[existingImage bestRepresentationForDevice: nil] pixelsWide];
    existingSize.height = [existingImage size].height;//[[existingImage bestRepresentationForDevice: nil] pixelsHigh];

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

- (void)setupImagesControllerWithDir:(NSString *)dir recursive:(BOOL)isRecursive {
	[images removeAllObjects];

	NSArray *dirContent = [[NSFileManager defaultManager] directoryContentFullPaths:dir recursive:isRecursive];
	
	dirContent = [dirContent sortedArrayUsingSelector:@selector(numericCompare:)];
	
	[imagesController addFiles:dirContent];
	[imagesController setSelectionIndex:0];
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
	
	[ir setView:panelImageView];
	
	NSTableColumn *flagColumn = [tableView tableColumnWithIdentifier:@"flag"];
	NSImage *flagHeaderImage = [NSImage imageNamed:@"FlaggedHeader.png"];
	NSImageCell *flagHeaderImageCell = [flagColumn headerCell];
	[flagHeaderImageCell setImage:flagHeaderImage];
	[flagColumn setHeaderCell:flagHeaderImageCell];
	
	[imageView setDelegate:self];
	[mainWindow setDelegate:self];

	NSNumber *slideShowSpeed = [[NSUserDefaults standardUserDefaults] valueForKey:@"SlideShowSpeed"];
	if (!slideShowSpeed) {
		[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:1.0] forKey:@"SlideShowSpeed"];
	}

	NSRect screenRect = [[NSScreen mainScreen] frame];	
	[slideShowPanel setContentSize:screenRect.size];
    fullScreenWindow = [[NSWindow alloc] initWithContentRect:screenRect
												 styleMask:NSBorderlessWindowMask
												   backing:NSBackingStoreBuffered
													 defer:NO screen:[NSScreen mainScreen]];
	
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
		[imagesController addDirFiles:dir];
	}
}

- (IBAction)exportToDirectory:(id)sender {
	NSString *destDirectory = [self chooseDirectory];
	if(!destDirectory) {
		return;
	}

	[[imagesController selectedObjects] makeObjectsPerformSelector:@selector(copyToDirectory:) withObject:destDirectory];
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

- (IBAction)fullScreenMode:(id)sender {
	// inspired from http://cocoadevcentral.com/articles/000028.php
	
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
	mainWindow = fullScreenWindow;
	
    [mainWindow setLevel:windowLevel];

    [mainWindow setBackgroundColor:[NSColor blackColor]];
    [mainWindow makeKeyAndOrderFront:nil];
	
    // Load our content view
    [slideShowPanel setFrame:screenRect display:YES];

	[self willChangeValueForKey:@"isFullScreen"];
	isFullScreen = YES;
	[self didChangeValueForKey:@"isFullScreen"];
	
    [mainWindow setContentView:[slideShowPanel contentView]];
}

- (IBAction)undo:(id)sender {
	[undoManager undo];
}

- (IBAction)redo:(id)sender {
	[undoManager redo];
}

- (IBAction)exitFullScreen:(id)sender {
	if(!isFullScreen) {
		return;
	}
	
	if([timer isValid]) {
		[timer invalidate];
		timer = nil;
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

- (void)timerNextTick {
	if(![imagesController canSelectNext]) {
		[timer invalidate];
		timer = nil;
	}
	[imagesController selectNextImage]; 
}

- (IBAction)toggleSlideShow:(id)sender {
	if([timer isValid]) {
		[timer invalidate];
		timer = nil;
	} else {
		timer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] valueForKey:@"SlideShowSpeed"] floatValue]
												  target:self
												selector:@selector(timerNextTick)
												userInfo:NULL
												repeats:YES];
	}
}

- (IBAction)startSlideShow:(id)sender {
	[self fullScreenMode:self];
	[self toggleSlideShow:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self exitFullScreen:self];
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
		NSString *defaultValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"ImagesDirectory"];
		if(defaultValue) {
			defaultDir = defaultValue;
		}
		[self setupImagesControllerWithDir:defaultDir recursive:NO];
	}
	
    [[Updater sharedInstance] checkUpdateSilentIfUpToDate:self];
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
		//NSLog(@"will add files");
		[imagesController addFiles:files];
		//NSLog(@"did add files");
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
	[imagesController retainOnlyAFewImagesAndReleaseTheRest];
}

@end
