//
//  MainWndController.m
//
//  Created by Laurent on 01/02/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	Operating System:	OSX 10.6 Snow Leopard
//	Xcode:				3.2.6
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#include <stdlib.h>

#import "MainWndController.h"
#import "BrowserCell.h"
#import	"Constants.h"
#import "NodeFile.h"
#import "NodeDirectory.h"
#import "GUIBootSectorController.h"
#import "GUIFormatController.h"
#import "GUIFilenameController.h"

@implementation MainWndController

//---------------------------------------------------------------------------
-(id) init {
	
	self = [super init];
	
	self->rootNode = [[Node alloc] initWithParent:nil withName:@"root"];
	
	self->nodeDiskA =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive A" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	self->nodeDiskB =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive B" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	self->nodeDiskC =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive C" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	self->nodeDiskD =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive D" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	self->nodeDiskE =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive E" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	self->nodeDiskF =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive F" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	self->nodeDiskG =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive G" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	self->nodeDiskH =  [[NodeFloppy alloc] initWithParent:self->rootNode withName:@"Drive H" withImage:[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericRemovableMediaIcon)]];
	
	[self->rootNode.childNodes addObject: self->nodeDiskA ];
	[self->rootNode.childNodes addObject: self->nodeDiskB ];
	[self->rootNode.childNodes addObject: self->nodeDiskC ];
	[self->rootNode.childNodes addObject: self->nodeDiskD ];	
	[self->rootNode.childNodes addObject: self->nodeDiskE ];
	[self->rootNode.childNodes addObject: self->nodeDiskF ];
	[self->rootNode.childNodes addObject: self->nodeDiskG ];
	[self->rootNode.childNodes addObject: self->nodeDiskH ];

	return self;
}
//---------------------------------------------------------------------------
-(void) dealloc {
		
	[self->rootNode release];
	[self->nodeDiskA release];
	[self->nodeDiskB release];
	
    [super dealloc];
}
//---------------------------------------------------------------------------
- (void)awakeFromNib
{
	[[self window] setTitle: APP_WINDOW__TITLE];
	
	[self->tfDatTime setStringValue:@""];
	[self->tfSize setStringValue:@""];
	[self->tfName setStringValue:@""];
	[self->tfStartCluster setStringValue:@""];
	
	[self->miSave setEnabled:NO];
	[self->miSaveAs setEnabled:NO];
	[self->miEject setEnabled:NO];
	[self->miEdit setEnabled:NO];	

				
	//	Initialize the file browser
    [self->fileBrowser setCellClass: [BrowserCell class]];
    [self->fileBrowser setTarget:self];
    [self->fileBrowser setAction:@selector(browserSingleClick:)];
    [self->fileBrowser setDoubleAction:@selector(browserDoubleClick:)];
    
    // Configure the number of columns
    [self->fileBrowser setMaxVisibleColumns: 255];
    [self->fileBrowser setMinColumnWidth:NSWidth([self->fileBrowser bounds]) / (CGFloat) 3];   
	
	[self->fileBrowser loadColumnZero];		
}
//---------------------------------------------------------------------------
- (void)windowWillClose:(NSNotification *)note {
	
	[NSApp terminate: self ];
}
//---------------------------------------------------------------------------
-(void) sendNotification:(STFloppy *)disk withDriveName:(NSString *)drive {

	//	Send to the Notification center the node selected
	NSDictionary	*userInfo = [NSDictionary dictionaryWithObject:disk forKey: KEY_OBJECT_NOTIFICATION];
	
	NSString *notificationName = [NSString stringWithFormat:@"%@%@", NOTIFICATION_ID, drive];
	NSNotification	*notification = [NSNotification notificationWithName:notificationName object:self userInfo:userInfo];

	[[NSNotificationCenter defaultCenter] postNotification: notification];
}

//---------------------------------------------------------------------------
-(void) displayNodeGUI:(Node *)node {

	if( [node isKindOfClass:[NodeFloppy class]] ) {
		
		[self->tfName setStringValue: [node nameValue]];
		[self->tfSize setStringValue:@""];
		[self->tfDatTime setStringValue:@""];
		[self->tfStartCluster setStringValue:@""];

	}
	else if( [node isKindOfClass:[NodeFile class]] ) {
		
		[self->tfName setStringValue: [NSString stringWithFormat:@"File: %@", [node nameValue]]];
		[self->tfDatTime setStringValue: [NSString stringWithFormat:@"Date: %@", [(NodeFile *)node dateOfFileAsString]]];
		[self->tfSize setStringValue: [NSString stringWithFormat:@"Size: %d bytes", [(NodeFile *)node sizeOfFile]]];

		[self->tfStartCluster setStringValue: [NSString stringWithFormat:@"Start clusters: %d", ((NodeFile *)node).directoryEntry.SCLUSTER]];
		} 
	else if( [node isKindOfClass:[NodeDirectory class]] ) {
		
		UInt32	cntEntries = 0;
		Node *topNode = [node topNode];		
		if( topNode != nil ) {
			cntEntries = (((NodeDirectory *)node).countClustersUsed * ((NodeFloppy *)topNode).floppyDisk.bootsectorBPS / sizeof(STDirectoryEntry) );
		}
		
		[self->tfName setStringValue: [NSString stringWithFormat:@"Folder: %@", [node nameValue]]];
		[self->tfDatTime setStringValue: [NSString stringWithFormat:@"Date: %@", [(NodeDirectory *)node dateOfFileAsString]]];
		[self->tfSize setStringValue: [NSString stringWithFormat:@"Size: %d clusters, %d entries", ((NodeDirectory *)node).countClustersUsed, cntEntries]];

		[self->tfStartCluster setStringValue: [NSString stringWithFormat:@"Start cluster: %d", ((NodeDirectory *)node).directoryEntry.SCLUSTER]];		
	} 
	else {
	
		[self->tfName setStringValue:@""];
		[self->tfSize setStringValue:@""];
		[self->tfDatTime setStringValue:@""];
		[self->tfStartCluster setStringValue:@""];
	}
	
	[self->imageIcon setImage:[node iconImageOfSize:NSMakeSize(128,128)]];
}

//---------------------------------------------------------------------------
//	methods about the file browser
//---------------------------------------------------------------------------

- (Node *)parentNodeInfoForColumn:(NSInteger)column {

    Node	*result;
    if (column == 0) {
       
		//[self loadTree];
        result = self->rootNode;
    } 
    else {
        // Find the selected item leading up to this column and grab its FSNodeInfo stored in that cell
        BrowserCell *selectedCell = [self->fileBrowser selectedCellInColumn:column-1];
        result = [selectedCell node];
    }
    return result;
}
//---------------------------------------------------------------------------
// Use lazy initialization, since we don't want to touch the file system too much.
- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column {

	Node *parentNode = [self parentNodeInfoForColumn:column];
    
    return [[parentNode childNodes] count];
}
//---------------------------------------------------------------------------
- (void)browser:(NSBrowser *)sender willDisplayCell:(BrowserCell *)cell atRow:(NSInteger)row column:(NSInteger)column {

    Node *parentNode = [self parentNodeInfoForColumn:column];
    Node *currentNode = [[parentNode childNodes] objectAtIndex:row];
    
    [cell setNode:currentNode];
    [cell loadCellContents];
}
//---------------------------------------------------------------------------
-(Node *) getCurrentNode/*:(id)sender*/ {
	
	Node *node = nil;
	
    NSArray *selectedCells = [self->fileBrowser selectedCells];
    
    if ([selectedCells count] == 1) {
		
        BrowserCell *lastSelectedCell = [selectedCells objectAtIndex:[selectedCells count] - 1];
        
        node = [lastSelectedCell node];
        
	} 
    return node;
}
//---------------------------------------------------------------------------
- (void)updateGUI:(id)sender {

	Node *node = [self getCurrentNode];
    if( node != nil ) {
		
        [self displayNodeGUI: node];
		Node *top = [node topNode];
		
		[self sendNotification:((NodeFloppy *)top).floppyDisk withDriveName:[((NodeFloppy *)top) nameValue]];

		//	Arrange GUI following the current status of the Floppy node and the selected item
		if( ((NodeFloppy *)top).floppyDisk.diskLoaded ) {
			
			[[self window] setTitle: ((NodeFloppy *)top).floppyDisk.filenameDisk];
			
			[self->miOpen setEnabled:NO];
			[self->miOpenRecent setEnabled:NO];
			[self->miSave setEnabled:YES];
			[self->miSaveAs setEnabled:YES];
			[self->miEject setEnabled:YES];

			[self->miEdit setEnabled:YES];
			[self->miRename setEnabled:YES];				
			[self->miDelete setEnabled:YES];				

			if( [node isKindOfClass:[NodeFile class]] ) {
			
				[self->miExtractFiles setEnabled:YES];
			}
			else if([node isKindOfClass:[NodeDirectory class]] ) {
				
				[self->miExtractFiles setEnabled:NO];
			}
			else if([node isKindOfClass:[NodeFloppy class]] ) {	
				
				[self->miExtractFiles setEnabled:NO];
				[self->miRename setEnabled:NO];				
				[self->miDelete setEnabled:NO];				
			}
		}
		else {
			[[self window] setTitle: APP_WINDOW__TITLE];
			
			[self->miOpen setEnabled:YES];
			[self->miOpenRecent setEnabled:YES];
			[self->miSave setEnabled:NO];
			[self->miSaveAs setEnabled:NO];
			[self->miEject setEnabled:NO];
			
			[self->miEdit setEnabled:NO];
		}
	}    
}
//---------------------------------------------------------------------------
- (IBAction)browserSingleClick:(id)sender {

    //[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateGUI:) object:sender];
    //[self performSelector:@selector(updateGUI:) withObject:sender afterDelay:0.3];    
	[self updateGUI:sender];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

//	based on the code: http://web.mac.com/philippe.robinet/Trees_View/Edition_passif.html
- (IBAction)browserDoubleClick:(id)sender {
    	
	Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		if( [node isKindOfClass:[NodeFloppy class]] ) {
			[self readDisk: sender];
		}
		else {
		
			/*// Localizing the selection
			NSBrowserCell * selectedCell = [self->fileBrowser selectedCell];
			NSMatrix * matrix = [self->fileBrowser matrixInColumn:[self->fileBrowser selectedColumn]];

			// Field editor frame 
			NSRect frame=[matrix cellFrameAtRow:[matrix selectedRow] column:0];

			// Editing with the common fieldEditor
			[selectedCell setEditable:YES];
			fieldEditor=[[self window] fieldEditor:YES forObject:nil] ;
			[selectedCell editWithFrame:frame inView:matrix editor:fieldEditor delegate:self event:nil];
			[fieldEditor selectAll:self];	*/
		}
	}
}
//---------------------------------------------------------------------------
-(void) textDidEndEditing:(NSNotification *) notification
{
	// Localization
	/*NSBrowserCell * selectedCell=[self->fileBrowser selectedCell];
	BrowserTreeNode * node=[selectedCell representedObject];
	NSIndexPath * indexPath=[node indexPath];

	// Making changes
	[self->fileBrowser setTitle:[fieldEditor string] atIndexPath:indexPath]; 

	// Cleaning
	[selectedCell setEditable:NO];
	[window endEditingFor:nil];
	[window makeFirstResponder:browser];*/
}
//---------------------------------------------------------------------------
-(void) setTitle:(NSString *)newTitle atIndexPath:(NSIndexPath *) indexPath;
{
	/*BrowserTreeNode * node=[self->fileBrowser nodeAtIndexPath:indexPath];
	NodeInfo * nodeInfo=[node representedObject];

	[[undoManager prepareWithInvocationTarget:self->fileBrowser] setTitle:nodeInfo.title atIndexPath:indexPath]; 
	nodeInfo.title=newTitle;
	[browser reloadColumn:[indexPath length]-1];*/
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

-(void) reselectBest:(id)object {

 	NSInteger lastRow = [self->fileBrowser selectedRowInColumn: 0];
	
	[self->fileBrowser loadColumnZero];
	[self->fileBrowser selectRow:lastRow inColumn:0];

	[self->imageIcon setImage:nil];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

- (IBAction) readDisk:(id)sender {
	
	Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		if( [node isKindOfClass:[NodeFloppy class]] ) {
		
			STFloppyManager *floppy = ((NodeFloppy *)node).floppyDisk;
			if( ! floppy.diskLoaded ) {
			
				// Create a SavePanel
				NSOpenPanel *openPanel = [NSOpenPanel openPanel];

				// Set its allowed file types
				NSArray* allowedFileTypes = [NSArray arrayWithObjects: @"st", nil];
				[openPanel setAllowedFileTypes:allowedFileTypes];

				// Get the default images directory
				NSString* defaultDir = [NSString stringWithFormat:@"%@", [[NSRunningApplication currentApplication] bundleURL]];

				// Run the open panel, then check if the user clicked OK
				if ( NSOKButton == [openPanel runModalForDirectory:defaultDir file:nil] ) {		

					[node removeChild];				
					if( [floppy readSTImage:[openPanel filename] withRoot:(NodeFloppy *)node] ) {
			
						[self updateGUI:node];
					}
					else {
						NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Failed while reading disk", @"OK", NULL, NULL);		
					}
				}
				[self performSelector:@selector(reselectBest:) withObject:nil afterDelay:0.3];  		
			}
			else {
				NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"A disk is already loaded in this drive", @"OK", NULL, NULL);	
			}
		}
	}
	else {
		NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Please select which drive to insert", @"OK", NULL, NULL);	
	}
}
//---------------------------------------------------------------------------
-(IBAction) writeDiskAs:(id)sender {

    Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		Node *topNode = [node topNode];		
		
		// Create a SavePanel
		NSSavePanel *savePanel = [NSSavePanel savePanel];
	
		// Set its allowed file types
		NSArray* allowedFileTypes = [NSArray arrayWithObjects: @"st", nil];
		[savePanel setAllowedFileTypes:allowedFileTypes];
		[savePanel setDirectoryURL: [[NSRunningApplication currentApplication] bundleURL] ];	
		[savePanel setNameFieldStringValue:@"new disk" ];
	
		// Run the open panel, then check if the user clicked OK
		if ( NSOKButton == [savePanel runModal] ) {	
	
			BOOL done = [((NodeFloppy *)topNode).floppyDisk writeSTImageAs:[savePanel filename]];
			if( ! done ) {
				NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat:@"Failed to save the disk image: %@", [savePanel filename]], @"OK", NULL, NULL);		
			}
			else {
				[self updateGUI:node];
			}
		}
	}
	else {
		NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Please select which drive to save", @"OK", NULL, NULL);	
	}	
}
//---------------------------------------------------------------------------
-(IBAction) writeDisk:(id)sender {

    Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		Node *topNode = [node topNode];		
		
		BOOL done = [((NodeFloppy *)topNode).floppyDisk writeSTImage];
		if( ! done ) {
			NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat:@"Failed to save the disk image: %@", ((NodeFloppy *)topNode).floppyDisk.filenameDisk], @"OK", NULL, NULL);		
		}
		else {
			[self updateGUI:node];
		}
	}
	else {
		NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Please select which drive to save", @"OK", NULL, NULL);	
	}	
}
//---------------------------------------------------------------------------
-(IBAction) ejectDisk:(id)sender {

    Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		Node *topNode = [node topNode];		
				
			//[((NodeFloppy *)node) ejectDisk];		FIXME	pourquoi ici avant ?
			
			if( ((NodeFloppy *)topNode).floppyDisk.diskLoaded ) {
				
				[((NodeFloppy *)topNode) ejectDisk];
				
				[self updateGUI:topNode];

				[self performSelector:@selector(reselectBest:) withObject:nil afterDelay:0.3];  
			}
			else {
				NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"No disk to eject in this drive", @"OK", NULL, NULL);	
			}

	}
	else {
		NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Please select which drive to eject", @"OK", NULL, NULL);	
	}	
}
//---------------------------------------------------------------------------
-(IBAction) extractFileFromDisk:(id)sender {

    NSArray *selectedCells = [self->fileBrowser selectedCells];
    
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setDirectoryURL: [[NSRunningApplication currentApplication] bundleURL] ];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanCreateDirectories: YES];
	[openPanel setPrompt:@"Select"];
	[openPanel setMessage:@"Select a folder..."];
	[openPanel setNameFieldLabel:@"Extract the file as..."];
	
	
	// Run the open panel, then check if the user clicked OK
	if ( NSOKButton == [openPanel runModal] ) {	
		STFloppyError done = Ok;
		for(int index = 0; index < [selectedCells count] && done == Ok; index++ ) {

			BrowserCell *lastSelectedCell = [selectedCells objectAtIndex:index];
			
			Node *node = [lastSelectedCell node];
			Node *topNode = [node topNode];			
			if( [node isKindOfClass:[NodeFile class]] && [topNode isKindOfClass:[NodeFloppy class]]) {

				NSString *fullname = [NSString stringWithFormat:@"%@/%@", [openPanel filename], ((NodeFile *)node).nameValue];
				done = [((NodeFloppy *)topNode).floppyDisk extractFileSTImage:(NodeFile *)node withName:fullname];
				if( done != Ok ) {
					NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat:@"Failed to extract the file: %@", ((NodeFile *)node).nameValue], @"OK", NULL, NULL);		
				}
			}
		} 
	}	
}
//---------------------------------------------------------------------------
-(IBAction) addFilesToDisk:(id)sender {

    Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		Node *topNode = [node topNode];
		if( ((NodeFloppy *)topNode).floppyDisk.diskLoaded ) {

			NSOpenPanel *openPanel = [NSOpenPanel openPanel];
			
			[openPanel setDirectoryURL: [[NSRunningApplication currentApplication] bundleURL] ];
			[openPanel setAllowsMultipleSelection:YES];
			[openPanel setCanChooseDirectories:NO];
			[openPanel setCanChooseFiles:YES];
			[openPanel setResolvesAliases:YES];
			
			// Run the open panel, then check if the user clicked OK
			if ( NSOKButton == [openPanel runModal] ) {		
				
				STFloppyError done = Ok;
				NSArray *paths = [openPanel filenames];
				for(int index = 0; index < [paths count] && done == Ok; index++ ) {
					
					NSString *pathFile = (NSString *)[paths objectAtIndex:index];
					done = [((NodeFloppy *)topNode).floppyDisk addFileSTImage:node atPath:pathFile withRoot:topNode];							
					if( done == ParentError ) {
						NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Parent error", @"OK", NULL, NULL);		
					}
					else if (done == DiskFull) {
						NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Disk image is full", @"OK", NULL, NULL);		
					}
					else if (done == DuplicateName) {
						NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat:@"File name already exists: %@", pathFile], @"OK", NULL, NULL);		
					}
					else if (done == DirectoryFull) {
						NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Directory is full", @"OK", NULL, NULL);		
					}
				}			
				[self updateGUI:node];

				[self performSelector:@selector(reselectBest:) withObject:nil afterDelay:0.3];  
			}
		}
		else {
			NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Insert a disk before", @"OK", NULL, NULL);	
		}
	}
}
//---------------------------------------------------------------------------
-(IBAction) addFolderToDisk:(id)sender {
	
    Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		Node *topNode = [node topNode];
		
		if( ((NodeFloppy *)topNode).floppyDisk.diskLoaded ) {
			
			NSString 	*name, *extension;
			GUIFilenameController *filenameOwner = [[GUIFilenameController alloc] initWithTitle:@"New folder"];
			
			bool result = [filenameOwner showUI:&name withExtension:&extension];
			if( result ) {
				
				STFloppyError done = [((NodeFloppy *)topNode).floppyDisk addFolderSTImage:node withName:name withExtension:extension withRoot:topNode];
				if( done == ParentError ) {
					NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Parent error", @"OK", NULL, NULL);		
				}
				else if (done == DiskFull) {
					NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Disk image is full", @"OK", NULL, NULL);		
				}
				else if (done == DuplicateName) {
					NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat:@"File name already exists: %@", name], @"OK", NULL, NULL);		
				}
				else if (done == DirectoryFull) {
					NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Directory is full", @"OK", NULL, NULL);		
				}
				[self updateGUI:node];
				[self performSelector:@selector(reselectBest:) withObject:nil afterDelay:0.3];  	
			}		
			[filenameOwner release];
		}
		else {
			NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Insert a disk before", @"OK", NULL, NULL);	
		}
	}
	else {
		NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Please select at least a drive", @"OK", NULL, NULL);	
	}	
}
//---------------------------------------------------------------------------
-(IBAction) removeFilesToDisk:(id)sender {

    NSArray *selectedCells = [self->fileBrowser selectedCells];
	
	for(int index = 0; index < [selectedCells count];index++) {
	
		BrowserCell *selected = [selectedCells objectAtIndex:index];
		Node *node = [selected node];
		if( node != nil ) {
		
			if( [node isKindOfClass:[NodeDirectory class]] || [node isKindOfClass:[NodeFile class]] ) {
			
				Node *topNode = [node topNode];

				STFloppyError done = [((NodeFloppy *)topNode).floppyDisk removeFileSTImage:(NodeDirectory *)node withRoot:topNode];
				if( done != Ok ) {
					NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat:@"failed to delete the file: %@", [node nameValue]], @"OK", NULL, NULL);		
				}
			}
		}
	}
	[self performSelector:@selector(reselectBest:) withObject:nil afterDelay:0.3];  
}
//---------------------------------------------------------------------------
-(IBAction) renameFile:(id)sender {
	
	Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		Node *topNode = [node topNode];			
		if( ( [node isKindOfClass:[NodeFile class]] || [node isKindOfClass:[NodeDirectory class]] ) && [topNode isKindOfClass:[NodeFloppy class]]) {
			
			NSString 	*name, *extension;
			GUIFilenameController *filenameOwner = [[GUIFilenameController alloc] initWithTitle:@"Rename file"];
			
			[filenameOwner setName:((NodeFile *)node).name];
			[filenameOwner setExtension:((NodeFile *)node).extension];
			
			bool result = [filenameOwner showUI:&name withExtension:&extension];
			if( result ) {
				
				STFloppyError done = [((NodeFloppy *)topNode).floppyDisk renameFileSTImage:(NodeFile *)node withName:name withExtension:extension];
				if( done != Ok ) {
					NSRunInformationalAlertPanel(APP_WINDOW__TITLE, [NSString stringWithFormat:@"Failed to rename the file: %@", ((NodeFile *)node).nameValue], @"OK", NULL, NULL);		
				}
			}
			[filenameOwner release];
			[self performSelector:@selector(reselectBest:) withObject:nil afterDelay:0.3];  
		}
		else {
			
			NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"not implemented", @"OK", NULL, NULL);			
		}
	}
}
//---------------------------------------------------------------------------
-(IBAction) openBootsectorDetails:(id)sender {

    Node *node = [self getCurrentNode];
	if( node != nil ) {
		
		Node *topNode = [node topNode];
		
		//	Set for this controller the custom notification string to check
		NSString *notificationName = [NSString stringWithFormat:@"%@%@", NOTIFICATION_ID, [((NodeFloppy *)topNode) nameValue]];
		
		//	Create the controller and run the window
		GUIBootSectorController *bootSectorOwner = [[GUIBootSectorController alloc] initWithNotification:notificationName driveName:[((NodeFloppy *)topNode) nameValue]];
		[bootSectorOwner showUI];
		
		//	send its first notification to display the floppy
		[self sendNotification:((NodeFloppy *)topNode).floppyDisk withDriveName:[((NodeFloppy *)topNode) nameValue]];		
	}
	else {
		NSRunInformationalAlertPanel(APP_WINDOW__TITLE, @"Please select the disk to show", @"OK", NULL, NULL);		
	}
}
//---------------------------------------------------------------------------
-(IBAction) openBlankDisk:(id)sender {

	GUIFormatController *formatingOwner = [[GUIFormatController alloc] init];
	[formatingOwner showUI];
	
	[formatingOwner release];
}
//---------------------------------------------------------------------------
  
@end
