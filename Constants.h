//
//  Constants.h
//
//  Created by Laurent on 05/12/11.
//  Copyright 2011 Laurent68k. All rights reserved.
//
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#ifndef	__ConstantsATARIDISK_H
#define	__ConstantsATARIDISK_H

// Constants.h
extern NSString * const KEY_OBJECT_NOTIFICATION;
extern NSString * const NOTIFICATION_ID;

#define	APP_WINDOW__TITLE	@"OSX AtariDisk"
#define	DTL_WINDOW__TITLE	@"Bootsector"
#define	NEW_WINDOW__TITLE	@"New floppy"

#define	FREENULL(a)			if( a != NULL ) { free(a); a = NULL; }

#define	SWAP_BYTE(low,high)	( low | high << 8)

#define	BIT_READONLY		0x01
#define	BIT_HIDDEN			0x02 
#define	BIT_SYSTEM			0X04 
#define	BIT_VOLUMELABEL		0x08 
#define	BIT_DIRECTORY		0x10 
#define	BIT_MODIFIED		0X20 

#define	SZ_FILENAME			8
#define	SZ_EXTENSION		3

#define	SZ_BOOTSECTOR		512

#define SZ_FOLDER			4			//	Foler will have 4 clusters 

#endif
