//
//  GUIBootSector.h
//
//  Created by Laurent on 09/03/2012.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>

@interface GUIBootSectorController : NSWindowController {

	@protected
	
	//	GUI buttons and others
	IBOutlet NSTextField			*tfVolumeName;
	IBOutlet NSTextField			*tfVolumeSize;
	IBOutlet NSTextField			*tfFreeEntries;
	
	IBOutlet NSTextField			*tfBRA;
	IBOutlet NSTextField			*tfOEM;   
	IBOutlet NSTextField			*tfSERIAL;	
	IBOutlet NSTextField			*tfBPS;  
	IBOutlet NSTextField			*tfSPC;	    
	IBOutlet NSTextField			*tfRESSEC;	
	IBOutlet NSTextField			*tfNFATS;	
	IBOutlet NSTextField			*tfNDIRS;	
	IBOutlet NSTextField			*tfNSECTS;	
	IBOutlet NSTextField			*tfMEDIA;	
	IBOutlet NSTextField			*tfSPF;
	IBOutlet NSTextField			*tfSPT;
	IBOutlet NSTextField			*tfNHEADS;	
	IBOutlet NSTextField			*tfNHID;    
	IBOutlet NSTextField			*tfEXECFLAG;
	IBOutlet NSTextField			*tfLDMODE;	
	IBOutlet NSTextField			*tfSSECT;	
	IBOutlet NSTextField			*tfSECTCNT; 
	IBOutlet NSTextField			*tfLDAADDR; 
	IBOutlet NSTextField			*tfFATBUF;	
	IBOutlet NSTextField			*tfFNAME;	
	IBOutlet NSTextField			*tfRESERVED;
	IBOutlet NSTextField			*tfCHECKSUM;
	
	NSString						*notificationName;
	NSString						*title;

}


-(id)				initWithNotification:(NSString *)notification driveName:(NSString *)driveName;
-(void)				showUI;

-(void) 			notificationDriveChange:(NSNotification*)notification;

@end
