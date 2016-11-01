//
//  Node.h
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>

@interface Node : NSObject {

	@protected

		NSString			*name;
		NSImage				*imageIcon;
	
		Node				*nodeParent; 
		NSMutableArray		*childNodes;
}

@property(nonatomic,retain,readwrite)	NSString *name;

-(id)				initWithParent:(Node *)parent;
-(id)				initWithParent:(Node *)parent withName:(NSString *)theName;
-(id)				initWithParent:(Node *)parent withName:(NSString *)theName withImage:(NSImage *)theImage;

-(void)				addChild:(Node *)child;
-(void)				removeChild;
-(NSMutableArray *) childNodes;
-(bool)				isLeaf;
-(NSString *)		nameValue;
-(void)				setName:(NSString *)theName;
-(void)				setParent:(Node *)theParent;
-(Node *)			parent;
-(Node *)			topNode;

-(NSImage *)		iconImage; 
-(NSImage *)		iconImageOfSize:(NSSize)size; 

@end
