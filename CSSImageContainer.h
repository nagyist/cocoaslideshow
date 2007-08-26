//
//  CSSImageContainer.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 25.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSSBitmapImageRep.h"

@interface CSSImageContainer : NSObject {
	NSString *path;
	CSSBitmapImageRep *bitmap;
}

- (NSString *)path;

@end
