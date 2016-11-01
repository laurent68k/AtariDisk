//
//  GUIFormatController.m
//
//  Created by Laurent on 04/04/2012
//	Updated on: 
//
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#include <stdlib.h>


#import "GUIFormatController.h"
#import	"Constants.h"

@implementation GUIFormatController

-(id) init {
	
	self = [super init];
	if( self != nil ) {
		
		self->textFormatter8 = [[LFTextFormatter alloc] initWithlenght:8];
		self->textFormatter3 = [[LFTextFormatter alloc] initWithlenght:3];
	}
	
	return self;
}
//---------------------------------------------------------------------------
-(void) dealloc {
			
	[self->textFormatter8 release];
	[self->textFormatter3 release];
	
    [super dealloc];
}
//---------------------------------------------------------------------------
- (void)awakeFromNib {
	
	[[self window] setTitle: NEW_WINDOW__TITLE];
	[self->tfDiskName setFormatter: self->textFormatter8];
    [self->tfDiskExtension setFormatter: self->textFormatter3];
}
//---------------------------------------------------------------------------
- (void)windowWillClose:(NSNotification *)note {
	
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

-(IBAction) validButton:(id)sender {

	if( [[self->tfDiskName stringValue] length] <= SZ_FILENAME ) {
		[NSApp stopModalWithCode:NSOKButton];
	}
	else {
		NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"The volume name must not be greater than 8", @"OK", NULL, NULL);		
	}
	
}
//---------------------------------------------------------------------------
-(IBAction) cancelButton:(id)sender {

	[NSApp stopModalWithCode:NSCancelButton];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

- (void) blankDisk {
	
	STFloppySize	size = kDoubleSide;
	
	if( [self->rbSizeDisk selectedRow] == 0 ) {
		
		size = ( [self->rbSizeDisk selectedColumn] == 0 ? kSingleSide : size);
		size = ( [self->rbSizeDisk selectedColumn] == 1 ? kDoubleSide : size);
		size = ( [self->rbSizeDisk selectedColumn] == 2 ? kHighDensity : size);
		size = ( [self->rbSizeDisk selectedColumn] == 3 ? kExtendDensity : size);
	}
	
	// Create a SavePanel
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	// Set its allowed file types
	NSArray* allowedFileTypes = [NSArray arrayWithObjects: @"st", nil];
	[savePanel setAllowedFileTypes:allowedFileTypes];
	
	// Get the default images directory
	NSString* defaultDir = [NSString stringWithCString:"." encoding:NSASCIIStringEncoding];
	
	// Run the SavePanel, then check if the user clicked OK
    if ( NSOKButton == [savePanel runModalForDirectory:defaultDir file:nil] ) {
		
		bool result = [STFloppyManager createSTImage:[savePanel filename] withSize:size withName:[self->tfDiskName stringValue] withExtension:[self->tfDiskExtension stringValue]];		
		if (result ) {
			NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat: @"Disk image '%@' created", [savePanel filename]], @"OK", NULL, NULL);
		}
		else {
			NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat: @"Failed while creating new disk '%@'", [savePanel filename]], @"OK", NULL, NULL);	
		}
		
	}
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

- (void) showUI {
	
    // load the nib
    if (NULL == [self window]) {
	
        [NSBundle loadNibNamed: @"DiskFormat" owner: self];
    }
	
	//	It's magic ! We get a nice effect while opening the modal sheet
	[NSApp beginSheet:[self window] modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
			
	NSInteger retour = [NSApp runModalForWindow: [self window]];	 //This call blocks the execution until [NSApp stopModal] is called
	
	if( NSOKButton == retour ) {
	
		[self blankDisk];
	}
	//	Do the nice effect while closing
	[NSApp endSheet: [self window]];
	[[self window] orderOut: nil];	
}
//---------------------------------------------------------------------------

@end
