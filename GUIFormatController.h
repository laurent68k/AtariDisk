//
//  GUIFormatController.h
//
//  Created by Laurent on 04/04/2012
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>

#import "LFTextFormatter.h"
#import "STFloppyManager.h"

@interface GUIFormatController : NSWindowController {

	@protected

	IBOutlet NSMatrix 				*rbSizeDisk;
	IBOutlet NSTextField 			*tfDiskName;
    IBOutlet NSTextField            *tfDiskExtension;
    
	LFTextFormatter					*textFormatter8;
	LFTextFormatter					*textFormatter3;
	STFloppyManager					*floppyST;
	
}

-(id)				init;
-(void) 			showUI;

-(IBAction) validButton:(id)sender;
-(IBAction) cancelButton:(id)sender;

@end
