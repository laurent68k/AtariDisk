//
//  STFloppyCluster.m
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import "STFloppyCluster.h"
#import "Constants.h"

@implementation STFloppyCluster

@synthesize buffer;
@synthesize number;

//---------------------------------------------------------------------------
- (id)init:(UInt32)sizeCluster withNumber:(UInt32)clusterNumber {  
  
    if (self = [super init]) {
    
		self->number = clusterNumber;
        self->buffer = malloc( sizeCluster );

	}           
    return self;
}
//---------------------------------------------------------------------------
- (void)dealloc {

	FREENULL(self->buffer);
    [super dealloc];
}
//---------------------------------------------------------------------------

@end
