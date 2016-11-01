//
//  NodeFile.m
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import "NodeFile.h"

@implementation NodeFile

//---------------------------------------------------------------------------
-(id) initWithParent:(Node *)parent withName:(NSString *)theName {

    if (self = [super initWithParent:parent withName:theName]) {
    

	}           
    return self;
}
//---------------------------------------------------------------------------
-(id) initWithParent:(Node *)parent rawEntry:(STDirectoryEntry *)aDirectoryEntry fromDisk:(STFloppy *)disk {  
  
    if (self = [super initWithParent: parent rawEntry:aDirectoryEntry fromDisk:disk]) {
    
	}           
    return self;
}
//---------------------------------------------------------------------------
- (void)dealloc {

    [super dealloc];
}
//---------------------------------------------------------------------------

@end
