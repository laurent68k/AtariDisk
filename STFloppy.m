//
//  STFloppy.m
//
//	Main base class to handle the basic operation with an ATARI floppy image in .ST format (Raw floppy disk image).
//
//  Created by Laurent on 02/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	Operating System:	OSX 10.6 Snow Leopard
//	Xcode:				3.2.6
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

/*
	  .ST FILE FORMAT
	--===============-------------------------------------------------------------

	The file format of the .ST image files used by PaCifiST is simplicity itself;
	they are just straight images of the disk in question, with sectors stored in
	the expected logical order. So, on a sector basis the images run from sector
	0 (bootsector) to however many sectors are on the disk. On a track basis the
	layout is the same as for MSA files but obviously the data is raw, no track
	header or compression or anything like that.

	TRACK 0, SIDE 0
	TRACK 0, SIDE 1
	TRACK 1, SIDE 0
	TRACK 1, SIDE 1
	TRACK 2, SIDE 0
	TRACK 2, SIDE 1
*/

#import "STFloppy.h"
#import "STFloppyCluster.h"
#import "Constants.h"

@implementation STFloppy

@synthesize diskLoaded;
@synthesize bootSector;
@synthesize firstFat12;
@synthesize secondFat12;
@synthesize rootDirectory;
@synthesize countFATEntries;

@synthesize volumeName;

#define DEF_NUMBYTESPERSECTOR 	512

//---------------------------------------------------------------------------
-(id)init {  
	
    if (self = [super init]) {
		
		self->diskLoaded = false;
		
	}           
    return self;
}
//---------------------------------------------------------------------------
-(void)dealloc {
	
    [super dealloc];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

/**
  Clean up all data structures and set no disk is currently loaded
  
  @param	tracks number of tracks per side
  @param	sectors number of sectors per side
  @param	sides number of sides
  
  @returns 	size in bytes 
 */
-(void) cleanup {

	if( self->volumeName != nil ) {
		[self->volumeName release];
	}
	if( self->diskBuffer != nil ) {
		[self->diskBuffer release];
	}
	if( firstFat12 != nil ) {
		free(self->firstFat12);		
	}
	if( secondFat12 != nil ) {
		free(self->secondFat12);
	}
	if( rootDirectory != nil ) {
		free(self->rootDirectory);
	}
	
	self->volumeName = nil;
	self->diskBuffer = nil;
	self->firstFat12 = NULL;
	self->secondFat12 = NULL;
	self->rootDirectory = NULL;
	memset( &self->bootSector, 0x00, sizeof(STBootSector));
	self->countFATEntries = 0;
	
	self->diskLoaded = false;
}
//---------------------------------------------------------------------------
/**
  Read the bootsector of the disk loaded in the diskBuffer. Instance variable bootSector
  is initialized with the entire bootsector
   
  @returns YES if a disk is loaded and bootsector read
 */
-(bool) readBootSector  {

	bool	success = NO;
	if( self->diskBuffer != nil ) {
	
		//	this struct will contains the entire boot sector still sized to 512 bytes
		[self->diskBuffer getBytes: (void *)&self->bootSector length: SZ_BOOTSECTOR ];
		success = YES;
	}
	return success;
}
//---------------------------------------------------------------------------
/**
  Read the first FAT from the diskBuffer and copy this one in the instance variable firstFat12 
   
  @returns Max entries count in the FAT
 */
-(UInt32) readFirstFAT {

	UInt32 countEntries = 0;
	if( self->diskBuffer != nil ) {
		NSRange	range;
		
		range.location = self->bootSector.RESSEC * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);												//	start address in bytes
		range.length = self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);														//	lengh in bytes
		
		//	Count of entries: in FAT12 is the count of 12 bits-words capacity
		countEntries = self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) * 8 / 12;										//	compute the entries capacity}
		
		self->firstFat12 = malloc( sizeof( STFatDouble12 ) * countEntries / 2);
		memset( self->firstFat12, 0x00, sizeof( STFatDouble12 ) * countEntries / 2 );
		
		[self->diskBuffer getBytes: (void *)self->firstFat12 range:range];
	}
	
	return countEntries;	
}
//---------------------------------------------------------------------------
/**
  Read the second FAT if exists from the diskBuffer and copy this one in the instance variable secondFat12 
   
  @returns Max entries count in the FAT
 */
 -(UInt32) readSecondFAT {

	UInt32 countEntries = 0;
	if( self->diskBuffer != nil ) {

		//	Lire la FAT12 de secours si elle existe
		if( self->bootSector.NFATS == 2 ) {
			NSRange	range;
			
			range.location = self->bootSector.RESSEC * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) + self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);			//	start address in bytes
			range.length = self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);													//	lengh in bytes

			//	Count of entries: in FAT12 is the count of 12 bits-words capacity
			countEntries = self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) * 8 / 12;											//	compute the entries capacity
			
			self->secondFat12 = malloc( sizeof( STFatDouble12 ) * countEntries / 2);
			memset( self->secondFat12, 0x00, sizeof( STFatDouble12 ) * countEntries / 2 );

			[self->diskBuffer getBytes: (void *)self->secondFat12 range:range];
		}
		else {
			NSLog(@"No secondary FAT");	
		}
	}
	return countEntries;
}
//---------------------------------------------------------------------------
/**
  Read the root directory from the diskBuffer and copy this one in the instance variable rootDirectory 
   
  @returns None
 */
-(void) readRootDirectory {

	NSRange	range;

	//	Following the BootSecor and FATs we have the root directory: Size = 7 sectors * 512 bytes / entry size (32) = 112 entries
	range.location = self->bootSector.RESSEC * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) + ( 2 * self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH));			//	start address in bytes
	range.length = SWAP_BYTE(self->bootSector.NDIRS_LOW,self->bootSector.NDIRS_HIGH) * sizeof(STDirectoryEntry);
					
	self->rootDirectory = malloc( SWAP_BYTE(self->bootSector.NDIRS_LOW,self->bootSector.NDIRS_HIGH) * sizeof(STDirectoryEntry) );					
	[self->diskBuffer getBytes: (void *)self->rootDirectory range:range];																
}
//---------------------------------------------------------------------------
/**
  Compute and return the number of bytes per sector
   
  @returns None
 */
-(UInt16) bootsectorBPS {

	return (UInt16)SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);
}
//---------------------------------------------------------------------------
/**
  Return the number of entries possible in the root directory
   
  @returns None
 */
 -(UInt16) bootsectorNDIRS {

	return (UInt16)SWAP_BYTE(self->bootSector.NDIRS_LOW,self->bootSector.NDIRS_HIGH);
}
//---------------------------------------------------------------------------
-(UInt16) bootsectorNSECTS {

	return (UInt16)SWAP_BYTE(self->bootSector.NSECTS_LOW,self->bootSector.NSECTS_HIGH);
}
//---------------------------------------------------------------------------
/**
  Return the content of field OEM from the boot sector
   
  @returns None
 */
 -(NSString *) bootsectorOEM {

	char	oem[7];
	memset(oem, 0x00, 7);
	strncpy( oem, self->bootSector.OEM, 6);
	
	return [NSString stringWithCString:oem encoding:NSASCIIStringEncoding];
}
//---------------------------------------------------------------------------
/**
  Return the disk size in bytes
   
  @returns None
 */
-(UInt32) volumeSize {

	return SWAP_BYTE(self->bootSector.NSECTS_LOW,self->bootSector.NSECTS_HIGH) * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);
}
//---------------------------------------------------------------------------
/**
  Return the size in bytes of a cluster
   
  @returns None
 */
-(UInt32) sizeCluster {

	return SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) * self->bootSector.SPC;
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

/**
  Read a cluster in the disk cluster area and store the bytes field in the parameter cluster
  
  @param	numCluster is the cluster number 0-based index (In the FAT the index = numCluster + 2)
  @param	cluster is an object which will ave its buffer feed with the content
   
  @returns None
 */
-(void) readCluster:(UInt32)numCluster clusterBuffer:(STFloppyCluster *)cluster {

	NSRange	range;

	range.location = self->indexFreeSpace;										//	should be like 0x1C00
	range.location = range.location + numCluster * [self sizeCluster];
	range.length = [self sizeCluster];											//	should be 1024
	
	[self->diskBuffer getBytes: (void *)cluster.buffer range:range];
}
//---------------------------------------------------------------------------
/**
  Write a cluster in the disk cluster area with the content in parameter
  
  @param	numCluster is the cluster number 0-based index (In the FAT the index = numCluster + 2)
  @param	buffer is the content to write in this cluster
  @param	sizeToWrite of buffer to write
   
  @returns None
 */
-(void) writeCluster:(UInt32)numCluster fromBuffer:(void *)buffer size:(UInt32)sizeToWrite {

	NSRange	range;
	
	range.location = self->indexFreeSpace;										//	should be like 0x1C00
	range.location = range.location + numCluster * [self sizeCluster];
	range.length = sizeToWrite;											
		
	[self->diskBuffer replaceBytesInRange:range withBytes:buffer];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

//	Read an entry in the 12bits FAT as follows:
//	Example:	cluster	373	($175)	next is 374			
//				cluster 374 ($176)	)next is NONE
//	In the FAT we have:
//	$75				$75 is the lower
//	$61				$x1 is the upper and $6x is the next lower
//	$17				$17 is the upper

-(UInt32) getFATValueAt:(UInt32) indexInFAT {
	
	UInt32	value;
	UInt32	indexDouble = indexInFAT / 2;
	STFatDouble12 doubleEntry = self->firstFat12[ indexDouble ];
	
	UInt32	low, high;
	//	we are on a n-bytes border 
	if( (indexInFAT & 0x0001) == 0) {
		
		low = doubleEntry.clusterNmber[0];
		
		high = (doubleEntry.clusterNmber[1] & 0x0F);
		high = high << 8;	
	}
	else {
		
		low = doubleEntry.clusterNmber[1] & 0xF0;
		low = low >> 4;
		
		high = doubleEntry.clusterNmber[2] ;
		high = high << 4;
	}
	value = (high | low);
	return value;
}
//---------------------------------------------------------------------------
-(void) setFATValueAt:(UInt32) indexInFAT withValue:(UInt16)value {

	UInt32	indexDouble = indexInFAT / 2;
	STFatDouble12 *doubleEntry = &(self->firstFat12[ indexDouble ]);
	
	//	we are on a n-bytes border 
	if( (indexInFAT & 0x0001) == 0) {
		
		//	set low value
		doubleEntry->clusterNmber[0] = (char)(value & 0xFF);
		
		(doubleEntry->clusterNmber[1] = (char)((value >> 8 ) & 0x0F));
	}
	else {
		
		doubleEntry->clusterNmber[1] = (char)((value << 4) & 0xF0);
		
		doubleEntry->clusterNmber[2] = (char)((value >> 4 ) & 0xFF);
	}
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

//$000			Available cluster.
//$002-$FEF		Index of entry for the next cluster in the file or directory. 
//$FF0-$FF6		Reserved
//$FF7			Bad sector in cluster; do not use cluster.
//$FF8-$FFF		Last cluster of file or directory. (usually the value $FFF is used)

-(UInt32) extractClusters:(NSMutableArray *)clusters AtFATIndex:(UInt32) indexFATEntry {

	STFloppyCluster	*cluster = nil;
	UInt32			numCluster = indexFATEntry - 2;			//	FAT Entry $002 is the first => Cluster 0 available
			
	cluster = [[STFloppyCluster alloc] init:[self sizeCluster] withNumber:numCluster];
	[self readCluster: numCluster clusterBuffer:cluster];
				
	[clusters addObject: (id)cluster];	

	UInt32	indexNextCluster = [self getFATValueAt:indexFATEntry];
	while( indexNextCluster >= 0x002 && indexNextCluster <= 0xFEF ) {
	
		numCluster = indexNextCluster - 2;
		
		cluster = [[STFloppyCluster alloc] init:[self sizeCluster] withNumber:numCluster];
		[self readCluster: numCluster clusterBuffer:cluster];				
		[clusters addObject: (id)cluster];
		
		indexNextCluster = [self getFATValueAt:indexNextCluster];
	}
	return [clusters count];
}
//---------------------------------------------------------------------------
-(void) assembleClusters:(NSMutableArray *)clusters inBuffer:(void **)buffer {

	UInt32	sizeBuffer = [self sizeCluster] * [clusters count];

	*buffer = malloc( sizeBuffer );
	for(int index = 0; index < [clusters count]; index++ ) {
		
		STFloppyCluster	*cluster = [clusters objectAtIndex:index];
		memcpy( *buffer + (index * [self sizeCluster]), cluster.buffer, [self sizeCluster]);
	}
}
//---------------------------------------------------------------------------
-(void) saveBackClusters:(NSMutableArray *)clusters fromBuffer:(void *)buffer {

	for(int index = 0; index < [clusters count]; index++ ) {
		
		STFloppyCluster	*cluster = [clusters objectAtIndex:index];
		[self writeCluster:cluster.number fromBuffer:(buffer + (index * [self sizeCluster])) size:[self sizeCluster]];
	}
}
//---------------------------------------------------------------------------
-(void) extractFileContentFromDisk:(UInt32) indexFATEntry inBuffer:(void **)buffer {

	NSMutableArray		*clusters = [[NSMutableArray alloc] init];
	
	[self extractClusters:clusters AtFATIndex:indexFATEntry];
	[self assembleClusters:clusters inBuffer:(void **)buffer];
	
	[clusters release];
}
//---------------------------------------------------------------------------
+(void) decodeDate:(NSDate *)aDate year:(UInt8 *)year month:(UInt8 *)month day:(UInt8 *)day hour:(UInt8 *)hour minute:(UInt8 *)minute second:(UInt8 *)second {
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	[dateFormatter setDateFormat:@"yyyy"];
	*year = [[dateFormatter stringFromDate:aDate] intValue];
	
	[dateFormatter setDateFormat:@"MM"];
	*month = [[dateFormatter stringFromDate:aDate] intValue];
	
	[dateFormatter setDateFormat:@"dd"];
	*day = [[dateFormatter stringFromDate:aDate] intValue];
	
	[dateFormatter setDateFormat:@"HH"];
	*hour = [[dateFormatter stringFromDate:aDate] intValue];
	
	[dateFormatter setDateFormat:@"mm"];
	*minute = [[dateFormatter stringFromDate:aDate] intValue];
	
	[dateFormatter setDateFormat:@"ss"];
	*second = [[dateFormatter stringFromDate:aDate] intValue];

	[dateFormatter release];
}
//---------------------------------------------------------------------------
-(void) commitDisk {

	NSRange	range;
	
	range.location = self->bootSector.RESSEC * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);						//	start address in bytes
	range.length = self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);							//	lengh in bytes
	[self->diskBuffer replaceBytesInRange:range withBytes:(void *)firstFat12];

	//	On copie dans la FAT 2 le contenu de la FAT 1
	if( self->bootSector.NFATS == 2 ) {
		range.location = self->bootSector.RESSEC * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) + self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);			//	start address in bytes
		range.length = self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH);

		[self->diskBuffer replaceBytesInRange:range withBytes:(void *)firstFat12];
	}
	
	//	Following the BootSecor and FATs we have the root directory: Size = 7 sectors * 512 bytes / entry size (32) = 112
	range.location = self->bootSector.RESSEC * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) + ( 2 * self->bootSector.SPF * SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH));			//	start address in bytes
	range.length = SWAP_BYTE(self->bootSector.NDIRS_LOW,self->bootSector.NDIRS_HIGH) * sizeof(STDirectoryEntry);;

	[self->diskBuffer replaceBytesInRange:range withBytes:(void *)rootDirectory];
	
	NSLog(@"commitDisk done");
}
//---------------------------------------------------------------------------
-(void) rollbackDisk {

	FREENULL(self->firstFat12);		
	FREENULL(self->secondFat12);
	FREENULL(self->rootDirectory);

	[self readBootSector];	
	self->countFATEntries = [self readFirstFAT];	
	[self readSecondFAT];
		
	[self readRootDirectory];
	
	NSLog(@"rollbackDisk done");
}
//---------------------------------------------------------------------------
-(void) buildDirectoryEmpty:(void *)buffer clusterParent:(UInt32)clusterParent clusterSelf:(UInt32)clusterSelf {

	STDirectoryEntry	*directoryContent = (STDirectoryEntry *)buffer;
	UInt8 year, month, day, hour, minute, second;
	[STFloppy decodeDate:[NSDate date] year:&year month:&month day:&day hour:&hour minute:&minute second:&second];
	year -= 1980;
					
	memcpy(&(directoryContent[0].FNAME), ".       ", 8);
	memset(&(directoryContent[0].FEXT), 0x20, 3);
	directoryContent[0].FATTRIB = BIT_DIRECTORY;
	directoryContent[0].FTIME = (hour << 11) | (minute << 5) | (second / 2);
	directoryContent[0].FDATE = (year << 9) | ( month << 5 ) | (day);
	directoryContent[0].SCLUSTER = clusterSelf;
	directoryContent[0].FSIZE = 0;

	memcpy(&(directoryContent[1].FNAME), "..      ", 8);
	memset(&(directoryContent[1].FEXT), 0x20, 3);
	directoryContent[1].FATTRIB = BIT_DIRECTORY;
	directoryContent[1].FTIME = (hour << 11) | (minute << 5) | (second / 2);
	directoryContent[1].FDATE = (year << 9) | ( month << 5 ) | (day);
	directoryContent[1].SCLUSTER = clusterParent;
	directoryContent[1].FSIZE = 0;
}


//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

+(bool) createSTImage:(int)tracks withSectors:(int)sectors withSides:(int)sides inBuffer:(NSData **)floppyBuffer withName:(NSString *)diskName withExtension:(NSString *)diskExtension {

	UInt8 				*diskFile;
	unsigned long 		diskSize;	
	STBootSector		*bootsector;
	
	sides = (sectors >= 18 ? 2 : sides);
	diskSize = tracks * sectors * sides * DEF_NUMBYTESPERSECTOR;

	/* Allocate space for our 'file', and blank */
	diskFile = malloc(diskSize);
	if (diskFile == NULL) {		
		return false;
	}
	memset(diskFile, 0, diskSize);                      				

	bootsector = (STBootSector *)diskFile;

	/* Fill in boot-sector */
	bootsector->BRA = 0x00E9;                                  			
	char loader[7] = "Loader";											/* 2-7 'Loader' */
	memcpy( bootsector->OEM, loader, 6);
	
	*((UInt32 *)(&bootsector->SERIAL)) = (arc4random() % 0xFFFFFF);

	bootsector->BPS_LOW = DEF_NUMBYTESPERSECTOR & 0xFF;
	bootsector->BPS_HIGH = (DEF_NUMBYTESPERSECTOR & 0xFF00) >> 8;
	
	bootsector->SPC = ((tracks == 40) && (sides == 1)) ? 1 : 2;
	bootsector->RESSEC = 1;
	bootsector->NFATS = 2;
	
	if (bootsector->SPC==1) {
	
		bootsector->NDIRS_LOW = 64;
		bootsector->NDIRS_HIGH = 0;
	}
	else if (sectors < 18) {
		
		bootsector->NDIRS_LOW = 112;
		bootsector->NDIRS_HIGH = 0;
	}
	else {
		
		bootsector->NDIRS_LOW = 224 & 0xFF;
		bootsector->NDIRS_HIGH = (224 & 0xFF00) >> 8;
	}

	bootsector->NSECTS_LOW = ((tracks * sectors * sides) & 0xFF);
	bootsector->NSECTS_HIGH = ((tracks * sectors * sides) & 0xFF00) >> 8;
	
	if (sectors >= 18)
		bootsector->MEDIA = 0xF0;
	else
	{
		if (tracks <= 42)
			bootsector->MEDIA = 0xFC;
		else
			bootsector->MEDIA = 0xF8;
		
		if (sides == 2)
			bootsector->MEDIA |= 0x01;
	}

	if (sectors >= 18)
		bootsector->SPF = 9;
	else if (tracks >= 80)
		bootsector->SPF = 5;
	else
		bootsector->SPF = 2;
	
	bootsector->SPT = sectors;
	bootsector->NHEADS = sides;
	bootsector->NHID = 0;

	/* Set correct media bytes in the 1st FAT: */
	diskFile[512] = 0xF9;
	diskFile[513] = 0xFF;
	diskFile[514] = 0xFF;
	
	/* Set correct media bytes in the 2nd FAT: */
	diskFile[512 + bootsector->SPF * 512] = 0xF9;
	diskFile[513 + bootsector->SPF * 512] = 0xFF;
	diskFile[514 + bootsector->SPF * 512] = 0xFF;

	//	Set a disk name in the root directory
	if( [diskName length] != 0) {
	
		UInt32 startRootDirectory = bootsector->RESSEC * SWAP_BYTE(bootsector->BPS_LOW,bootsector->BPS_HIGH) + ( 2 * bootsector->SPF * SWAP_BYTE(bootsector->BPS_LOW,bootsector->BPS_HIGH));			//	start address in bytes	
	
		STDirectoryEntry	dirEntry;
		
		memcpy(&(dirEntry.FNAME), [[diskName uppercaseString] UTF8String], SZ_FILENAME);
		//memcpy(&(dirEntry.FEXT), [@"   " UTF8String], SZ_EXTENSION);
        memcpy(&(dirEntry.FEXT), [[diskExtension uppercaseString] UTF8String], SZ_EXTENSION);
		
		UInt8 year, month, day, hour, minute, second;
		[STFloppy decodeDate:[NSDate date] year:&year month:&month day:&day hour:&hour minute:&minute second:&second];
		year -= 1980;

		dirEntry.FATTRIB = BIT_VOLUMENAME;
		dirEntry.FTIME = (hour << 11) | (minute << 5) | (second / 2);
		dirEntry.FDATE = (year << 9) | ( month << 5 ) | (day);
		dirEntry.SCLUSTER = 0;
		dirEntry.FSIZE = 0;
		
		memcpy( diskFile + startRootDirectory, &dirEntry, sizeof(STDirectoryEntry));
	}
	
	*floppyBuffer = [NSData dataWithBytes:(const void *)diskFile length:diskSize];
	
	free(diskFile);
	return true;
}
//---------------------------------------------------------------------------
-(bool) readSTImage:(NSString *)filename  {

	bool success = NO;
	[self cleanup];
		
	self->diskBuffer = [[NSMutableData alloc] initWithData: [[NSFileManager defaultManager] contentsAtPath:filename]];
	if( self->diskBuffer != nil ) {
		
		[self->diskBuffer retain];
		
		//	this struct will contains the entire boot sector still sized to 512 bytes
		[self readBootSector];
						
		//	Following the BootSector we have the first FAT				
		self->countFATEntries = [self readFirstFAT];	
		
		//	And normally the second for backup				
		[self readSecondFAT];
		
		//	Following the BootSecor and FATs we have the root directory: Size = 7 sectors * 512 bytes / entry size (32) = 112
		int size = SWAP_BYTE(self->bootSector.NDIRS_LOW,self->bootSector.NDIRS_HIGH) * sizeof(STDirectoryEntry);
		
		self->rootDirectory = malloc( size );
		
		[self readRootDirectory];
		
		//	Calculer l'index de départ de la zone de secteurs libre de la disquette pour usage = BS + FAT1 + FAT2 + RootDirectory
		//	We should have something like: 1 + 3 + 3 + 7 * 512 
		indexFreeSpace = ((1 + 2 * self->bootSector.SPF ) * [self bootsectorBPS]) + size;
		
		success = YES;
		self->diskLoaded = true;
	}
	return success;
}

//---------------------------------------------------------------------------
-(bool)	extractFileSTImage:(UInt32)startCluster size:(UInt32)sizeBytes inBuffer:(NSData **)fileMemory {

	UInt8	*clustersMemory;			//	will contents the contigues clusters for the file
	
	[self extractFileContentFromDisk:startCluster inBuffer:(void **)&clustersMemory];
	
	*fileMemory = [NSData dataWithBytes:clustersMemory length:sizeBytes];
	
	FREENULL(clustersMemory);
	
	return YES;
}
//---------------------------------------------------------------------------
-(STFloppyError) addFileSTImage:(STDirectoryEntry *)directoryContent directorySize:(UInt32) directorySize withData:(NSData *)fileData withName:(NSString *)filename withExtension:(NSString *)extension {

	STFloppyError code = Ok;
	bool found = false;		
	bool duplicated = false;
	SInt32 indexDirectory = -1;	
	UInt32 index = 0;
	UInt32	sizeofFile = [fileData length];
	while( index < directorySize && !duplicated) {
	
		found = ( directoryContent[index].FNAME[0] == (char)0x00 || directoryContent[index].FNAME[0] == (char)0xE5 );	
		duplicated = (memcmp( &(directoryContent[index].FNAME), [[filename uppercaseString] UTF8String], SZ_FILENAME) == 0) &&
					 (memcmp( &(directoryContent[index].FEXT), [[extension uppercaseString] UTF8String], SZ_EXTENSION) == 0);
		if(found && indexDirectory == -1) {
			//	Store the index entry where to insert the filename
			indexDirectory = index;
		}
		index++;
	}

	if( found && ! duplicated) {	
		//	Enchain each FAT entry and copy into the cluster the content of the file
		//found = false;
		UInt32 firstNumClusterInFAT = 2;
		UInt32 indexClusterInFAT = 2;	
		UInt32 prevClusterInFAT = 2;	
		UInt32 sizeFAT = [self countFATTotalEntries];
		UInt32 indexToCopy = 0;
		void *bufferCluster = malloc( [self sizeCluster] );
		bool isFirstEntry = true;
		bool fileWasAdded = false;
		while( indexClusterInFAT < sizeFAT && sizeofFile > 0 ) {
		
			found = ([self getFATValueAt:indexClusterInFAT] == 0x000);
			if(found) {
				
				if( isFirstEntry ) {				
					firstNumClusterInFAT = indexClusterInFAT;
					prevClusterInFAT = indexClusterInFAT;
					isFirstEntry = false;
				}
								
				if( sizeofFile < [self sizeCluster] ) {
					NSRange range;
					range.location = indexToCopy;
					range.length = sizeofFile;
											
					[fileData getBytes:bufferCluster range:range];
					[self writeCluster:indexClusterInFAT - 2 fromBuffer:bufferCluster size:sizeofFile];
					
					sizeofFile = 0;
					
					[self setFATValueAt:prevClusterInFAT withValue:indexClusterInFAT];
					[self setFATValueAt:indexClusterInFAT withValue:0xFFF];
					
					fileWasAdded = true;
				}
				else {
					NSRange range;
					range.location = indexToCopy;
					range.length = [self sizeCluster];
					
					[fileData getBytes:bufferCluster range:range];
					[self writeCluster:indexClusterInFAT - 2 fromBuffer:bufferCluster size:[self sizeCluster]];
					
					sizeofFile = sizeofFile - [self sizeCluster];
					indexToCopy += [self sizeCluster];
					
					[self setFATValueAt:prevClusterInFAT withValue:indexClusterInFAT];
					prevClusterInFAT = indexClusterInFAT;
				}
				memset(bufferCluster, 0x00, [self sizeCluster] );
			}
			indexClusterInFAT++;			
		}		
		FREENULL(bufferCluster);
		
		//	Create in the directory the entry for this new file
		if( fileWasAdded ) {
			//	Get current date time
			UInt8 year, month, day, hour, minute, second;
			[STFloppy decodeDate:[NSDate date] year:&year month:&month day:&day hour:&hour minute:&minute second:&second];
			year -=1980;
			
			//	Update the parent directory which contents the new added file
			memcpy(&(directoryContent[indexDirectory].FNAME), [[filename uppercaseString] UTF8String], SZ_FILENAME);
			memcpy(&(directoryContent[indexDirectory].FEXT), [[extension uppercaseString] UTF8String], SZ_EXTENSION);
			directoryContent[indexDirectory].FATTRIB = BIT_FILE;
			directoryContent[indexDirectory].FTIME = (hour << 11) | (minute << 5) | (second / 2);
			directoryContent[indexDirectory].FDATE = (year << 9) | ( month << 5 ) | (day);
			directoryContent[indexDirectory].SCLUSTER = firstNumClusterInFAT;
			directoryContent[indexDirectory].FSIZE = [fileData length];
			
			code = Ok;
		}
		else {
			code = DiskFull;
		}
	}
	else if(duplicated) {
		code = DuplicateName;
	}
	else {
		code = DirectoryFull;
	}

	return code;
}
//---------------------------------------------------------------------------
-(STFloppyError) addFolderSTImage:(STDirectoryEntry *)directoryContent directorySize:(UInt32) directorySize parentStartCluster:(UInt32)parentStartCluster withName:(NSString *)filename withExtension:(NSString *)extension withCount:(UInt32)countClusters {

	NSLog(@"parentDirectory entries: %u", directorySize);
	NSLog(@"parentDirectory StartCluster: %u", parentStartCluster);
	NSLog(@"new Directory: will have %u clusters", countClusters);

	STFloppyError code = Ok;
	bool found = false;		
	bool duplicated = false;
	SInt32 indexDirectory = -1;	
	UInt32 index = 0;
	while( index < directorySize && !duplicated ) {
	
		found = ( directoryContent[index].FNAME[0] == ENTRY_FREE || directoryContent[index].FNAME[0] == ENTRY_DELETED);	
		duplicated = (memcmp( &(directoryContent[index].FNAME), [[filename uppercaseString] UTF8String], SZ_FILENAME) == 0) &&
				 	 (memcmp( &(directoryContent[index].FEXT), [[extension uppercaseString] UTF8String], SZ_EXTENSION) == 0);
		if(found && indexDirectory == -1) {
			//	Store the index entry where to insert the filename
			indexDirectory = index;
		}
		index++;
	}

	if( found && ! duplicated) {	
		void *clusterEmpty = malloc( [self sizeCluster] );	
		memset(clusterEmpty, 0x00, [self sizeCluster] );

		//	Enchain each FAT entry
		UInt32 firstNumClusterInFAT = 2;
		UInt32 indexClusterInFAT = 2;	
		UInt32 prevClusterInFAT = 2;	
		UInt32 sizeFAT = [self countFATTotalEntries];
		bool isFirstEntry = true;
		bool fileWasAdded = false;
		while( indexClusterInFAT < sizeFAT && countClusters > 0 ) {
		
			found = ([self getFATValueAt:indexClusterInFAT] == 0x000);
			if(found) {
				
				countClusters--;

				if( isFirstEntry ) {				
					firstNumClusterInFAT = indexClusterInFAT;
					prevClusterInFAT = indexClusterInFAT;
					isFirstEntry = false;
															
					memset(clusterEmpty, 0x00, [self sizeCluster] );
					[self buildDirectoryEmpty:clusterEmpty clusterParent:parentStartCluster clusterSelf:firstNumClusterInFAT];
					[self writeCluster:indexClusterInFAT - 2 fromBuffer:clusterEmpty size:[self sizeCluster]];
					memset(clusterEmpty, 0x00, [self sizeCluster] );
					
					NSLog(@"allocate cluster: %u", firstNumClusterInFAT);
				}
				else {
					[self writeCluster:indexClusterInFAT - 2 fromBuffer:clusterEmpty size:[self sizeCluster]];
					NSLog(@"allocate cluster: %u", indexClusterInFAT);
				}
				
				[self setFATValueAt:prevClusterInFAT withValue:indexClusterInFAT];

				if( countClusters == 0 ) {																	
					[self setFATValueAt:indexClusterInFAT withValue:0xFFF];
					fileWasAdded = true;					
				}
			}
			prevClusterInFAT = indexClusterInFAT;
			indexClusterInFAT++;		
		}
		FREENULL(clusterEmpty);
		
		//	Create in the directory the entry for this new sub-directory
		if( fileWasAdded ) {
		
			//	Get current date time
			UInt8 year, month, day, hour, minute, second;
			[STFloppy decodeDate:[NSDate date] year:&year month:&month day:&day hour:&hour minute:&minute second:&second];
			year -=1980;
			
			//	Update the parent directory which contents the new added file
			memcpy(&(directoryContent[indexDirectory].FNAME), [[filename uppercaseString] UTF8String], SZ_FILENAME);
			memcpy(&(directoryContent[indexDirectory].FEXT), [[extension uppercaseString] UTF8String], SZ_EXTENSION);
			directoryContent[indexDirectory].FATTRIB = BIT_DIRECTORY;
			directoryContent[indexDirectory].FTIME = (hour << 11) | (minute << 5) | (second / 2);
			directoryContent[indexDirectory].FDATE = (year << 9) | ( month << 5 ) | (day);
			directoryContent[indexDirectory].SCLUSTER = firstNumClusterInFAT;
			directoryContent[indexDirectory].FSIZE = 0;
			
			NSLog(@"settings new folder entry %@ in parent directory", filename);
			
			code = Ok;
		}
		else {
			code = DiskFull;
		}
	}
	else if(duplicated) {		
		code = DuplicateName;
	}
	else {
		code = DirectoryFull;
	}

	return code;
}
//---------------------------------------------------------------------------
-(STFloppyError) removeFileSTImage:(STDirectoryEntry *)directoryContent directorySize:(UInt32) directorySize withName:(NSString *)name withExtension:(NSString *)extension startCluster:(UInt32)startCluster {

	STFloppyError code = Ok;
	bool found = false;							
	UInt32 indexDirectory = 0;	
	while( !found && indexDirectory < directorySize ) {

		found = ( memcmp(&(directoryContent[indexDirectory].FNAME), [[name uppercaseString] UTF8String], SZ_FILENAME) == 0 && memcmp(&(directoryContent[indexDirectory].FEXT),[[extension uppercaseString] UTF8String], SZ_EXTENSION) == 0 );	
		if(found) {
		
			directoryContent[indexDirectory].FNAME[0] = (unsigned char)ENTRY_DELETED;			
		}
		else {
			indexDirectory++;
		}
	}
	
	if( found ) {
		
		//	If the file is a folder itself, we need to delete all recursively files inside...
		if( directoryContent[indexDirectory].FATTRIB & BIT_DIRECTORY ) {
			
			UInt32 indexFATEntry = startCluster;
			NSMutableArray		*clusters = [[NSMutableArray alloc] init];
			STDirectoryEntry	*localDirectory;
		
			UInt32 countClusters = [self extractClusters:clusters AtFATIndex:indexFATEntry];
			[self assembleClusters:clusters inBuffer:(void **)&localDirectory];
			
			UInt32 countLocalEntries = countClusters * self->bootSector.SPC * [self bootsectorBPS] / sizeof(STDirectoryEntry);		
			UInt32 indexLocalDirectory = 0;	
			NSString	*localName;
			NSString	*localExtension;
			NSLog(@"file is a folder: cleaning its content");
			NSLog(@"SCluster: %d", startCluster);
			NSLog(@"Entries: %d", countLocalEntries);
			while( indexLocalDirectory < countLocalEntries ) {

				if( localDirectory[indexLocalDirectory].FNAME[0] != ENTRY_DELETED && localDirectory[indexLocalDirectory].FNAME[0] != '.' && 
					localDirectory[indexLocalDirectory].FNAME[0] != ENTRY_FREE ) { 
					
					char	filename[9];
					char	fileext[4];
					memset( filename, 0x00, SZ_FILENAME + 1);
					memset( fileext, 0x00, SZ_EXTENSION + 1);
					
					strncpy(filename, localDirectory[indexLocalDirectory].FNAME, SZ_FILENAME );	
					strncpy(fileext, localDirectory[indexLocalDirectory].FEXT, SZ_EXTENSION );	
					
					localName = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
					localExtension = [NSString stringWithCString:fileext encoding:NSASCIIStringEncoding];
			
					if( localDirectory[indexLocalDirectory].FATTRIB & BIT_DIRECTORY ) {
						
						NSLog(@"removing sub-folder: %@\tSCluster:%d", localName, localDirectory[indexLocalDirectory].SCLUSTER);
					}
					else {
						NSLog(@"removing file: %@\tSCluster:%d", localName, localDirectory[indexLocalDirectory].SCLUSTER);
					}
					
					[self removeFileSTImage:localDirectory directorySize:countLocalEntries withName:localName withExtension:localExtension startCluster:localDirectory[indexLocalDirectory].SCLUSTER];
					
				}
				indexDirectory++;
			}
			
			//	FIXME: sould be optional: Save the new content of this directory
			//[self saveBackClusters:clusters fromBuffer:(void *)localDirectory];
			
			FREENULL(localDirectory);
			[clusters release];
		}
		
		//	Freeing all clusters of the file, whatever it was a file or folder
		UInt32	indexNextCluster = [self getFATValueAt:startCluster];
		UInt32	currCluster;
		[self setFATValueAt:startCluster withValue:0x000];
		NSLog(@"release cluster=%d", startCluster);		
		while( indexNextCluster >= 0x002 && indexNextCluster <= 0xFEF ) {
		
			currCluster = indexNextCluster;
			indexNextCluster = [self getFATValueAt:currCluster];
			[self setFATValueAt:currCluster withValue:0x000];
			NSLog(@"release cluster=%lu", indexNextCluster);			
		}				
		code = Ok;
	}
	else {
	
		code = FileNotFound;
	}	
	return code;
}
//---------------------------------------------------------------------------
-(STFloppyError) renameFileSTImage:(STDirectoryEntry *)directoryContent directorySize:(UInt32) directorySize entry:(STDirectoryEntry)directoryEntry withName:(NSString *)name withExtension:(NSString *)extension {
	
	STFloppyError code = Ok;
	bool found = false;							
	UInt32 indexDirectory = 0;	
	while( !found && indexDirectory < directorySize ) {
		
		found = ( memcmp(&(directoryContent[indexDirectory].FNAME), directoryEntry.FNAME, SZ_FILENAME) == 0 && 
				  memcmp(&(directoryContent[indexDirectory].FEXT), directoryEntry.FEXT, SZ_EXTENSION) == 0 );	
		if(found) {
			
			memcpy(&(directoryContent[indexDirectory].FNAME), [[name uppercaseString] UTF8String], SZ_FILENAME);
			memcpy(&(directoryContent[indexDirectory].FEXT), [[extension uppercaseString] UTF8String], SZ_EXTENSION);
			
			//	Update the datetime ?
			UInt8 year, month, day, hour, minute, second;
			[STFloppy decodeDate:[NSDate date] year:&year month:&month day:&day hour:&hour minute:&minute second:&second];
			year -=1980;
			
			//	Update the parent directory which contents the new added file
			directoryContent[indexDirectory].FTIME = (hour << 11) | (minute << 5) | (second / 2);
			directoryContent[indexDirectory].FDATE = (year << 9) | ( month << 5 ) | (day);			
			
			NSLog(@"renaming done");
		}
		indexDirectory++;
	}
	if( found ) {
		code = Ok;
	}
	else {
		
		code = FileNotFound;
	}	
	return code;
}
//---------------------------------------------------------------------------
/**
  Add a new Cluster to the current cluster list of a folder in order to extend
  its capacity.
  
  @param	startCluster, entry in FAT of the clusters list's directory
  
  @returns 	STFloppyError enum
 */
-(STFloppyError) extendFolderSTImage:(UInt32)startCluster {

	STFloppyError code = Ok;
	
	NSLog(@"extendFolderSTImage: Add 1 new cluster");
	
	//	Course the FAT to find the last entry used by the folder
	UInt32	indexNextCluster = [self getFATValueAt:startCluster];
	while( indexNextCluster >= 0x002 && indexNextCluster <= 0xFEF ) {
	
		NSLog(@"Index FAT used: %lu", indexNextCluster);
		//numCluster = indexNextCluster - 2;
		
		//cluster = [[STFloppyCluster alloc] init:[self sizeCluster] withNumber:numCluster];
		//[self readCluster: numCluster clusterBuffer:cluster];				
		//[clusters addObject: (id)cluster];
		
		indexNextCluster = [self getFATValueAt:indexNextCluster];
	}
	NSLog(@"Last Index used: %lu", indexNextCluster);
	
	bool	done = false;

	UInt32 sizeFAT = [self countFATTotalEntries];

	UInt32	lastIndexCluster = indexNextCluster;		//	Keep the last index used
	indexNextCluster++;									//	And go to the next beside
	while( indexNextCluster < sizeFAT && !done) {
	
		//	Entry is available
		if( [self getFATValueAt:indexNextCluster] <= 0x001  ) {
		
			NSLog(@"New Index added: %lu", indexNextCluster);
		
			[self setFATValueAt:lastIndexCluster withValue:indexNextCluster];
			
			void *bufferCluster = malloc( [self sizeCluster] );
			[self writeCluster:indexNextCluster - 2 fromBuffer:bufferCluster size:[self sizeCluster]];
			FREENULL( bufferCluster );
			
			done = true;
		}
		else {
			NSLog(@"Index not available: %lu", indexNextCluster);
			indexNextCluster++;
		}
	}
	if( !done ) {
	
		code = DiskFull;
	}
	return code;
}
//---------------------------------------------------------------------------
/**
  Compute the number of total entries in FAT, included the 2 first FAT entries reserved
   
  @returns 	number of total entries included the 2 reserved
 */
 -(UInt32) countFATTotalEntries {

	UInt32 sizeFATBytes = SWAP_BYTE(self->bootSector.BPS_LOW,self->bootSector.BPS_HIGH) * self->bootSector.SPF;
	UInt32 sizeFAT = sizeFATBytes / sizeof(STFatDouble12) * 2;
	
	return sizeFAT;
}
//---------------------------------------------------------------------------
/**
  Compute the number of free entries in FAT
   
  @returns 	number of free entries
 */
-(UInt32) countFATEntriesFree {

	UInt32	indexFAT = 2;		
	UInt32	countFree = 0;
	UInt32  sizeFAT = [self countFATTotalEntries];
	while( indexFAT < sizeFAT ) {
	
		//	Entry is available
		if( [self getFATValueAt:indexFAT] <= 0x001  ) {
		
			countFree++;
		}
		indexFAT++;
	}
	return countFree;
}
//---------------------------------------------------------------------------

@end
//---------------------------------------------------------------------------


/*
           40 track SS   40 track DS   80 track SS   80 track DS
 0- 1   Branch instruction to boot program if executable
 2- 7   'Loader'
 8-10   24-bit serial number
11-12   BPS    512           512           512           512
13      SPC     1             2             2             2
14-15   RES     1             1             1             1
16      FAT     2             2             2             2
17-18   DIR     64           112           112           112
19-20   SEC    360           720           720          1440
21      MEDIA  $FC           $FD           $F8           $F9  (isn't used by ST-BIOS)
22-23   SPF     2             2             5             5
24-25   SPT     9             9             9             9
26-27   SIDE    1             2             1             2
28-29   HID     0             0             0             0
510-511 CHECKSUM
*/

/*
Atari ST FD Software

Atari Low Level Formatting

The first step in preparing a diskette involves the creation of the actual structures on the surface of the media that are used to hold the data. This means recording the tracks and marking the start of each sector on each track. This is called low-level formatting, and sometimes it is called "true formatting" since it is actually recording the format that will be used to store information on the disk. Once the floppy disk has been low-level formatted, the locations of the tracks and sectors on the disk are fixed in place.
Atari / PC / ISO DD Formats
Atari Standard Double Density Format
Standard 9-10-11 Sectors of 512 Bytes Format
Standards 128-256-512-1024 Bytes / Sector Format
Back to the top
Atari / PC / ISO Formats
The Atari ST uses the Western Digital WD1772 Floppy Disc Controller (FDC) to access the 3 1/2 inch (or to be more precise 90mm) floppy disks. Western Digital was recommending to use the IBM 3740 Format for Single Density diskette and to use the IBM System 34 Format for Double Density diskette. Actually the default Atari Format used by the TOS is slightly different (nearer to the ISO Double Density Format) as it does not have an IAM byte (and associated GAP), before the first IDAM sector of the track (see diagram below). 
However the WD1772 ( and therefore the Atari) is capable to read both format without problem but the reverse is usually not true (i.e. floppies formatted on early Atari machines can't be read on PCs but floppies created on PC can be read on Atari).
IBM System 34 Double Density Format (this is the format produced on a DOS machine formatting in 720K)
 
ISO Double Density Format.
Back to the top
Atari Standard Double Density Format
Below is a detail description of the "Standard Atari Double Density Format" as created by the early TOS.
Note: There is no standard GAPS naming convention and it is not clear on how they must be decomposed. This document uses a GAP naming/numbering scheme which is a combination of the IBM and ISO standards with more details for the description of the GAP between the ID record and the DATA record. Usually only one gap is used to describe the content between these two records but here we decompose it into a post ID gap (Gap 3a) and a pre-data gap (Gap 3b) as this allow a more detail description. Of course they can be easily combined into one Gap 3 which is more conventional. Not show in the diagram below when the floppy is formatted with an IAM (index address mark) the Gap1 is further decomposed into two gaps: A post index gap (Gap1a) and a post IAM gap (Gap1b).
 

 
The tables below indicates the standard values of the different gaps in a "standard" Atari diskette with 9 sectors of 512 user data bytes. It also indicates the minimum acceptable values of these gaps, as specified in the WD1772 datasheet, when formatting non standard diskettes.
 
Name	Standard Values (9 sectors)	Minimum Values (Datasheet)
Gap 1 Post Index	60 x $4E	32 x $4E
Gap 2 Pre ID	12 x $00 + 3 x $A1	8 x 00 + 3 x $A1
Gap 3a Post ID	22 x $4E	22 x $4E
Gap 3b Pre Data	12 x $00 + 3 x $A1	12 x $00 + 3 x $A1
Gap 4 Post Data	40 x $4E	24 x $4E
Gap 5 Pre Index	~ 664 x $4E	16 x $4E
Standard Record Gap Value (Gap 2 + Gap 3a + Gap 3b + Gap 4) = 92 Bytes / Record
Minimum Record Gap Value (Gap 2 + Gap 3a + Gap 3b + Gap 4) = 72 Bytes / Record
Standard Record Length (Record Gap + ID + DATA) = 92 + 7 + 515 = 614 bytes
Minimum Record Length (Record GAP + ID + DATA) = 72 + 7 + 515 = 594
Back to the top
Standard 9-10-11 Sectors of 512 Bytes Format
Note that the 3 1/2 FD are spinning at 300 RPM which implies a 200 ms total track time. As the MFM cells have a length of 4 µsec this gives a total of 50000 cells and therefore about 6250 bytes per track.
The table below indicates possible (i.e. classical) values of the gaps for tracks with 9, 10, and 11 sectors.
Name	9 Sectors: # bytes	10 Sectors: # bytes	11 Sectors: # bytes
Gap 1 Post Index	60	60	10
Gap 2 Pre ID	12+3	12+3	3+3
Gap 3a Post ID	22	22	22
Gap 3b Pre Data	12+3	12+3	12+3
Gap 4 Post Data	40	40	1
Gap 2-4	92	92	44
Record Length	614	614	566
Gap 5 Pre Index	664	50	20
Total Track	6250	6250	6250
Respecting all the minimum value on an 11 sectors / track gives a length of: L = Min Gap 1 + (11 x Min Record Length) + Min Gap 5 = 32 + 6534 + 16 = 6582 (which is 332 bytes above max track length). Therefore we need to decrease by about 32 bytes per sector in order to be able to write such a track. For example the last column of the table above shows values as used by Superformat v2.2 program for 11 sectors/track (values analyzed with a Discovery Cartridge). As you can see the track is formatted with a Gap 2 reduced to 6 and Gap 4 reduced to 1 !
These values do not respect the minimum specified by the WD1772 datasheet but they make sense as it is mandatory to let enough time to the FDC between the ID block and the corresponding DATA block which implies that Gap 3a & 3b should not be shorten.  The reduction of gap 4 plus gap 2 to only 7 bytes between a DATA block and the next ID block does not let enough time to the FDC to read the next sector on the fly but this is acceptable as this sector can be read on the next rotation of the FD. This has an obviously impact on performance that can be minimized by using sectors interleaving (explain below). But it is somewhat dangerous to have such a short gap between the data and the next ID because the writing of a data block need to be perfectly calibrated or it will collide with the next ID block. This is why such a track is actually reported as "read only" in the DC documentation and is sometimes used as a protection mechanism.
Of course you have more chance to successfully write 11 sectors on the first track (the outer one) than on the last track (the inner one) as the bit density gets higher in the later case. It is also important to have a floppy drive that have a stable and minimum rotation speed deviation (i.e. RPM should not be more than 1% above 300).
Back to the top
Standard 128-256-512-1024 Bytes / Sector Format
The table below indicates some "classical" gaps values for tracks with sectors of size of 128, 256, 512, and 1024.
Name	29 sectors of 128 bytes	18 sectors of 256 bytes	9 Sectors of 512 bytes	5 Sectors of 1024 bytes
Gap 1 Post Index	40	42	60	60
Gap 2 Pre ID	10+3	11+3	12+3	40+3
Gap 3a Post ID	22	22	22	22
Gap 3b Pre Data	12+3	12+3	12+3	12+3
Gap 4 Post Data	25	26	40	40
Gap 2-4	75	77	92	120
Record Length	213	343	614	1154
Gap 5	73	76	664	480
Total Track	6250	6250	6250	6250
Interleaving: Normally the sector number is incremented by 1 for each record (i.e. there is no need to interleave with DD like it used to be with older FD) however sectors can written be in any order.
Back to the top
Overall Track / Sector Description
Track Description

Back to the top
Sector ID Segment

 
ID PREAMBLE
PLL SYNCH FIELD
This is a 12 bytes long field of repetitive clocked data bits. The preamble normally will be all zeroes of NRZ data (encoded as 1010. . . in MFM). During the ID preamble, the signal Read Gate will go active, indicating that the incoming data pattern has to be locked on to.
ID SYNCH FIELD 
The synch mark byte contains a missing clock code violation, typically in MFM. The violation is detected by circuitry to indicate the start of an ID Field or a Data Field. The first decoded byte that does not contain all 0s after the preamble will be the synch mark. The first 1 to be received is then used to byte align after the all zeroes preamble. The DD format have three ID synch mark byte. On soft sectored drives Synch field precedes the address mark (AM).
ID FIELD
ID ADDRESS MARK FIELD
ID Address Mark (IDAM) is required on soft sectored drives to indicate the beginning of a sector, because this type of drive does not have a sector pulse at the start of each sector.
ID content Field 
The ID content Field format contains a track number bytes, a sector number byte, a head number byte. It is 4 bytes long.
ID CRC FIELD
CRC (Cyclic Redundancy Checking) code is appended to the header field. The CRC consists of two bytes of the standard CRC-CCITT polynomial. The code detects errors in the header field. This appendage is basically a protection field to make sure that the ID field contains valid information.
ID POSTAMBLE
This field is used to give the disk controller time to interpret the data found in the ID field and to act upon it. It provides slack for write splicing that occurs between the ID and Data segment. A Write splice occurs when the read/ write head starts writing the data field. A splice is created each time a sector's data segment is written to. The slight variations in the rotational speeds cause the first flux change to occur in different positions for each write operation. It also allows time in a write disk operation for the read/write circuitry to be switched from read to write mode. Finally it allows time for the PLL circuit to re-lock on to a fixed reference clock before it returns to synchronize to the preamble of the data field.
Back to the top
Sector DATA Segment

 
Data PREAMBLE FIELD
PLL Synch Field 
The Data Preamble field is necessary when reading a sector's data. It ensures that the PLL circuit locks on to the Data segment data rate. Initially, the ID segment and the data segment of every sector will be written when formatting the disk, but the Data segment will be written over later. Due to drive motor speed variations within the tolerance specified, the ID and Data segments will have slightly different data rates because they are written at different times. This implies that the PLL must adjust its frequency and phase in order to lock on to the data rate of the Data segment before the incoming preamble field has finished. Hence the need for a second preamble field in the sector.
DATA SYNCH FIELD 
Following the PLL Synch Field will be the Data synch field similar to the ID synch field.
DATA FIELD
Data Address Mark field
Following the Data Preamble will be the Data Address Mark for soft sectored drives similar to the ID Address Mark field.
Data Content Field
The Data field is transferred to or from external memory. It is usually from 128 bytes to 1024 bytes per sector.
DATA CRC
A CRC appendage follows the Data field. CRC generating (when writing to the disk) and checking (when reading from the disk) are performed on the Data field. Errors may therefore be detected.
DATA POSTAMBLE FIELD 
This has the same function as the ID Postamble field. It is the final field of the sector. It allows slack between neighboring sectors. Without this gap, whenever a data segment is written to a sector, any reduction in drive motor speed at the instance of writing to the disk would cause an overlap of the data segment and the succeeding ID segment of the next sector. This field is only written when formatting the disk.
Note 1: A final gap field is added from the end of the last sector until the INDEX pulse occurs and this gap is often termed Gap 5. It takes up the slack from the end of the last sector to the Index pulse.
Note 2: When writing a sector the write gate is tunrned on at the begining of the DATA preamble (location of the write splicing) and is turned off in the data postamble (one or two bytes after the last CRC).
Back to the top
Sector Write Splice
The area at the begining of the DATA preamble provides slack for write splicing that occurs between the ID and Data segment. A Write splice occurs when the read/ write head starts writing the data field. A splice is created each time a sector's data segment is written to. The slight variations in the rotational speeds cause the first flux change to occur in different positions for each write operation. It also allows time in a write disk operation for the read/write circuitry to be switched from read to write mode.
Back to the top
Track Write Splice
A Track write splice occurs when writing a complete track. When you write a whole track, you start writing bytes at the index mark for 200ms. The problem is that floppy drives do not run exactly at 300 rpm all the time, so there's pretty much no chance you'll get an exact joining once you've done a complete revolution. So you'll either have some leftover noise just before your starting point, or some overwriting there.
Back to the top
Atari High-Level Formating
Getting a Floppy Disk Ready
The Boot Sector
Directory Structure
FAT Structure
Getting a floppy disk ready
There are two steps involved in getting a floppy disks ready for usage on an Atari:
As already described in this section the first step involves the creation of the actual structures on the surface of the media that are used to hold the data ans is called the Low_Level formatting.
The second step is called the high-level formatting. This is the process of creating the disk's logical structures such as the file allocation table and root directory. The high-level format uses the structures created by the low-level format to prepare the disk to hold files using the chosen file system. In order for the TOS to use a diskette it has to know about the number of tracks, the number of sectors per tracks, the size of the sectors and the number of sides. This information is defined in a special sector called the boot sector. Beyond that it is necessary for the TOS  to find information (e.g. location of all the sectors belonging to this file, attributes, ...) about any files stored on the diskette as well as global information (e.g. the space still available on the diskette). This information is kept in directories and FATs structures.
Back to the top

The Boot Sector (BS)
====================

The boot sector is always located on track 0, side 0, first sector of the diskette. This sector is tested by the TOS  as soon as you change of diskette to find important information about the diskette (e.g. it contains a serial number that identify the diskette). Some parameters are loaded from this sector to be used by the BIOS and are stored in a structure called the BPB (Bios Parameter Block). Eventually the boot sector also contain a bootstrap routine (the loader) that allow to start a relocatable program a boot time (usually a TOS image).
The structure of the boot sector is described below (the grayed areas are stored in the BPB). Note that the Atari boot sector is similar with the boot sector used by IBM PC and therefore 16 bits words are stored using the low/high bytes Intel format  (e.g. a BPS = $00 $02 indicates a $200 bytes per sector).
Name	Offset	Bytes	Contents
BRA			$00		2	This word contains a 680x0 BRA.S instruction to the bootstrap code in this sector if the disk is executable, otherwise it is unused.
OEM			$02		6	These six bytes are reserved for use as any necessary filler information. The disk-based TOS loader program places the string 'Loader' here.
SERIAL		$08		4	The low 24-bits of this long represent a unique disk serial number.
BPS			$0B		2	This is an Intel format word (low byte first) which indicates the number of bytes per sector on the disk (usually 512).
SPC			$0D		1	This is a byte which indicates the number of sectors per cluster on the disk. Must be a power of 2 (usually 2)
RESSEC		$0E		2	This is an Intel format word which indicates the number of reserved sectors at the beginning of the media preceding the start of the first FAT, including the boot sector itself. It is usually one for floppies.
NFATS		$10		1	This is a byte indicating the number of File Allocation Table's (FAT's) stored on the disk. Usually the value is two as one extra copy of the FAT is kept to recover data if the first FAT gets corrupted.
NDIRS		$11		2	This is an Intel format word indicating the total number of file name entries that can be stored in the root directory of the volume.
NSECTS		$13		2	This is an Intel format word indicating the number of sectors on the disk (including those reserved).
MEDIA		$15		1	This byte is the media descriptor. For hard disks this value is set to 0xF8, otherwise it is unused on Atari.
SPF			$16		2	This is an Intel format word indicating the number of sectors occupied by each of the FATs on the volume. Given this information, together with the number of FATs and reserved sectors listed above, we can compute where the root directory begins. Given the number of entries in the root directory, we can also compute where the user data area of the disk begins.
SPT			$18		2	This is an Intel format word indicating the number of sectors per track (usually 9)
NHEADS		$1A		2	This is an Intel format word indicating the number of heads on the disk. For a single side diskette the value is 1 and for a double sided diskette the value is  2.
NHID		$1C		2	This is an Intel format word indicating the number of hidden sectors on a disk (not used by Atari).
EXECFLAG	$1E		2	This is  a word which is loaded in the cmdload system variable. This flag is used to find out if the command.prg program has to be started after loading the OS.
LDMODE		$20		2	This is  a word indicating the load mode. If this flag equal zero the file specified by the FNAME field is located and loaded (usually the file is TOS.IMG). If the flag is not equal to zero the sectors as specified by SECTCNT and SSSECT variables are loaded.
SSECT		$22		2	This is  an Intel format word indicating the logical sector from where we boot. This variable is only used if LDMODE is not equal to zero
SECTCNT		$24		2	This is  an Intel format word indicating the number of sectors to load for the boot. This variable is only used if LDMODE is not equal to zero
LDAADDR		$26		2	This is  an Intel format word indicating the memory address where the boot program will be loaded.
FATBUF		$2A		2	This is  an Intel format word indicating the address where the FAT and catalog sectors must be loaded
FNAME		$2E		11	This is the name of an image file that must be loaded when LDMODE equal zero. It has exactly the same structure as a normal file name, that is 8 characters for the name and 3 characters for the extension.
RESERVED	$39		2	Reserved
BOOTIT		$3A		452	Boot program that can eventually be loaded after loading of the boot sector.
CHECKSUM	$1FE	2	The entire boot sector word summed with this Motorola format word will equal 0x1234 if the boot sector is executable or some other value if not.

The data beginning at offset $1E (colored in yellow) are only used for a bootable diskette. To recognize that a diskette is bootable the boot sector must contain the text "Loader" starting at the third bytes and the sum of the entire boot sector should be equal to $1234.
The boot process is usually done in 4 stages:
The boot sector is loaded and the boot program contained is executed.
The FAT and the catalog are loaded from the diskette and the loader search for the file name indicated
The program image is loaded usually starting with address $40000
The loaded program is executed from the beginning.
See also some Boot sector code.

Directory Structure
===================

The TOS arranges and stores file-system contents in directories. Every file system has at least one directory, called the root directory 
(also referred as the catalog in Atari), and may have additional directories either in the root directory or ordered hierarchically below it. 
The contents of each directory are described in individual directory entries. The TOS strictly controls the format and content of directories.
The root directory is always the topmost directory. The TOS creates the root directory when it formats the storage medium ( high level formatting). 
The root directory can hold information for only a fixed number of files or other directories, and the number cannot be changed without reformatting the medium. 
A program can identify this limit by examining the NDIRS field in the BPB structure described in the boot sector section. This field specifies the maximum 
number of root-directory entries for the medium.
A user or a program program can add new directories within the current directory, or within other directories. Unlike the root directory, 
the new directory is limited only by the amount of space available on the medium, not by a fixed number of entries. 
The TOS initially allocates only a single cluster for the directory, allocating additional clusters only when they are needed. 
Every directory except the root directory has two entries when it is created. The first entry specifies the directory itself, and the second entry specifies 
its parent directoryóthe directory that contains it. These entries use the special directory names ". "(an ASCII period) and ".." (two ASCII periods), 
respectively.
The TOS gives programs access to files in the file system. Programs can read from and write to existing files, as well as create new ones. 
Files can contain any amount of data, up to the limits of the storage medium. Apart from its contents, every file has a name (possibly with an extension), 
access attributes, and an associated date and time. This information is stored in the file's directory entry, not in the file itself.

The root directory is located just after the FATs (i.e. on a single sided FD: side 0, track 1, sector 3 and on DS DF side 1, track 0, sector 3) and 
is composed of 7 sectors. Each entry in the root directory can be describe by the following structure:

Name	Bytes	Contents

FNAME	8	Specifies the name of the file or directory. If the file or directory was created by using a name with fewer than eight characters, space characters (ASCII $20) fill the remaining bytes in the field. The first byte in the field can be a character or one of the following values:
			$00 The directory entry has never been used. The TOS uses this value to limit the length of directory searches.
			$05 The first character in the name has the value 0E5h.
			$2E The directory entry is an alias for this directory or the parent directory. If the remaining bytes are space characters (ASCII 20h), the SCLUSTER field contains the starting cluster for this directory. If the second byte is also 2Eh (and the remaining bytes are space characters), SCLUSTER contains the starting cluster number of the parent directory, or zero if the parent is the root directory.
			E5h The file or directory has been deleted.
FEXT	3	Specifies the file or directory extension. If the extension has fewer than three characters, space characters (ASCII $20) fill the remaining bytes in this field.
ATTRIB	1	Specifies the attributes of the file or directory. This field can contain some combination of the following values:
			$01 Specifies a read-only file.
			$02 Specifies a hidden file or directory.
			$04 Specifies a system file or directory.
			$08 Specifies a volume label. The directory entry contains no other usable information (except for date and time of creation) and can occur only in the root directory.
			$10 Specifies a directory.
			$20 Specifies a file that is new or has been modified.
			All other values are reserved. (The two high-order bits are set to zero.) If no attributes are set, the file is a normal file.
RES		10	Reserved; do not use.
FTIME	2	Specifies the time the file or directory was created or last updated. The field has the following form:
			bits 0-4 Specifies two-second intervals. Can be a value in the range 0 through 29.
			bits 5-10 Specifies minutes. Can be a value in the range 0 through 59.
			bits 11-15 Specifies hours. Can be a value in the range 0 through 23.
FDATE	2	Specifies the date the file or directory was created or last updated. The field has the following form:
			bits 0-4 Specifies the day. Can be a value in the range 1 through 31.
			bits 5-8 Specifies the month. Can be a value in the range 1 through 12.
			bits 9-15 Specifies the year, relative to 1980.
SCLUSTER	2	Specifies the starting cluster of the file or directory (index into the FAT)
FSIZE	4	Specifies the maximum size of the file, in bytes.


FAT Structure
=============

The file allocation table (FAT) is an array used by the TOS to keep track of which clusters on a drive have been allocated for each file or directory. 
As a program creates a new file or adds to an existing one, the system allocates sectors for that file, writes the data to the given sectors, 
and keeps track of the allocated sectors by recording them in the FAT. To conserve space and speed up record-keeping, each record in the FAT corresponds 
to two or more consecutive sectors (called a cluster). The number of sectors in a cluster depends on the type and capacity of the drive but is always a power of 2. 
Every logical drive has at least one FAT, and most drives have two, one serving as a backup should the other fail. The FAT immediately follows the boot sector 
and any other reserved sectors.
Depending on the number of clusters on the drive, the FAT consists of an array of either 12-bit or 16-bit entries. Drives with more than 4086 clusters 
have a 16-bit FAT; those with 4086 or fewer clusters have a 12-bit FAT. As Atari diskette has always less than 4086 clusters the FATs on Atari diskettes 
are always 12-bit FATs.
The first two entries in a FAT (3 bytes for a 12-bit FAT) are reserved. In most cases the first byte contains the media descriptor (usually $F9F) and 
the additional reserved bytes are set to $FFF. Each FAT entry represents a corresponding cluster on the drive. If the cluster is part of a file or directory, 
the entry contains either a marker specifying the cluster as the last in that file or directory, or an index pointing to the next cluster in the file or directory. 
If a cluster is not part of a file or directory, the entry contains a value indicating the cluster's status.

The following table shows possible FAT entry values:

Value		Meaning
$000		Available cluster.
$002-$FEF	Index of entry for the next cluster in the file or directory. Note that $001 does not appear in a FAT, since that value corresponds to the FAT's second reserved entry. Index numbering is based on the beginning of the FAT
$FF0-$FF6	Reserved
$FF7		Bad sector in cluster; do not use cluster.
$FF8-$FFF	Last cluster of file or directory. (usually the value $FFF is used)

Each file and directory consists of one or more clusters, each cluster represented by a single entry in the FAT. 
The SCLUSTER field in the directories structure corresponding to the file or directory specifies the index of the first FAT entry for the file or directory. 
This entry contains $FFF if there are no further FAT entries for that file or directory, or it contains the index of the next FAT entry for the file or directory. 
For example, the following segment of a 12-bit FAT shows the FAT entries for a file consisting of four clusters:

 $003 Cluster 2 points to cluster 3
 $005 Cluster 3 points to cluster 5
 $FF7 Cluster 4 contains a bad sector
 $006 Cluster 5 points to cluster 6
 $FFF Cluster 6 is the last cluster for the file
 $000 Clusters 7 is available
 ...
Note that if a cluster contains $000 it does not mean that it is empty but that it is available. This is due to the fact that when a file is deleted the data are not erased but only the first letter of the name of the file in the directory structure is set to $E5 and all clusters used by the deleted file are set to $000.
Back to the top
Atari Floppy Disk Images
Disk Image Formats
Format Supported by Emulators
Making disk images from FDs
Making FDs from disk images
Disk Image Utilities
This section is also related to the Atari FD Preservation section.
Disk Image formats
Disk images are usually used by SW or HW emulators. There are a lot of sites dedicated to the subject of Atari SW emulation and I will therefore point you to a list of links on the subject. For example Emulateurs & TOS (in French!).
The most famous and still maintained Atari Emulators running on PC are Hatari, Steem, and Saint. In order to run an emulator you need a TOS ROM also not covered here. There is also the HxC2001 Universal FD Drive Emulator that can be used on real Atari.
The major disk image formats used by the Atari emulators are:
ST : Supported by all emulators, it is the most simple format since itís a straight copy of the readable data of a disk. Created originally for the PacifiST emulator, it does not allow copying copy-protected disks.
MSA : An acronym for Magic Shadow Archiver, it is a format created on Atari by the compression program of the same name. This format, is also supported by almost all emulators. It contains the same data as the ST format, the only difference is that the data is compressed. A variation of the program on Atari allows saving the data without any compression. This result in an ST file but with an MSA header. A nice feature of the MSA program is that it allows to split an archive into multiple files, thus facilitating the transfer of large disk images on floppies.
DIM : A format created by the well known Atari copy program: "FastCopy Pro". The non-compressed version of this format contains the same information as the ST and MSA formats, but with a proprietary header. This format is also supported by most emulators.
STT : Created and developed by the creators of STeem Engine emulator, it is supposed to allow the copy of many original disks, including certain copy-protected games. It supports disks of various numbers of tracks that can be of different size as well as other details. For example it supports irregular sector numbers, sector numbers in range $F7-FF and 1 KB sectors.
STX: Created by the PASTI initiative (Atari ST Imaging & Preservation Tools). The imaging tools can virtually create images of any ST disk including copy protected disks. The STX Images can be used by the STeem and SainT emulators. There is also a plan to support it in the Hatari Emulator. Unfortunately Ijor has not published information on the STX format. However you can find information here, here, and here (you have to look into the source code).
IPF: Created by the Software Preservation Society (SPS). -- The provided DCT imaging tool can create images of any ST disk including copy protected disks. This format is "new" to the Atari scene and support in emulators is not yet available.
Note also that most recent emulators like STeem can directly read zipped disk images. For example STeem or Hatari can mount directly a zipped file (.zip) that contains a disk image of any of the supported disk image format.
Formats supported by Emulators

The following table summurize the supported formats for each emulators:
 
		ST	MSA	DIM	STT	STX	IPF
Hatari	Yes	Yes	Yes	 	 	 
Steem	Yes	Yes	Yes	Yes	Yes	 
Saint	Yes	Yes	Yes	 	Yes	 
USB HxC	Yes	Yes	Yes	Yes	Yes	Yes
SD HxC	Yes	Yes	Yes	Yes	No VBR	No VBR
 
Back to the top
Making Disk Images from ST Original Floppies
This section try to answer the question: I have Atari floppies that I want to use with my favorite emulator...
 Making ST Disk Images (Only on a PC):
To make ST images on a Windows system the best solution is to use the Floppy Imaging & File transfer (FloImg) program from P. Putnik.You can also use Makedisk (DOS), imgbuild (DOS), wfdcopy (Windows 95/98 you will have problem on XP/7). Instruction can be found at Mr Nours site. I have tested these three program successfully on simples non protected FD without problem. Although it should be possible to use the gemulator explorer to create disk images but it did not worked for me.
 Making MSA Images (On PC and Atari ST):
To make MSA images on a Windows system the best solution is to use the Floppy Imaging & File transfer (FloImg) program from P. Putnik. On Atari I have made the tests with MSA II - V2.3. The process is straightforward : start the program specify the name and directory for the image, indicate if you want the file to be compressed or not and click the "Disk -> File" button ... and you are done. You should use compressed mode to get smaller disk images.
 Making DIM Disk Image (On Atari ST):
First you need the FastCopy Pro version (version "no version", or 1.0 or 1.2 did work for me). Important if you are using the version "without version" number you must first select the "all" option from the get sectors choice, in V1.0 and 1.2 this choice is unavailable (always pre-selected to all). After that you need to click on the "image copy" button, then select the "read" button and enter the name of the file you want to create... This file should be directly readable by the emulators.
 Making STT Disk Images (On PC or Atari ST):
To make STT images on a Windows system the best solution is to use the Floppy Imaging & File transfer (FloImg) program from P. Putnik. On Atari use the STeem Disk Imager that comes with STeem itself. Instructions are provided in the disk image howto.txt file. The STT image can be mounted by STeem only.
 Making STX Disk Images of copy protected disk (On Atari ST):
Instruction on making STX images can be found in the Alone in the paST AitpaST site.
Making IPF Disk Image of copy protected disk -- TODO
Back to the top
Making ST Floppies from Disk Image files
This section try to answer the question: I have some interesting disk images that I would like to run from a FD on my real Atari...
 Making a floppy disk from a ST image (Only on PC):
On a Windows system the best solution is to use the Floppy Imaging & File transfer (FloImg) program from P. Putnik to write ST images on an actual FD. You can also use makedisk (DOS), or ST Disk (DOS), or wfdcopy (Windows 95/98 you will have problem on XP/7). Instruction can be found at the Mr Nours site.
 Making a floppy disk from a MSA image (On PC or Atari ST):
On a Windows system the best solution is to use the Floppy Imaging & File transfer (FloImg) program from P. Putnik to write ST images on an actual FD. I have made the tests with MSA II - V2.3. The process is straightforward : start the program specify the name and directory of the image, click the "File -> Disk" button ... and you should have your disk ready.
 Making a floppy disk from a DIM image (On Atari ST):
First you need the FastCopy Pro version (version "no version", or 1.0 or 1.2). you need to click on the "image copy" button, then select the "Restore" button and enter the name of the image file...
 Making a floppy disk from a STT image (on PC or Atari ST):
This is only possible if no protection or specific protections have been used. Your best choice is to use the Floppy Imaging & File transfer (FloImg) program from P. Putnik. In some cases (when no protection are used) it is possible to first convert the STT image to an ST or MSA image using the MSA converter program, and from this converted image use one of the procedure described above.
 Making a floppy disk from a STX image:
It is not yet possible to create a protected disk from an STX image. The reason is that protected disk uses specific data that cannot be written directly by the Atari FD controller. Might be possible in future with the "Discovery Cartridge" or the KryoFlux Board.
 Making a floppy disk from a IPF image:
TODO - see the KryoFlux Project and the KryoFlux Board
Back to the top
Other PC Disk image utilities
As already mentioned above, if you deal with disk images there is one program you must have: the Floppy Imaging & File transfer program (FloImg) from P. Putnik. This program can be used to create images in ST / MSA / STT format directly from a ST floppy placed in the PC Floppy Drive. It is also possible to create FD directly from images. It also support ST <-> to MSA conversion.
Another must have program is the MSA converter that run under Windows. This program not only allow conversion between different image formats but it also gives useful information about the image content.
For information there are some older programs that run under DOS for st to msa conversion or from msa to st conversion. As well as two DOS programs to convert a PC disk to/from an ST disk.
Links
Disk Image from Wikipedia
 
Back to the top
Copyright and Fair Use Notice
This site contains copyrighted material the use of which has not always been specifically authorized by the copyright owner. We are making such material available in our efforts to help in the understanding of the Atari Computers. We believe this constitutes a 'fair use' of any such copyrighted material. The material on this site is accessible without profit and is presented here with the only goal to disseminate knowledge about Atari computers. Consistent with this notice you are welcome to make 'fair use' of anything you find on this web site. However, all persons reproducing, redistributing, or making commercial use of this information are expected to adhere to the terms and conditions asserted by the copyright holder. Transmission or reproduction of protected items beyond that allowed by fair use notice as defined in the copyright laws requires the permission of the copyright owners.
© Info-Coach - DrCoolZic (Jean Louis-GuÈrin)
*/
