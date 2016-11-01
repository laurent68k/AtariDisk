//
//  STFloppyCluster.h
//
//  Created by Laurent on 04/11/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import <Cocoa/Cocoa.h>

@interface STFloppyCluster : NSObject {

	@protected

		UInt32			number;
		UInt8			*buffer;
}

@property(nonatomic,readwrite)	UInt8 *buffer;
@property(nonatomic,readonly)	UInt32 number;

-(id)				init:(UInt32)sizeCluster withNumber:(UInt32)clusterNumber;


@end
