//
//  BrowserCell.h
//
//  Created by Laurent on 02/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import <Cocoa/Cocoa.h>

#import "Node.h"

@interface BrowserCell : NSBrowserCell { 

	@private

		NSImage			*iconImage;
		Node			*nodeInfo;
		BOOL			drawsBackground;
}

- (void)setNode:(Node *)value;
- (Node *)node;

- (void)setIconImage:(NSImage *)image;
- (NSImage *)iconImage;

- (void)loadCellContents;

@end