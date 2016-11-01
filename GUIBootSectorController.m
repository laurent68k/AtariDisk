//
//  GUIBootSectorController.m
//
//  Created by Laurent on 09/03/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import "GUIBootSectorController.h"
#import "STFloppyManager.h"
#import	"Constants.h"

@implementation GUIBootSectorController

//---------------------------------------------------------------------------
- (id)initWithNotification:(NSString *)notification driveName:(NSString *)driveName{  
  
    if (self = [super init]) {
		
		self->notificationName = notification;
		self->title = driveName;
	}           
    return self;
}
//---------------------------------------------------------------------------
-(void) dealloc {
			
    [super dealloc];
}
//---------------------------------------------------------------------------
- (void) showUI {
	
    // load the nib
    if (NULL == [self window]) {
	
        [NSBundle loadNibNamed: @"BootSector" owner: self];
    }
	[[self window] setTitle:self->title];
    [self showWindow:self];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

-(void) clearGUI {
	
	[self->tfVolumeName setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfVolumeSize setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfFreeEntries  setStringValue: [NSString stringWithFormat:@"-"]];
	
	[self->tfBRA setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfOEM setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfSERIAL setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfBPS setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfSPC setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfRESSEC setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfNFATS setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfNDIRS setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfNSECTS	setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfMEDIA setStringValue: [NSString stringWithFormat:@"-"]];	
	[self->tfSPF setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfSPT setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfNHEADS	setStringValue: [NSString stringWithFormat:@"-"]];	
	[self->tfNHID setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfEXECFLAG setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfLDMODE	setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfSSECT setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfSECTCNT setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfLDAADDR setStringValue: [NSString stringWithFormat:@"-"]];	
	[self->tfFATBUF setStringValue: [NSString stringWithFormat:@"-"]];
	[self->tfCHECKSUM setStringValue: [NSString stringWithFormat:@"-"]];	
}
//---------------------------------------------------------------------------
- (void)awakeFromNib
{
	[[self window] setTitle: DTL_WINDOW__TITLE];
	
	[self clearGUI];
	
	//	Register for item change
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationDriveChange:) name:self->notificationName object:nil];	
}
//---------------------------------------------------------------------------
- (void)windowWillClose:(NSNotification *)note {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:self->notificationName object:nil];
	
	[self release];
}

//---------------------------------------------------------------------------
//	
//---------------------------------------------------------------------------

-(NSString *) dateToString:(NSDate *)aDate {
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSString		*stringDate;
	
	[dateFormatter setDateStyle: kCFDateFormatterLongStyle ];		//	NSDateFormatterShortStyle equal to kCFDateFormatterShortStyle.
	[dateFormatter setTimeStyle: kCFDateFormatterMediumStyle ];		//	NSDateFormatterShortStyle equal to kCFDateFormatterShortStyle.

	stringDate = [dateFormatter stringFromDate:aDate];
	
	[dateFormatter release];
	return stringDate;
}
//---------------------------------------------------------------------------
-(void) notificationDriveChange:(NSNotification*)notification {

	NSObject	*disk = (NSObject *)[[notification userInfo] objectForKey: KEY_OBJECT_NOTIFICATION ];
	
	if( [disk isKindOfClass:[STFloppy class]] ) {
		
		if( ((STFloppy *)disk).diskLoaded ) {
			
			[self->tfVolumeName setStringValue: [NSString stringWithFormat:@"%@", ( ((STFloppy *)disk).volumeName != nil ? ((STFloppy *)disk).volumeName : @"")]];
			[self->tfVolumeSize setStringValue: [NSString stringWithFormat:@"%d Kbytes", [((STFloppy *)disk) volumeSize] / 1024]];
			
			[self->tfFreeEntries setStringValue: [NSString stringWithFormat:@"%d/%d (2 reserved)", [((STFloppy *)disk) countFATEntriesFree], [((STFloppy *)disk) countFATTotalEntries]]];
			
			[self->tfBRA setStringValue: [NSString stringWithFormat:@"$%04X", ((STFloppy *)disk).bootSector.BRA]];	
			[self->tfOEM setStringValue: [NSString stringWithFormat:@"%@", [((STFloppy *)disk) bootsectorOEM] ]];
			[self->tfSERIAL setStringValue: [NSString stringWithFormat:@"$%X%X%X (24 bits)", (((STFloppy *)disk).bootSector.SERIAL[2]), (((STFloppy *)disk).bootSector.SERIAL[1]), (((STFloppy *)disk).bootSector.SERIAL[0])]];
			[self->tfBPS setStringValue: [NSString stringWithFormat:@"%d", [((STFloppy *)disk) bootsectorBPS] ]];
			[self->tfSPC setStringValue: [NSString stringWithFormat:@"%d", ((STFloppy *)disk).bootSector.SPC]];
			[self->tfRESSEC setStringValue: [NSString stringWithFormat:@"%d", ((STFloppy *)disk).bootSector.RESSEC]];
			[self->tfNFATS setStringValue: [NSString stringWithFormat:@"%d", ((STFloppy *)disk).bootSector.NFATS]];	
			[self->tfNDIRS setStringValue: [NSString stringWithFormat:@"%d", [((STFloppy *)disk) bootsectorNDIRS] ]];
			[self->tfNSECTS	setStringValue: [NSString stringWithFormat:@"%d", [((STFloppy *)disk) bootsectorNSECTS] ]];
			[self->tfMEDIA setStringValue: [NSString stringWithFormat:@"$%X (Unused on Atari)", ((STFloppy *)disk).bootSector.MEDIA]];	
			[self->tfSPF setStringValue: [NSString stringWithFormat:@"%d", ((STFloppy *)disk).bootSector.SPF]];
			[self->tfSPT setStringValue: [NSString stringWithFormat:@"%d", ((STFloppy *)disk).bootSector.SPT]];
			[self->tfNHEADS	setStringValue: [NSString stringWithFormat:@"%d", ((STFloppy *)disk).bootSector.NHEADS]];	
			[self->tfNHID setStringValue: [NSString stringWithFormat:@"%d (Unused on Atari)", ((STFloppy *)disk).bootSector.NHID]];
/*		[self->tfEXECFLAG setStringValue: [NSString stringWithFormat:@"EXECFLAG : $%X", ((STFloppy *)disk).bootSector.EXECFLAG]];	
		[self->tfLDMODE	setStringValue: [NSString stringWithFormat:@"Load mode (LDMODE): %d (if = 0 FNAME field is located and loaded)", ((STFloppy *)disk).bootSector.LDMODE]];	
		[self->tfSSECT setStringValue: [NSString stringWithFormat:@"Logical sector from where we boot (SSECT): %d", ((STFloppy *)disk).bootSector.SSECT]];	
		[self->tfSECTCNT setStringValue: [NSString stringWithFormat:@"Number of sectors to load for the boot (SECTCNT): %d", ((STFloppy *)disk).bootSector.SECTCNT]];	
		[self->tfLDAADDR setStringValue: [NSString stringWithFormat:@"Memory address where boot program will be loaded (LDAADDR): $%X", ((STFloppy *)disk).bootSector.LDAADDR]];	
		[self->tfFATBUF setStringValue: [NSString stringWithFormat:@"FATBUF: $%X", ((STFloppy *)disk).bootSector.FATBUF]];	
*/
			char	fname[12];
			memset(fname, 0x00, 12);
			strncpy( fname, ((STFloppy *)disk).bootSector.FNAME, 11);

			[self->tfFNAME setStringValue: [NSString stringWithFormat:@"FNAME: %s", fname]];		
			[self->tfCHECKSUM setStringValue: [NSString stringWithFormat:@"$%04X ", ((STFloppy *)disk).bootSector.CHECKSUM]];	

		}
		else {
			[self clearGUI];
		}
	} 
	else {
	
		[self clearGUI];
	}	
}
//---------------------------------------------------------------------------


@end
