#import "CocoaSlideShow.h"
#import "AppleRemote.h"

#import "NSFileManager+CSS.h"

@implementation CocoaSlideShow

- (id)init {
	self = [super init];
	images = [[NSMutableArray alloc] init];
	isFullScreen = NO;
	return self;
}

- (void)dealloc {
	[images release];
	[remoteControl autorelease];
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

- (void)addFiles:(NSArray *)filePaths {
	NSEnumerator *e = [filePaths objectEnumerator];
	NSString *path;
	NSArray *allowedExtensions = [NSArray arrayWithObjects:@"jpg", @"jpeg", @"tif", @"tiff", @"psd", @"gif", @"png", @"pdf", @"bmp", nil];
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
		
		if(![[imagesController arrangedObjects] containsObject:path]) {
			[imagesController addObject:path];
		}
	}
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
	NSString *defaultDir = [NSString pathWithComponents:[NSArray arrayWithObjects:NSHomeDirectory(), @"Pictures", nil]];
	NSString *defaultValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"ImagesDirectory"];
	if(defaultValue) {
		defaultDir = defaultValue;
	}
	[self setupImagesControllerWithDir:defaultDir recursive:NO];

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

	NSString *sourcePath;
	NSString *destPath;
	NSEnumerator *e = [[imagesController arrangedObjects] objectEnumerator];
	NSFileManager *fm = [NSFileManager defaultManager];
	while(( sourcePath = [e nextObject] )) {
		destPath = [destDirectory stringByAppendingPathComponent:[sourcePath lastPathComponent]];
		if ([fm fileExistsAtPath:sourcePath]) {
			[fm copyPath:sourcePath toPath:destPath handler:nil];
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
	
	isFullScreen = YES;
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
	
	isFullScreen = NO;
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
	int index = [imagesController selectionIndex];
	if(index == 0) {
		//NSLog(@"-- can't select index below 0");
		return;
	}
	[imagesController setSelectionIndex:index - 1];
}

- (void)selectNextImage {
	int index = [imagesController selectionIndex];
	if(index == [[imagesController arrangedObjects] count] - 1) {
		//NSLog(@"-- can't select index beyond bounds");
		return;
	}
	[imagesController setSelectionIndex:index + 1];
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
		[self addFiles:files];
    }
    return YES;
}













@end
