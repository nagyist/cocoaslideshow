#import "MyWindow.h"
#import "CocoaSlideShow.h"

@implementation MyWindow

-(void) setDelegate: (id) del {
    delegate = del;
}

- (id) delegate {
    return (delegate);
}

- (void)keyDown:(NSEvent *)theEvent {
	if([theEvent keyCode] == 53) { // escape key
		[(CocoaSlideShow *)[self delegate] exitFullScreen:self];
	} else {
		[super keyDown:theEvent];
	}
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return [delegate draggingEntered:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return [delegate prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return [delegate performDragOperation:sender];
}

@end
