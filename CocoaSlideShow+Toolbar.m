//
//  CocoaSlideShow+Toolbar.m
//  CocoaSlideShow
//
//  Created by Nicolas Seriot on 04.05.08.
//  Copyright 2008 Sen:te. All rights reserved.
//

#import "CocoaSlideShow+Toolbar.h"


@implementation CocoaSlideShow (Toolbar)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	if ([itemIdentifier isEqualToString:@"setDirectory"]) {
        [item setLabel:NSLocalizedString(@"Set Directory…", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Set Directory…", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Set Directory…", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"folder"]];
        [item setTarget:self];
        [item setAction:@selector(setDirectory:)];
	} else if ([itemIdentifier isEqualToString:@"addFiles"]) {
        [item setLabel:NSLocalizedString(@"Add Files…", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Add Files…", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Add Files…", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"add"]];
        [item setTarget:self];
        [item setAction:@selector(addDirectory:)];
	} else if ([itemIdentifier isEqualToString:@"flag"]) {
        [item setLabel:NSLocalizedString(@"Flag", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Flag", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Flag", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"flag"]];
        [item setTarget:imagesController];
        [item setAction:@selector(toggleFlags:)];
	} else if ([itemIdentifier isEqualToString:@"fullScreen"]) {
        [item setLabel:NSLocalizedString(@"Full Screen", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Full Screen", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Full Screen", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"full_screen"]];
        [item setTarget:self];
		[item setAction:@selector(fullScreenMode:)];
	} else if ([itemIdentifier isEqualToString:@"slideShow"]) {
        [item setLabel:NSLocalizedString(@"Slideshow", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Slideshow", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Slideshow", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"slideshow"]];
        [item setTarget:self];
		[item setAction:@selector(startSlideShow:)];
	} else if ([itemIdentifier isEqualToString:@"rotateLeft"]) {
        [item setLabel:NSLocalizedString(@"Rotate Left", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Rotate Left", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Rotate Left", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"left"]];
        [item setTarget:self];
		[item setAction:@selector(rotateLeft:)];
	} else if ([itemIdentifier isEqualToString:@"rotateRight"]) {
        [item setLabel:NSLocalizedString(@"Rotate Right", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Rotate Right", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Rotate Right", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"right"]];
        [item setTarget:self];
		[item setAction:@selector(rotateRight:)];
	} else if ([itemIdentifier isEqualToString:@"remove"]) {
        [item setLabel:NSLocalizedString(@"Remove", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Remove", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Remove", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"remove"]];
        [item setTarget:imagesController];
		[item setAction:@selector(remove:)];
	} else if ([itemIdentifier isEqualToString:@"trash"]) {
        [item setLabel:NSLocalizedString(@"Trash", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Trash", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Trash", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:@"trash"]];
        [item setTarget:imagesController];
		[item setAction:@selector(moveToTrash:)];
    }
	
    return [item autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:@"setDirectory", @"addFiles",
			NSToolbarSeparatorItemIdentifier, @"flag", @"fullScreen", @"slideShow", @"rotateLeft", @"rotateRight", @"remove",
			NSToolbarFlexibleSpaceItemIdentifier, @"trash", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    NSArray *standardItems = [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
							  NSToolbarSpaceItemIdentifier,
							  NSToolbarFlexibleSpaceItemIdentifier,
							  NSToolbarCustomizeToolbarItemIdentifier, nil];
	NSArray *moreItems = [NSArray array];
	return [[[self toolbarDefaultItemIdentifiers:nil] arrayByAddingObjectsFromArray:standardItems] arrayByAddingObjectsFromArray:moreItems];
}

- (void)toolbaritemclicked:(NSToolbarItem*)item {
    //NSLog(@"-- toolbaritemclicked %@", [item label]);
    
    NSString *identifier = [item itemIdentifier];
    if([identifier isEqualToString:@"informations"]) {
        //[self toggleEdition];
    } else if ([identifier isEqualToString:@"quickLook"]) {
        //[self openQuickLook:nil];
    }    
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    
	NSString *identifier = [theItem itemIdentifier];
    if ([identifier isEqualToString:@"informations"]) {
		return YES;//[[activeTracksController arrangedObjects] count] > 0;
    } else if ([identifier isEqualToString:@"quickLook"]) {
		return NO;//quickLookAvailable && [[selectedResultsController selectedObjects] count] > 0;
	}
    
    return YES;
}

@end