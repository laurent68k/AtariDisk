//
//  MainWndController.h
//
//  Created by Laurent on 01/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>
#import "STFloppyManager.h"

#import "Node.h"
#import "NodeFloppy.h"



@interface MainWndController : NSWindowController {

	@protected

	//	GUI buttons and others
    IBOutlet NSBrowser				*fileBrowser;
	
	IBOutlet NSTextField			*tfName;
	IBOutlet NSTextField			*tfSize;
	IBOutlet NSTextField			*tfDatTime;
	IBOutlet NSTextField			*tfStartCluster;

	IBOutlet NSImageView			*imageIcon;	
	
	IBOutlet NSMenuItem				*miOpen;
	IBOutlet NSMenuItem				*miOpenRecent;
	IBOutlet NSMenuItem				*miSave;
	IBOutlet NSMenuItem				*miSaveAs;
	IBOutlet NSMenuItem				*miEject;
	
	IBOutlet NSMenuItem				*miEdit;
	IBOutlet NSMenuItem				*miExtractFiles;
	IBOutlet NSMenuItem				*miRename;
	IBOutlet NSMenuItem				*miDelete;
	
	Node							*rootNode;
	NodeFloppy						*nodeDiskA;
	NodeFloppy						*nodeDiskB;
	NodeFloppy						*nodeDiskC;	
	NodeFloppy						*nodeDiskD;	
	NodeFloppy						*nodeDiskE;
	NodeFloppy						*nodeDiskF;
	NodeFloppy						*nodeDiskG;	
	NodeFloppy						*nodeDiskH;	
	
	NSText 							*fieldEditor;
}

//	Methods GUI binded to IB
-(IBAction) 	readDisk:(id)sender;
-(IBAction) 	writeDiskAs:(id)sender;
-(IBAction) 	writeDisk:(id)sender;
-(IBAction) 	ejectDisk:(id)sender;

-(IBAction) 	extractFileFromDisk:(id)sender;
-(IBAction) 	addFilesToDisk:(id)sender;
-(IBAction) 	addFolderToDisk:(id)sender;
-(IBAction) 	removeFilesToDisk:(id)sender;
-(IBAction) 	renameFile:(id)sender;

-(IBAction) 	openBootsectorDetails:(id)sender;
-(IBAction) 	openBlankDisk:(id)sender;

@end
