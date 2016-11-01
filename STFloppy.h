//
//  STFloppy.h
//
//  Created by Laurent on 02/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>
//#import "NodeFile.h"

typedef enum tagFloppySize { kSingleSide = 0, kDoubleSide = 1, kHighDensity = 2, kExtendDensity = 3 } STFloppySize;
typedef enum tagDiskError { Ok = 0, 
							ParentError = 1, 
							DiskFull = 2, 
							DuplicateName = 3, 
							DirectoryFull = 4,
							FileNotFound = 5,
							NoDisk = 6} STFloppyError;

#define	BIT_VOLUMENAME	0x08
#define	BIT_DIRECTORY	0x10
#define	BIT_FILE		0x20
#define	ENTRY_DELETED	(char)0xE5
#define	ENTRY_FREE		(char)0x00
#define	CLUSTER_DELETED	0x000

//	Many int are not aligned in the bootsector structure. I don't use Pragma Pack but i will resort in the code the low/high word.
//#pragma pack(push)
//#pragma pack(1)
typedef struct	{
					UInt16				BRA;			//$00		2	This word contains a 680x0 BRA.S instruction to the bootstrap code in this sector if the disk is executable, otherwise it is unused.
					char				OEM[6];			//$02		6	These six bytes are reserved for use as any necessary filler information. The disk-based TOS loader program places the string 'Loader' here.
					UInt8				SERIAL[3];		//$08		4	The low 24-bits of this long represent a unique disk serial number.
					UInt8				BPS_LOW;		//$0B		2	This is an Intel format word (low byte first) which indicates the number of bytes per sector on the disk (usually 512).
					UInt8				BPS_HIGH;		//
					UInt8				SPC;			//$0D		1	This is a byte which indicates the number of sectors per cluster on the disk. Must be a power of 2 (usually 2)
					UInt16				RESSEC;			//$0E		2	This is an Intel format word which indicates the number of reserved sectors at the beginning of the media preceding the start of the first FA
					UInt8				NFATS;			//$10		1	This is a byte indicating the number of File Allocation Table's (FAT's) stored on the disk. Usually the value is two as one extra copy of the
					UInt8				NDIRS_LOW;		//$11		2	This is an Intel format word indicating the total number of file name entries that can be stored in the root directory of the volume.
					UInt8				NDIRS_HIGH;		//
					UInt8				NSECTS_LOW;		//$13		2	This is an Intel format word indicating the number of sectors on the disk (including those reserved).
					UInt8				NSECTS_HIGH;	//
					UInt8				MEDIA;			//$15		1	This byte is the media descriptor. For hard disks this value is set to 0xF8, otherwise it is unused on Atari.
					UInt16				SPF;			//$16		2	This is an Intel format word indicating the number of sectors occupied by each of the FATs on the volume. Given this information, together wi
					UInt16				SPT;			//$18		2	This is an Intel format word indicating the number of sectors per track (usually 9)
					UInt16				NHEADS;			//$1A		2	This is an Intel format word indicating the number of heads on the disk. For a single side diskette the value is 1 and for a double sided dis
					UInt16				NHID;			//$1C		2	This is an Intel format word indicating the number of hidden sectors on a disk (not used by Atari).
					UInt16				EXECFLAG;		//$1E		2	This is  a word which is loaded in the cmdload system variable. This flag is used to find out if the command.prg program has to be started after 
					UInt16				LDMODE;			//$20		2	This is  a word indicating the load mode. If this flag equal zero the file specified by the FNAME field is located and loaded (usually the fi
					UInt16				SSECT;			//$22		2	This is  an Intel format word indicating the logical sector from where we boot. This variable is only used if LDMODE is not equal to zero
					UInt16				SECTCNT;		//$24		2	This is  an Intel format word indicating the number of sectors to load for the boot. This variable is only used if LDMODE is not equal to zer
					UInt16				LDAADDR;		//$26		2	This is  an Intel format word indicating the memory address where the boot program will be loaded.
					UInt16				FATBUF;			//$2A		2	This is  an Intel format word indicating the address where the FAT and catalog sectors must be loaded
					char				FNAME[11];		//$2E		11	This is the name of an image file that must be loaded when LDMODE equal zero. It has exactly the same structure as a normal file name, that i
					UInt8				RESERVED_LOW;	//$39		2	Reserved
					UInt8				RESERVED_HIGH;	//			2	Reserved
					unsigned char		BOOTIT[452];	//$3A		452	Boot program that can eventually be loaded after loading of the boot sector.
					UInt16				CHECKSUM;		//$1FE		2	The entire boot sector word summed with this Motorola format word will equal 0x1234 if the boot sector is executable or some other value if not.		
				} /*__attribute__ ((aligned (1)))*/ STBootSector;
//#pragma pack(pop)

typedef struct	{
					char				FNAME[8];		//8		Specifies the name of the file or directory. If the file or directory was created by using a name with fewer than eight characters, space characters (ASCII $20) fill the remaining bytes in the field. The first byte in the field can be a character or one of the following values:
														//$00 	The directory entry has never been used. The TOS uses this value to limit the length of directory searches.
														//$05 	The first character in the name has the value 0E5h.
														//$2E 	The directory entry is an alias for this directory or the parent directory. If the remaining bytes are space characters (ASCII 20h), the SCLUSTER field contains the starting cluster for this directory. If the second byte is also 2Eh (and the remaining bytes are space characters), SCLUSTER contains the starting cluster number of the parent directory, or zero if the parent is the root directory.
														//E5h 	The file or directory has been deleted.
					char				FEXT[3];		//3		Specifies the file or directory extension. If the extension has fewer than three characters, space characters (ASCII $20) fill the remaining bytes in this field.
					UInt8				FATTRIB;		//1		Specifies the attributes of the file or directory. This field can contain some combination of the following values:
																	//$01 Specifies a read-only file.
																	//$02 Specifies a hidden file or directory.
																	//$04 Specifies a system file or directory.
																	//$08 Specifies a volume label. The directory entry contains no other usable information (except for date and time of creation) and can occur only in the root directory.
																	//$10 Specifies a directory.
																	//$20 Specifies a file that is new or has been modified.
																	//All other values are reserved. (The two high-order bits are set to zero.) If no attributes are set, the file is a normal file.
					UInt8				RES[10];		//10	Reserved; do not use.
					UInt16				FTIME;			//2		Specifies the time the file or directory was created or last updated. The field has the following form:
																	//bits 0-4 Specifies two-second intervals. Can be a value in the range 0 through 29.
																	//bits 5-10 Specifies minutes. Can be a value in the range 0 through 59.
																	//bits 11-15 Specifies hours. Can be a value in the range 0 through 23.
					UInt16				FDATE;			//2		Specifies the date the file or directory was created or last updated. The field has the following form:
																	//bits 0-4 Specifies the day. Can be a value in the range 1 through 31.
																	//bits 5-8 Specifies the month. Can be a value in the range 1 through 12.
																	//bits 9-15 Specifies the year, relative to 1980.
					UInt16				SCLUSTER;		//2		Specifies the starting cluster of the file or directory (index into the FAT)
					UInt32				FSIZE;			//4		Specifies the maximum size of the file, in bytes.
				} STDirectoryEntry;
				
//	Represent an double 12 bits entries in the FAT
typedef struct	{
					UInt8				clusterNmber[3];
				} STFatDouble12;

@interface STFloppy : NSObject {

	@protected
	
		bool				diskLoaded;

		NSMutableData		*diskBuffer;					//	raw bytes of full disk image content
		
		STBootSector		bootSector;						//	Copy of the bootsector
		STFatDouble12		*firstFat12;						//	Copy of the first FAT
		STFatDouble12		*secondFat12;					//	Copy of the second FAT
		STDirectoryEntry	*rootDirectory;					//	Copy of the root directory
		
		UInt32				countFATEntries;
		NSString			*volumeName;
		UInt32				indexFreeSpace;
}

@property(nonatomic,readwrite)			bool				diskLoaded;
@property(nonatomic,retain,readwrite)	NSString			*volumeName;
@property(nonatomic,readwrite)			STBootSector		bootSector;
@property(nonatomic,readwrite)			STFatDouble12		*firstFat12;
@property(nonatomic,readwrite)			STFatDouble12		*secondFat12;
@property(nonatomic,readwrite)			STDirectoryEntry	*rootDirectory;
@property(nonatomic,readwrite)			UInt32				countFATEntries;

- (id)				init;

- (void)			cleanup;

- (UInt16) 			bootsectorBPS;
- (UInt16) 			bootsectorNDIRS;
- (UInt16) 			bootsectorNSECTS;
- (NSString *) 		bootsectorOEM;

- (UInt32)			volumeSize;

- (UInt32) 			countFATTotalEntries;
- (UInt32) 			countFATEntriesFree;

- (UInt32)			extractClusters:(NSMutableArray *)clusters AtFATIndex:(UInt32) indexFATEntry;
- (void)			assembleClusters:(NSMutableArray *)clusters inBuffer:(void **)buffer;

- (void)			commitDisk;
- (void)			rollbackDisk;
- (void)			saveBackClusters:(NSMutableArray *)clusters fromBuffer:(void *)buffer;
- (STFloppyError)	extendFolderSTImage:(UInt32)startCluster;

+ (bool)			createSTImage:(int)nTracks withSectors:(int)sectors withSides:(int)sides inBuffer:(NSData **)floppyBuffer withName:(NSString *)diskName withExtension:(NSString *)diskExtension;
- (bool)			readSTImage:(NSString *)filename;
- (bool)			extractFileSTImage:(UInt32)startCluster size:(UInt32)sizeBytes inBuffer:(NSData **)fileMemory;
- (STFloppyError)	addFileSTImage:(STDirectoryEntry *) directoryContent directorySize:(UInt32) directorySize withData:(NSData *)fileData withName:(NSString *)filename withExtension:(NSString *)extension;
- (STFloppyError) 	removeFileSTImage:(STDirectoryEntry *)directoryContent directorySize:(UInt32) directorySize withName:(NSString *)name withExtension:(NSString *)extension startCluster:(UInt32)startCluster;
- (STFloppyError)	addFolderSTImage:(STDirectoryEntry *)directoryContent directorySize:(UInt32) directorySize parentStartCluster:(UInt32)parentStartCluster withName:(NSString *)filename withExtension:(NSString *)extension withCount:(UInt32)countClusters;
- (STFloppyError)	renameFileSTImage:(STDirectoryEntry *)directoryContent directorySize:(UInt32) directorySize entry:(STDirectoryEntry)directoryEntry withName:(NSString *)name withExtension:(NSString *)extension;

@end
