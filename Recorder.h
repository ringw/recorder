//
//  Recorder.h
//  Recorder
//
//  Created by Daniel Ringwalt on 11/29/11.
//

#import <Foundation/Foundation.h>
#import <lame/lame.h>
#import <AudioToolbox/AudioToolbox.h>

@interface Recorder : NSObject {
    //MTCoreAudioDevice *inputDevice;
	
    lame_global_flags *			lame_flags;
	
    //int STOP;
    //ALCdevice *device;
    /*AVCaptureSession *session;
    AVCaptureAudioDataOutput *dataout;
    AVCaptureAudioPreviewOutput *prevout;
    AVCaptureDevice *device;*/
    //AudioQueueRef aq;
}

@property (nonatomic, readwrite) AudioQueueRef queue;

@property (nonatomic, readwrite) CFAbsoluteTime queueStartStopTime;
@property (nonatomic, readwrite) AudioFileID recordFile;
@property (nonatomic, readwrite) SInt64 recordPacket; // current packet number in record file
@property (nonatomic, readwrite) Boolean running;
@property (nonatomic, readwrite) Boolean verbose;

@property (readonly) NSMutableData *pcmData;
@property (readonly) NSMutableData *lameData;
@property (assign) id delegate;

- (void)start;
- (void)stop;

- (void)writeTagsFid:(FILE *)fid;

@end
