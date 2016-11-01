//
//  LFTextFormatter.h
//
//
//	Operating System:	OSX 10.6 Snow Leopard
//	Xcode:				3.2.6
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.


#import <Cocoa/Cocoa.h>


@interface LFTextFormatter : NSFormatter {

	@protected
	
		UInt32	stringlength;
}

-(id)				initWithlenght:(UInt32)lenght;

@end
