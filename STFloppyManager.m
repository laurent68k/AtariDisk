//
//  NodeInfo.m
//
//  Created by Laurent on 02/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	Operating System:	OSX 10.6 Snow Leopard
//	Xcode:				3.2.6
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import "STFloppyManager.h"
#import "NodeFile.h"
#import "NodeFloppy.h"
#import	"Constants.h"

@implementation STFloppyManager

@synthesize filenameDisk;

//
//	80	9	1	512		360 Ko
//	80	9	2	512		720 Ko
//	80	18	2	512		1.44 Mb
//

//---------------------------------------------------------------------------
- (id)initWithDelegate:(id)theDelegate {  
  
    if (self = [super init]) {
    	
    	self->delegate = theDelegate;
		self->filenameDisk = nil;
	}       
    
    return self;
}
//---------------------------------------------------------------------------
- (void)dealloc {

    [super dealloc];
}

//---------------------------------------------------------------------------
//	
//---------------------------------------------------------------------------

-(void) parseDirectory:(STDirectoryEntry *)directory withEntries:(UInt32)countEntries withRoot:(Node *) nodeRoot {
							
	int index = 0;			
	while( index < countEntries ) {
	
		Node	*node = nil;
					
		if( directory[index].FNAME[0] == ENTRY_FREE || directory[index].FNAME[0] == ENTRY_DELETED) {
		}
		else if( (directory[index].FATTRIB & BIT_VOLUMENAME) != 0 ) {
		
			char	volume[9];
			memset( volume, 0x00, 9);		
			strncpy(volume, directory[index].FNAME, 8 );	
			self->volumeName = [NSString stringWithCString:volume encoding:NSASCIIStringEncoding];
			
			[self->volumeName retain];				
		}
		else {
			if( (directory[index].FATTRIB & BIT_DIRECTORY) != 0 ) {

				node = [[NodeDirectory alloc] initWithParent:nodeRoot rawEntry:&directory[index] fromDisk:self];		

				if( ! ([[node nameValue] isEqualToString:@"."] || [[node nameValue] isEqualToString:@".."]) ){
					/*NSLog(@"Folder : %@ Attr: %X Date:%X Time:%X Size:%d SCluster:%d", [node nameValue], 
																			directory[index].FATTRIB,
																			directory[index].FDATE, 
																			directory[index].FTIME, 
																			directory[index].FSIZE,
																			directory[index].SCLUSTER );*/
								
				
					UInt32 indexFATEntry = directory[index].SCLUSTER;
					NSMutableArray		*clusters = [[NSMutableArray alloc] init];
					STDirectoryEntry	*subDirectory;
	
					UInt32 countClusters = [self extractClusters:clusters AtFATIndex:indexFATEntry];
					[self assembleClusters:clusters inBuffer:(void **)&subDirectory];
				
					((NodeDirectory *)node).countClustersUsed = countClusters;
					
					UInt32	countEntries = countClusters * self->bootSector.SPC * [self bootsectorBPS] / sizeof( STDirectoryEntry );
					[self parseDirectory:subDirectory withEntries:countEntries withRoot:node];
					[clusters release];
				}
				else {
					node = nil;
				}
			}
			else {			
				node = [[NodeFile alloc] initWithParent:nodeRoot rawEntry:&directory[index] fromDisk:self];		

				/*NSLog(@"Filename : %@ Attr: %X Date:%X Time:%X Size:%d SCluster:%d", [node nameValue], 
																			directory[index].FATTRIB,
																			directory[index].FDATE, 
																			directory[index].FTIME, 
																			directory[index].FSIZE,
																			directory[index].SCLUSTER );*/
																			
			}

			if( node != nil ) {
			   [nodeRoot addChild:node];
			}
		}
		index++;
	}
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

-(bool) readSTImage:(NSString *)filename withRoot:(Node *)nodeDisk  {

	bool success = [super readSTImage:filename];

	if( success ) {	
	
		[self parseDirectory:rootDirectory withEntries:[self bootsectorNDIRS] withRoot:nodeDisk];
		self->diskLoaded = true;
		self->filenameDisk = filename;
		
		[self->filenameDisk retain];
	}
	return success;
}
//---------------------------------------------------------------------------
-(bool)	writeSTImageAs:(NSString *)filename {

	if( self->diskBuffer != nil ) {
	
		[[NSFileManager defaultManager] createFileAtPath:filename contents:self->diskBuffer attributes:nil];	

		if( self->filenameDisk != nil ) {
		
			[self->filenameDisk release];
		}
		
		self->filenameDisk = filename;
		[self->filenameDisk retain];
		
		return true;
	}
	return false;
}
//---------------------------------------------------------------------------
-(bool)	writeSTImage {

	if( self->diskBuffer != nil ) {
	
		[[NSFileManager defaultManager] createFileAtPath:self->filenameDisk contents:self->diskBuffer attributes:nil];	
		
		return true;
	}
	return false;
}
//---------------------------------------------------------------------------
-(STFloppyError) extractFileSTImage:(NodeFile *)node withName:(NSString *)filename {

	NSData	*fileMemory = nil;

	NSLog(@"extract File in ST image: name=%@", filename);
	bool success = [super extractFileSTImage:node.directoryEntry.SCLUSTER size:node.directoryEntry.FSIZE inBuffer:&fileMemory ];
	
	if( success ) {	
	
		[[NSFileManager defaultManager] createFileAtPath:filename contents:fileMemory attributes:nil];	
	}
	return Ok;
}
//---------------------------------------------------------------------------
+(bool) createSTImage:(NSString *)filename withSize:(STFloppySize)size withName:(NSString *)diskName withExtension:(NSString *)diskExtension {
	
	int tracks, sectors, sides;
	tracks = 80;
	
	switch( size ) {
			
		//	Premier ST/STf have drives with single side
		case kSingleSide:
			sides = 1;
			sectors = 9;
			break;
			
		//	case of Atari Falcon
		case kHighDensity:
			sides = 2;
			sectors = 18;
			break;
			
		//	Never existed on Atari
		case kExtendDensity:
			sides = 2;
			sectors = 36;
			break;
			
		//	Standard STF/STE/Mega floppy
		case kDoubleSide:
		default:
			sides = 2;
			sectors = 9;
			break;
	} 
	
	NSData *floppyBuffer;
	
	bool result = [STFloppy createSTImage:tracks withSectors:sectors withSides:sides inBuffer:&floppyBuffer withName:diskName withExtension:diskExtension];
	if (result ){
		[[NSFileManager defaultManager] createFileAtPath:filename contents:floppyBuffer attributes:nil];
	}
	return result;
}
//---------------------------------------------------------------------------
-(void) ejectSTDisk {
	
	NSLog(@"ejectDisk");
	
	[super cleanup];
	
	if( self->filenameDisk != nil ) {
	
		[self->filenameDisk release];
		self->filenameDisk = nil;
	}
}
//---------------------------------------------------------------------------
-(STFloppyError) addFileSTImage:(Node *)parentNode atPath:(NSString *)filename withRoot:(Node *)nodeRoot {
	
	STFloppyError	retour;

	NSData 	*fileData = [[NSFileManager defaultManager] contentsAtPath:filename];
	
	NSArray *elements = [filename pathComponents];
	NSArray *names = [((NSString *)[elements objectAtIndex: [elements count]-1 ]) componentsSeparatedByString:@"."];
	NSString *nameonly = (NSString *)[names objectAtIndex: 0 ];
	NSString *extension = [filename pathExtension];
	
	NSString *padName = [nameonly stringByPaddingToLength: 8 withString: @" " startingAtIndex:0];
	NSString *padExtension = [extension stringByPaddingToLength: 3 withString: @" " startingAtIndex:0];
		
	if( !self->diskLoaded ) {
		return NoDisk;
	}
	
	if( fileData != nil ) {
	
		if( [parentNode isKindOfClass:[NodeFloppy class]] ) {
			
			NSLog(@"addFile: file %@ extension %@ in root directory", nameonly, [filename pathExtension]);

			retour = [super addFileSTImage:self->rootDirectory directorySize:[self bootsectorNDIRS] withData:fileData withName:padName withExtension:padExtension];
			if( retour == Ok ) {
		
				[self commitDisk];
			}
			else {
				[self rollbackDisk];
			}
		} 
		else if ([parentNode isKindOfClass:[NodeFile class]]) {
		
			Node *nodeDirectory = [parentNode parent];
			retour = [self addFileSTImage:nodeDirectory atPath:filename withRoot:nodeRoot];
			if( retour == Ok ) {
		
				[self commitDisk];
			}
			else {
				[self rollbackDisk];
			}
		}
		else if ( [parentNode isKindOfClass:[NodeDirectory class]] ) {
		
			NSLog(@"addFile: file %@ extension %@ in directory %@", nameonly, [filename pathExtension], parentNode.nameValue);
			
			UInt32 indexFATEntry = ((NodeDirectory *)parentNode).directoryEntry.SCLUSTER;
			NSMutableArray		*clusters = [[NSMutableArray alloc] init];
			STDirectoryEntry	*subDirectory;
		
			UInt32 countClusters = [self extractClusters:clusters AtFATIndex:indexFATEntry];
			[self assembleClusters:clusters inBuffer:(void **)&subDirectory];
			
			UInt32 countEntries = countClusters * self->bootSector.SPC * [self bootsectorBPS] / sizeof(STDirectoryEntry);			
			retour = [super addFileSTImage:subDirectory directorySize:countEntries withData:fileData withName:padName withExtension:padExtension];
			if( retour == Ok ) {
			
				[super saveBackClusters:clusters fromBuffer:(void *)subDirectory];
				[super commitDisk];
			}
			else {
				[super rollbackDisk];
			}
			
			FREENULL(subDirectory);
			[clusters release];
		}
		else {
			retour = ParentError;
		}
		
		if( retour == Ok ) {
			[nodeRoot removeChild];	
			[self parseDirectory:self->rootDirectory withEntries:[self bootsectorNDIRS] withRoot:nodeRoot];
		}
	}
	return retour;
}
//---------------------------------------------------------------------------
-(STFloppyError) removeFileSTImage:(NodeDirectory *)nodeFile withRoot:(Node *)nodeRoot {
	
	STFloppyError	retour;
	Node *parentNode = [nodeFile parent];
	
	if( [parentNode isKindOfClass:[NodeFloppy class]] ) {
	
		NSLog(@"removeFile: file %@ from root directory", nodeFile.nameValue);
		
		retour = [self removeFileSTImage:self->rootDirectory directorySize:[self bootsectorNDIRS] withName:nodeFile.nameValue withExtension:nodeFile.extension startCluster:nodeFile.directoryEntry.SCLUSTER];
		if( retour == Ok ) {
		
			[self commitDisk];
		}
		else {
			[self rollbackDisk];
		}
	}
	else if([parentNode isKindOfClass:[NodeDirectory class]]){
	
		NSLog(@"removeFile: file %@ from directory: %@", nodeFile.nameValue, parentNode.nameValue);

		UInt32 indexFATEntry = ((NodeDirectory *)parentNode).directoryEntry.SCLUSTER;
		NSMutableArray		*clusters = [[NSMutableArray alloc] init];
		STDirectoryEntry	*subDirectory;
	
		UInt32 countClusters = [self extractClusters:clusters AtFATIndex:indexFATEntry];
		[self assembleClusters:clusters inBuffer:(void **)&subDirectory];
		
		UInt32 countEntries = countClusters * self->bootSector.SPC * [self bootsectorBPS] / sizeof(STDirectoryEntry);		
		retour = [self removeFileSTImage:subDirectory directorySize:countEntries withName:nodeFile.nameValue withExtension:nodeFile.extension startCluster:nodeFile.directoryEntry.SCLUSTER];
	
		if( retour == Ok ) {
		
			[self saveBackClusters:clusters fromBuffer:(void *)subDirectory];
			[self commitDisk];
		}
		else {
			[self rollbackDisk];
		}
		FREENULL(subDirectory);
		[clusters release];
	}
	else {
		retour = ParentError;
	}
	
	if( retour == Ok ) {
		[nodeRoot removeChild];	
		[self parseDirectory:self->rootDirectory withEntries:[self bootsectorNDIRS] withRoot:nodeRoot];
	}

	return retour;
	
}
//---------------------------------------------------------------------------
-(STFloppyError) addFolderSTImage:(Node *)parentNode withName:(NSString *)name withExtension:(NSString *)extension withRoot:(Node *)nodeRoot {
	
	STFloppyError	retour;
	
	NSString *padName = [name stringByPaddingToLength: 8 withString: @" " startingAtIndex:0];
	NSString *padExtension = [extension stringByPaddingToLength: 3 withString: @" " startingAtIndex:0];

	if( !self->diskLoaded ) {
		return NoDisk;
	}
	
	if( [parentNode isKindOfClass:[NodeFloppy class]] ) {
		
		NSLog(@"addFolder: foldername=%@ folderextension=%@ in root directory", name, extension);
		retour = [super addFolderSTImage:self->rootDirectory directorySize:[self bootsectorNDIRS] parentStartCluster:0 withName:padName withExtension:padExtension withCount:SZ_FOLDER];
		if( retour == Ok ) {
		
			[self commitDisk];
		}
		else {
			[self rollbackDisk];
		}
	}
	else if ([parentNode isKindOfClass:[NodeFile class]]) {
		
		Node *nodeDirectory = [parentNode parent];

		NSLog(@"addFolder: foldername=%@ folderextension=%@ in directory %@", name, extension, nodeDirectory.nameValue);

		retour = [self addFolderSTImage:nodeDirectory withName:name withExtension:extension withRoot:nodeRoot];
		if( retour == Ok ) {
		
			[super commitDisk];
		}
		else {
			[super rollbackDisk];
		}
	}
	else if ( [parentNode isKindOfClass:[NodeDirectory class]] ) {
	
		NSLog(@"addFolder: foldername=%@ folderextension=%@ in directory %@", name, extension, parentNode.nameValue);

		UInt32 indexFATEntry = ((NodeDirectory *)parentNode).directoryEntry.SCLUSTER;
		NSMutableArray		*clusters = [[NSMutableArray alloc] init];
		STDirectoryEntry	*subDirectory;
	
		UInt32 countClusters = [self extractClusters:clusters AtFATIndex:indexFATEntry];
		[self assembleClusters:clusters inBuffer:(void **)&subDirectory];

		UInt32 countEntries = countClusters * self->bootSector.SPC * [self bootsectorBPS] / sizeof(STDirectoryEntry);

		retour = [super addFolderSTImage:subDirectory directorySize:countEntries parentStartCluster:indexFATEntry withName:padName withExtension:padExtension withCount:SZ_FOLDER];
		if( retour == Ok ) {
		
			[self saveBackClusters:clusters fromBuffer:(void *)subDirectory];
			[self commitDisk];
		}
		else {
			[self rollbackDisk];
		}
		FREENULL(subDirectory);
		[clusters release];
	}
	else {
		retour = ParentError;
	}
	
	if( retour == Ok ) {
		[nodeRoot removeChild];	
		[self parseDirectory:self->rootDirectory withEntries:[self bootsectorNDIRS] withRoot:nodeRoot];
	}

	return retour;
}
//---------------------------------------------------------------------------
-(STFloppyError) renameFileSTImage:(NodeFile *)node withName:(NSString *)name withExtension:(NSString *)extension {

	STFloppyError	retour;
	
	NSString *newName = [name stringByPaddingToLength: 8 withString: @" " startingAtIndex:0];
	NSString *newExtension = [extension stringByPaddingToLength: 3 withString: @" " startingAtIndex:0];
	
	if( !self->diskLoaded ) {
		return NoDisk;
	}
	
	Node *parentNode = [node parent];
	
	if( [parentNode isKindOfClass:[NodeFloppy class]] ) {
		
		NSLog(@"RenameFile: filename=%@ fileextension=%@ inside root directory", name, extension);
		retour = [super renameFileSTImage:self->rootDirectory directorySize:[self bootsectorNDIRS] entry:node.directoryEntry withName:newName withExtension:newExtension ];

		if( retour == Ok ) {
			
			[self commitDisk];
			
			node.extension = extension;
			node.name = name;
		}
		else {
			[self rollbackDisk];
		}
	}
	else if ( [parentNode isKindOfClass:[NodeDirectory class]] ) {
		
		NSLog(@"RenameFile: filename=%@ fileextension=%@ from parent directory %@", name, extension, parentNode.nameValue);
		
		UInt32 indexFATEntry = ((NodeDirectory *)parentNode).directoryEntry.SCLUSTER;
		NSMutableArray		*clusters = [[NSMutableArray alloc] init];
		STDirectoryEntry	*subDirectory;
		
		UInt32 countClusters = [self extractClusters:clusters AtFATIndex:indexFATEntry];
		[self assembleClusters:clusters inBuffer:(void **)&subDirectory];
		
		UInt32 countEntries = countClusters * self->bootSector.SPC * [self bootsectorBPS] / sizeof(STDirectoryEntry);
		
		retour = [super renameFileSTImage:subDirectory directorySize:countEntries entry:node.directoryEntry withName:newName withExtension:newExtension];
		if( retour == Ok ) {
			
			[self saveBackClusters:clusters fromBuffer:(void *)subDirectory];
			[self commitDisk];
			
			node.extension = extension;
			node.name = name;
		}
		else {
			[self rollbackDisk];
		}
		FREENULL(subDirectory);
		[clusters release];
	}
	else {
		retour = ParentError;
	}
	
	return retour;
	
}

@end
