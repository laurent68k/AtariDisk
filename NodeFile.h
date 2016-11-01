//
//  NodeFile.h
//
//  Created by Laurent on 02/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>
#import "NodeDirectory.h"
#import "STFloppy.h"

@interface NodeFile : NodeDirectory {

	@protected
		
}

-(id)				initWithParent:(Node *)parent withName:(NSString *)theName;
-(id)				initWithParent:(Node *)parent rawEntry:(STDirectoryEntry *)aDirectoryEntry fromDisk:(STFloppy *)disk;

@end
