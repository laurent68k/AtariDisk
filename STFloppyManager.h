//
//  STFloppyManager.h
//
//  Created by Laurent on 02/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>
#import "NodeFile.h"
#import "STFloppy.h"

@interface STFloppyManager : STFloppy {

	@protected

		id				delegate;
		NSString		*filenameDisk;


}

@property(nonatomic,readonly)	NSString		*filenameDisk;

-(id)				initWithDelegate:(id)theDelegate;

+(bool)				createSTImage:(NSString *)filename withSize:(STFloppySize)size withName:(NSString *)diskName withExtension:(NSString *)diskExtension;
-(bool)				readSTImage:(NSString *)filename withRoot:(Node *) nodeRoot;
-(bool)				writeSTImageAs:(NSString *)filename;
-(bool)				writeSTImage;

-(STFloppyError)	extractFileSTImage:(NodeFile *)node withName:(NSString *)filename;
-(STFloppyError)	addFileSTImage:(Node *)parentNode atPath:(NSString *)filename withRoot:(Node *) nodeRoot;
-(STFloppyError)	addFolderSTImage:(Node *)parentNode withName:(NSString *)name withExtension:(NSString *)extension withRoot:(Node *)nodeRoot;
-(STFloppyError) 	removeFileSTImage:(NodeDirectory *)nodeFile withRoot:(Node *)nodeRoot;
-(STFloppyError)	renameFileSTImage:(NodeFile *)node withName:name withExtension:extension;

-(void)				ejectSTDisk;

@end
