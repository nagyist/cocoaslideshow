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

@end
