#import "MyImageView.h"

@implementation MyImageView

-(void) setDelegate: (id) del {
    delegate = del;
}

- (id) delegate {
    return (delegate);
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if ([delegate respondsToSelector: @selector(draggingEntered:)]) {
		return [delegate draggingEntered:sender];
	}
	return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	if ([delegate respondsToSelector: @selector(prepareForDragOperation:)]) {
		return [delegate prepareForDragOperation:sender];
	}
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	if ([delegate respondsToSelector: @selector(performDragOperation:)]) {
		return [delegate performDragOperation:sender];
	}
	return NO;
}

@end
