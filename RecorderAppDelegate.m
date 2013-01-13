//
//  RecorderAppDelegate.m
//  Recorder
//
//  Created by Daniel Ringwalt on 11/25/11.
//  Copyright 2011 Tilt Software. All rights reserved.
//

#import "RecorderAppDelegate.h"

@implementation RecorderAppDelegate

@synthesize window;

/*- (void)_updateAudioView {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	double time = 5e-2;
	while (1) {
		usleep(5e-2*1e6);
		time += 5e-2;
		[audioView setLength: time];
		[audioView setPosition: time];
		dispatch_queue_t q = dispatch_get_main_queue();
		dispatch_async(q, ^{
			[audioView setNeedsDisplay: YES];
		});
		//[audioView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:[NSNumber numberWithBool: YES] waitUntilDone: NO];
	}
}*/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	//[NSThread detachNewThreadSelector:@selector(_updateAudioView) toTarget:self withObject:nil];
	//rec = [Recorder new];
	//[rec start];
	//[self performSelectorInBackground:@selector(stuff) withObject:nil];
	//[[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:NULL];
}
	/*- (void)stuff {
		sleep(10);
		//[rec stop];
		[[rec valueForKey: @"wavData"] writeToFile: @"/Users/dan/Desktop/a.pcm" atomically: YES];
}*/

@end
