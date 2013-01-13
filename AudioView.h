//
//  AudioView.h
//  Recorder
//
//  Created by Daniel Ringwalt on 11/29/11.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface AudioVolumeView : NSView {
	double volume, peakVolume;
	CALayer *peakLayer, *volumeLayer;
}
@property (assign) double volume;
@property (assign) double peakVolume;
@end

@interface AudioView : NSView {
	double position, length;
	BOOL isRecording;
	CALayer *progressLayer;
	AudioVolumeView *volumeView;
	
	double peakAudio, peakTime;
}
@property (assign) double position;
@property (assign) double length;
@property (assign, getter=isRecording, setter=setIsRecording:) BOOL recording;
@property (strong) IBOutlet AudioVolumeView *volumeView;
- (void)displayPcmSamples: (void *)samples count: (long)count startTime: (double)start endTime: (double)end;
@end
