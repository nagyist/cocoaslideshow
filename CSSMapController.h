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

extern NSString *const G_NORMAL_MAP;

@interface CSSMapController : NSObject {
	IBOutlet WebView *webView;
	IBOutlet ImagesController *imagesController;
}

- (void)clearMap;

- (NSArray *)mapStyles;

- (IBAction)displayGoogleMapForSelection:(id)sender;

@end
