//
//  GUIFilenameController.m
//
//  Created by Laurent on 27/04/2012
//	Updated on: 
//
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#include <stdlib.h>

#import "STFloppyManager.h"
#import "GUIFilenameController.h"
#import	"Constants.h"

@implementation GUIFilenameController

-(id) init {
	
	self = [super init];
	if( self != nil ) {
		
		self->textFormatter8 = [[LFTextFormatter alloc] initWithlenght:8];
		self->textFormatter3 = [[LFTextFormatter alloc] initWithlenght:3];	
	}
	
	return self;
}
//---------------------------------------------------------------------------
-(id) initWithTitle:(NSString *)title {
	
	self = [super init];
	if( self != nil ) {

		self->windowTitle = title;
		[self->windowTitle retain];
		
		self->name = nil;
		self->extension = nil;

        self->textFormatter8 = [[LFTextFormatter alloc] initWithlenght:8];
		self->textFormatter3 = [[LFTextFormatter alloc] initWithlenght:3];	
}
	
	return self;
}
//---------------------------------------------------------------------------
-(void) dealloc {
			
	[self->windowTitle release];

	[self->textFormatter8 release];
	[self->textFormatter3 release];
	
	if( self->name != nil ) {
		[self->name release];
	}
	if( self->extension != nil ) {
		[self->extension release];
	}	
	
    [super dealloc];
}
//---------------------------------------------------------------------------
- (void)awakeFromNib {
	
	[[self window] setTitle: self->windowTitle];
    
	[self->tfFilename setFormatter: self->textFormatter8];
	[self->tfExtension setFormatter: self->textFormatter3];
}
//---------------------------------------------------------------------------
- (void)windowWillClose:(NSNotification *)note {
	
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

-(IBAction) validButton:(id)sender {

	if( [[self->tfFilename stringValue] length] > 0 && [[self->tfFilename stringValue] length] <= SZ_FILENAME ) {;
		[NSApp stopModalWithCode:NSOKButton];
	}
	else {
		NSRunInformationalAlertPanel(self->windowTitle, @"The file name can not be empty or greater than 8", @"OK", NULL, NULL);		
	}
	
	if( [[self->tfExtension stringValue] length] <= SZ_EXTENSION ) {;
		[NSApp stopModalWithCode:NSOKButton];
	}
	else {
		NSRunInformationalAlertPanel(self->windowTitle, @"The file extension can not be greater than 3", @"OK", NULL, NULL);		
	}
}
//---------------------------------------------------------------------------
-(IBAction) cancelButton:(id)sender {

	[NSApp stopModalWithCode:NSCancelButton];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

-(void)	setName:(NSString *)text {
	
	self->name = text;
	[self->name retain];
}
//---------------------------------------------------------------------------
-(void)	setExtension:(NSString *)text {

	self->extension = text;
	[self->extension retain];
}
//---------------------------------------------------------------------------
-(bool) showUI:(NSString **)newName withExtension:(NSString **)newExtension {
	
    // load the nib
    if (NULL == [self window]) {
	
        [NSBundle loadNibNamed: @"Filename" owner: self];
    }
	
	if( self->name != nil ) {
		[self->tfFilename setStringValue:self->name];
	}
	if( self->extension != nil ) {
		[self->tfExtension setStringValue:self->extension];
	}	
	
	[self->bxGroup setTitle:self->windowTitle];
	
	//	It's magic ! We get a nice effect while opening the modal sheet
	[NSApp beginSheet:[self window] modalForWindow:[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
			
	NSInteger retour = [NSApp runModalForWindow: [self window]];	 //This call blocks the execution until [NSApp stopModal] is called
		
	if( NSOKButton == retour ) {
	
		*newName = [NSString stringWithFormat:@"%@", [self->tfFilename stringValue]];
		*newExtension = [NSString stringWithFormat:@"%@", [self->tfExtension stringValue]];
		
		NSLog(@"filename=%@ extension=%@", *newName, *newExtension);
	}
	
	//	Do the nice effect while closing
	[NSApp endSheet: [self window]];
	[[self window] orderOut: nil];
	
	return ( NSOKButton == retour );
}
//---------------------------------------------------------------------------

@end
