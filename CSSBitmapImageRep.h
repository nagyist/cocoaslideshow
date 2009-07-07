#import <Cocoa/Cocoa.h>

@class CSSImageContainer;

@interface CSSBitmapImageRep:NSBitmapImageRep {
	NSString *path;
	NSURL *url;
	CGImageSourceRef source;
	NSMutableDictionary *metadata;
	
	CSSImageContainer *container; // weak ref
}

- (void)setContainer:(CSSImageContainer *)aContainer;

- (NSString *)path;

- (NSImage *)image;

- (void)setPath:(NSString *)aPath;
- (NSDictionary *)exif;
- (NSDictionary *)gps;

- (NSString *)exifDateTime;

- (NSString *)prettyLatitude;
- (NSString *)prettyLongitude;

- (void)setUserComment:(NSString *)comment;
- (NSString *)userComment;

- (void)setKeywords:(NSArray *)keywords;
- (NSArray *)keywords;

- (NSString *)prettyImageSize;

- (NSURL *)googleMapsURL;
//- (NSString *)gmapMarkerWithIndex:(int)i;

@end
