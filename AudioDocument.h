//
//  AudioDocument.h
//  Recorder
//
//  Created by Daniel Ringwalt on 12/26/11.
//

#import <Cocoa/Cocoa.h>
#import "AudioView.h"
#import "Recorder.h"

@interface AudioDocument : NSDocument {
	AudioView *audioView;
	NSButton *recordButton;
	Recorder *recorder;
	BOOL recording;
}
@property (strong) IBOutlet AudioView *audioView;
@property (strong) IBOutlet NSButton *recordButton;
- (IBAction)recordClicked:(id)sender;
- (void)recordedPcmSamples:(void *)samples count:(long)count
					 start:(double)start
					   end:(double)end;
@end
