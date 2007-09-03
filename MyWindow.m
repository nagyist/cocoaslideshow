#import "MyWindow.h"
#import "CocoaSlideShow.h"

@implementation MyWindow

-(void) setDelegate: (id) del {
    [super setDelegate:del];
}

- (id) delegate {
    return [super delegate];
}

- (void)keyDown:(NSEvent *)theEvent {
	CocoaSlideShow *css = [self delegate];
	
	switch([theEvent keyCode]) {
		case 53:
			[css exitFullScreen:self];
			break;
		case 123:
			[imagesController selectPreviousImage];
			break;
		case 124:
			[imagesController selectNextImage];
			break;
		default:
			[super keyDown:theEvent];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return [[self delegate] draggingEntered:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return [[self delegate] prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return [[self delegate] performDragOperation:sender];
}

@end
