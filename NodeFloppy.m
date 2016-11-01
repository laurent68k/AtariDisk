//
//  Node.m
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import "NodeFloppy.h"

@implementation NodeFloppy

@synthesize floppyDisk;

//---------------------------------------------------------------------------
-(id) initWithParent:(Node *)parent {  
  
    if (self = [super initWithParent: parent]) {
    
		self->floppyDisk =  [[STFloppyManager alloc] initWithDelegate: self];
	}           
    return self;
}
//---------------------------------------------------------------------------
-(id) initWithParent:(Node *)parent withName:(NSString *)theName {  
  
    if (self = [super initWithParent:parent withName:theName]) {
    
		self->floppyDisk =  [[STFloppyManager alloc] initWithDelegate: self];
	}           
    return self;
}
//---------------------------------------------------------------------------
-(id) initWithParent:(Node *)parent withName:(NSString *)theName withImage:(NSImage *)theImage {  
  
    if (self = [super initWithParent:parent withName:theName withImage:theImage ]) {
    
		self->floppyDisk =  [[STFloppyManager alloc] initWithDelegate: self];
	}           
    return self;
}
//---------------------------------------------------------------------------
-(void) dealloc {

	[self->floppyDisk release];
	[super dealloc];
}
//---------------------------------------------------------------------------
-(NSString *) nameValue {
	
	if( [self->floppyDisk volumeName] != nil ) {
		
		return [NSString stringWithFormat:@"%@: %@", self->name, [self->floppyDisk volumeName]];
	}
	return self->name;
}
//---------------------------------------------------------------------------
-(void) ejectDisk {
	
	[self->floppyDisk ejectSTDisk];
	[self removeChild];
}
//---------------------------------------------------------------------------


@end
