//
//  NodeFile.h
//
//  Created by Laurent on 02/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>
#import "Node.h"
#import "STFloppy.h"


@interface NodeDirectory : Node {

	@protected

		STFloppy 			*floppyDisk;
		STDirectoryEntry	directoryEntry;
		UInt32				countClustersUsed;
		
		NSString			*extension;
		NSDate				*dateTime;		
}

@property(nonatomic,retain,readwrite)	NSString *extension;

@property(nonatomic,retain,readwrite)	NSDate *dateTime;
@property(nonatomic,readwrite)			UInt32 countClustersUsed;
@property(nonatomic,readonly)			STDirectoryEntry directoryEntry;

-(void)				assignIconImage;

-(bool)				isReadOnly;
-(bool)				isHidden;
-(bool)				isSystem;
-(bool)				isVolumeLabel;
-(bool)				isDirectory;
-(bool)				isModified;
-(UInt32)			sizeOfFile;
-(NSString *) 		dateOfFileAsString;

-(id)				initWithParent:(Node *)parent rawEntry:(STDirectoryEntry *)aDirectoryEntry fromDisk:(STFloppy *)disk;

@end
