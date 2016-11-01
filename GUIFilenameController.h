//
//  GUIFilenameController.h
//
//  Created by Laurent on 27/04/2012
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>

#import "LFTextFormatter.h"

@interface GUIFilenameController : NSWindowController {

	@protected

	IBOutlet NSBox				*bxGroup;
	IBOutlet NSTextField		*tfFilename;
	IBOutlet NSTextField		*tfExtension;
	
	NSString					*windowTitle;
	NSString					*name;
	NSString					*extension;
	
	LFTextFormatter				*textFormatter8;
    LFTextFormatter				*textFormatter3;

}

-(id)				init;
-(id) 				initWithTitle:(NSString *)title;
-(void)				setName:(NSString *)text;
-(void)				setExtension:(NSString *)text;

-(bool)				showUI:(NSString **)newName withExtension:(NSString **)newExtension;

-(IBAction) 		validButton:(id)sender;
-(IBAction) 		cancelButton:(id)sender;

@end
