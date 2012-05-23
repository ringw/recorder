// AppController.h -- application controller for Recordotron

// Copyright (C) 2003 Borkware
// We use the BSD License.  Check out http://borkware.com/license

#import <Cocoa/Cocoa.h>

@class MTCoreAudioDevice;

@interface AppController : NSObject
{
    IBOutlet NSSlider *inputVolumeSlider;
    IBOutlet NSSlider *outputVolumeSlider;

    IBOutlet NSButton *recordStopButton;
    IBOutlet NSButton *playStopButton;

    MTCoreAudioDevice *inputDevice;
    MTCoreAudioDevice *outputDevice;
}

- (IBAction) startRecording: (id) sender;
- (IBAction) stopRecording: (id) sender;

- (IBAction) startPlaying: (id) sender;
- (IBAction) stopPlaying: (id) sender;

- (IBAction) changeInputVolume: (id) sender;
- (IBAction) changeOutputVolume: (id) sender;

@end // AppController

