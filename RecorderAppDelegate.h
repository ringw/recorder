//
//  RecorderAppDelegate.h
//  Recorder
//
//  Created by Daniel Ringwalt on 11/25/11.
//  Copyright 2011 Tilt Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AudioView.h"
//#import "Recorder.h"

@interface RecorderAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *__weak window;
	//AudioView *audioView;
	//Recorder *rec;
}

@property (weak) IBOutlet NSWindow *window;
//@property (retain) IBOutlet AudioView *audioView;

@end
