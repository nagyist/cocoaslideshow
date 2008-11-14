#import "MyWindow.h"
#import "CocoaSlideShow.h"

@implementation MyWindow

- (BOOL)preservesContentDuringLiveResize {
	return NO;
}

- (void)keyDown:(NSEvent *)theEvent {
	CocoaSlideShow *css = [self delegate];
	
	//NSLog(@"-- %d", [theEvent keyCode]);
	
	switch([theEvent keyCode]) {
		case 49: // space
			[css toggleSlideShow:self];
			break;
		case 53: // esc
			[css exitFullScreen:self];
			break;
		case 123: // left
			[imagesController selectPreviousImage];
			break;
		case 124: // right
			[imagesController selectNextImage];
			break;
		default:
			[[self nextResponder] keyDown:theEvent];
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"-- mouseDown");
	[[self nextResponder] mouseDown:theEvent];
}
/*
- (void)mouseUp:(NSEvent *)theEvent {
	//NSLog(@"-- mouseUp");
	CocoaSlideShow *css = [self delegate];
	if([css mapNeedsResizing]) {
		[css displayGoogleMapForSelection:self];
	}
	[[self nextResponder] mouseUp:theEvent];
}
*/
@end
