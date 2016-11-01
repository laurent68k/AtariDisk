//
//  Node.m
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import "Node.h"

@implementation Node

@synthesize name;

//---------------------------------------------------------------------------
- (id)initWithParent:(Node *)parent {  
  
    if (self = [super init]) {
    
        self->imageIcon = nil;
		self->nodeParent = parent;	
        self->childNodes = [[NSMutableArray alloc] init];
		self->name = nil; 		

		[self->childNodes retain];
		[self->nodeParent retain];

	}           
    return self;
}
//---------------------------------------------------------------------------
- (id)initWithParent:(Node *)parent withName:(NSString *)theName {  
  
    if (self = [super init]) {
    
        self->imageIcon = nil;
		self->nodeParent = parent;	
        self->childNodes = [[NSMutableArray alloc] init];
		self->name = theName; 		

		[self->childNodes retain];
		[self->name retain];
		[self->nodeParent retain];

	}           
    return self;
}
//---------------------------------------------------------------------------
- (id)initWithParent:(Node *)parent withName:(NSString *)theName withImage:(NSImage *)theImage {  
  
    if (self = [super init]) {
    
		self->imageIcon = theImage;
        self->nodeParent = parent;	
        self->childNodes = [[NSMutableArray alloc] init];
		self->name = theName; 	
		
		[self->imageIcon retain];
		[self->childNodes retain];
		[self->name retain];
		[self->nodeParent retain];

	}           
    return self;
}//---------------------------------------------------------------------------
- (void)dealloc {

	if( self->imageIcon != nil ) {
		[self->imageIcon release];
	}
	[self->nodeParent release];
	[self->childNodes release];  
    [super dealloc];
}
//---------------------------------------------------------------------------
-(void) addChild:(Node *)child {
	
	[self->childNodes addObject:child];
}
//---------------------------------------------------------------------------
-(void)removeChild {

	for(int index = 0; index < [self->childNodes count]; index++ ) {
	
		Node *child = (Node *)[self->childNodes objectAtIndex: index];
		[child removeChild];
	}
	
    [self->childNodes removeAllObjects];
}
//---------------------------------------------------------------------------
-(NSMutableArray *) childNodes {

	return self->childNodes;
}
//---------------------------------------------------------------------------
-(Node *) topNode {

	Node *top;
	if( self->nodeParent == nil ) {
	
		top = self;
	}
	else if([self->nodeParent parent] == nil ) {
		
		top = self;
	}
	else {
		top = [self->nodeParent topNode];
	}
	return top;
}
//---------------------------------------------------------------------------
-(void) setParent:(Node *)theParent {

	self->nodeParent = theParent;
}
//---------------------------------------------------------------------------
-(Node *) parent {
	
	return self->nodeParent;
}
//---------------------------------------------------------------------------
-(bool) isLeaf {

	return NO;
}
//---------------------------------------------------------------------------
-(NSString *) nameValue {

	return self->name;
}
//---------------------------------------------------------------------------
-(void) setName:(NSString *)theName {
	
	self->name = theName;
	[self->name retain];
}

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------

-(NSImage *) iconImage {
	
	return self->imageIcon;
}
//---------------------------------------------------------------------------
- (NSImage *) iconImageOfSize:(NSSize)size {
	
    NSImage		*image = nil;
    
    if( self->imageIcon == nil ) {
		self->imageIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIconResource)];
    }
	
	image = [self->imageIcon copy];
	[image setSize: size];
	
    return image;
}
//---------------------------------------------------------------------------

@end
