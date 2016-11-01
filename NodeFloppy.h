//
//  Node.h
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>
#import "STFloppyManager.h"
#import "Node.h"

@interface NodeFloppy : Node {

	@protected

	STFloppyManager					*floppyDisk;
}

@property(nonatomic,readonly)		STFloppyManager		*floppyDisk;

-(id)				initWithParent:(Node *)parent withName:(NSString *)theName;
-(id)				initWithParent:(Node *)parent withName:(NSString *)theName withImage:(NSImage *)theImage;

-(void)				ejectDisk;

@end
