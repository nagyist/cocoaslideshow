//
//  MapController.h
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 14.11.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class ImagesController;

@interface CSSMapController : NSObject {
	IBOutlet WebView *webView;
	IBOutlet ImagesController *imagesController;
}

- (IBAction)displayGoogleMapForSelection:(id)sender;
- (void)clearMap;

@end