//
//  NodeFile.m
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import "NodeDirectory.h"
#import "Constants.h"
//#import <IconsCore.h>

@implementation NodeDirectory

@synthesize extension;
@synthesize dateTime;
@synthesize directoryEntry;
@synthesize countClustersUsed;


//---------------------------------------------------------------------------
-(id) initWithParent:(Node *)parent rawEntry:(STDirectoryEntry *)aDirectoryEntry fromDisk:(STFloppy *)disk {  
  
    if (self = [super initWithParent:parent ]) {
    
		self->floppyDisk = disk;
		memcpy(&self->directoryEntry, aDirectoryEntry, sizeof(STDirectoryEntry));  
		
		char	filename[9];
		char	fileext[4];
		memset( filename, 0x00, SZ_FILENAME + 1);
		memset( fileext, 0x00, SZ_EXTENSION + 1);
		
		strncpy(filename, self->directoryEntry.FNAME, SZ_FILENAME );	
		strncpy(fileext, self->directoryEntry.FEXT, SZ_EXTENSION );	
		
		self->name = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
		self->extension = [NSString stringWithCString:fileext encoding:NSASCIIStringEncoding];
		
		self->name = [self->name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ];
		self->extension = [self->extension stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet] ];
		
		//mandatory format is: YYYY-MM-DD HH:MM:SS ±HHMM
		//FTIME	2	Specifies the time the file or directory was created or last updated. The field has the following form:
		//	bits 0-4 Specifies two-second intervals. Can be a value in the range 0 through 29.
		//	bits 5-10 Specifies minutes. Can be a value in the range 0 through 59.
		//	bits 11-15 Specifies hours. Can be a value in the range 0 through 23.
		//FDATE	2	Specifies the date the file or directory was created or last updated. The field has the following form:
		//	bits 0-4 Specifies the day. Can be a value in the range 1 through 31.
		//	bits 5-8 Specifies the month. Can be a value in the range 1 through 12.
		//	bits 9-15 Specifies the year, relative to 1980.
		/*NSString	*timestamp = [NSString stringWithFormat:@"%4d-%02d-%02d %02d:%02d:%02d +0000", 
								  ((self->directoryEntry.FDATE & 0xFE00) >> 9) + 1980,
								  (self->directoryEntry.FDATE & 0x01E0) >> 5,
								  (self->directoryEntry.FDATE & 0x001F),
								  
								  (self->directoryEntry.FTIME & 0xF800) >> 11,	
								  (self->directoryEntry.FTIME & 0x07E0) >> 5,
								  (self->directoryEntry.FTIME & 0x001F) * 2 ];

		self->dateTime = [NSDate dateWithString: timestamp];*/
								  
		NSString	*timestamp = [NSString stringWithFormat:@"%4d-%02d-%02d %02d:%02d:%02d", 
								  ((self->directoryEntry.FDATE & 0xFE00) >> 9) + 1980,
								  (self->directoryEntry.FDATE & 0x01E0) >> 5,
								  (self->directoryEntry.FDATE & 0x001F),
								  
								  (self->directoryEntry.FTIME & 0xF800) >> 11,	
								  (self->directoryEntry.FTIME & 0x07E0) >> 5,
								  (self->directoryEntry.FTIME & 0x001F) * 2 ];
								  
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		self->dateTime = [dateFormatter dateFromString:timestamp];
		[dateFormatter release];
		
		[self->name retain];
		[self->extension retain];
		[self->floppyDisk retain];
		[self->dateTime retain];
		
		
		//	image
		[self assignIconImage];
		[self->imageIcon retain];
	}           
    return self;
}
//---------------------------------------------------------------------------
- (void)dealloc {

	[self->floppyDisk release];
	[self->name release];
	[self->extension release];
	[self->dateTime release];
	
    [super dealloc];
}
//---------------------------------------------------------------------------
-(bool) isLeaf {
	
	return ![self isDirectory];
}
//---------------------------------------------------------------------------
-(NSString *) nameValue {
	
	if( [self->extension isEqualToString:@""] ) {
	
		return self->name;
	}
	return [NSString stringWithFormat:@"%@.%@", self->name, self->extension];
}
//---------------------------------------------------------------------------
-(void) assignIconImage {
	
	if( [self isDirectory] ) {
	
		if( [self->name isEqualToString:@"AUTO"] || [self->extension isEqualToString:@"CPX"]){
		
			self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kSystemFolderIcon)];
		}
		else {
			self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		}
	}
	else {
		if( [self->extension isEqualToString:@"PRG"] || [self->extension isEqualToString:@"APP"]) {
			self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
		}
		else if( [self->extension isEqualToString:@"TOS"] || [self->extension isEqualToString:@"TTP"]) {
			self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
		}
		else if( [self->extension isEqualToString:@"INF"]) {
			self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kDesktopIcon)];
		}
		else if( [self->extension isEqualToString:@"ACC"]) {
			self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDeskAccessoryIconResource)];
		}		
		else {		
			self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIconResource)];
		}
	}
}

//---------------------------------------------------------------------------
//			Méthodes de commoditées.
//---------------------------------------------------------------------------

-(bool)	isReadOnly {

	return	(self->directoryEntry.FATTRIB & BIT_READONLY) != 0;
}
//---------------------------------------------------------------------------
-(bool)	isHidden {

	return	(self->directoryEntry.FATTRIB & BIT_HIDDEN) != 0;
}
//---------------------------------------------------------------------------

-(bool)	isSystem {

	return	(self->directoryEntry.FATTRIB & BIT_SYSTEM) != 0;
}
//---------------------------------------------------------------------------

-(bool)	isVolumeLabel {

	return	(self->directoryEntry.FATTRIB & BIT_VOLUMELABEL) != 0;
}
//---------------------------------------------------------------------------

-(bool)	isDirectory {

	return	(self->directoryEntry.FATTRIB & BIT_DIRECTORY) != 0;
}
//---------------------------------------------------------------------------

-(bool)	isModified {

	return	(self->directoryEntry.FATTRIB & BIT_MODIFIED) != 0;
}
//---------------------------------------------------------------------------
-(UInt32)	sizeOfFile {

	return	self->directoryEntry.FSIZE;
}
//---------------------------------------------------------------------------
-(NSString *) dateOfFileAsString {
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSString		*stringDate;
	
	[dateFormatter setDateStyle: kCFDateFormatterLongStyle ];		//	NSDateFormatterShortStyle equal to kCFDateFormatterShortStyle.
	[dateFormatter setTimeStyle: kCFDateFormatterMediumStyle ];		//	NSDateFormatterShortStyle equal to kCFDateFormatterShortStyle.

	if( self->dateTime != nil ) {
		
		stringDate = [dateFormatter stringFromDate: self->dateTime];
	}
	
	[dateFormatter release];
	return stringDate;
}


@end
