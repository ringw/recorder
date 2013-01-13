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

@property (nonatomic, readonly) AudioStreamBasicDescription recordingFormat;

@property (nonatomic, readwrite) AudioQueueRef queue;

@property (nonatomic, readwrite) CFAbsoluteTime queueStartStopTime;
@property (nonatomic, readwrite) AudioFileID recordFile;
@property (nonatomic, readwrite) SInt64 recordPacket; // current packet number in record file
@property (nonatomic, readwrite) Boolean running;
@property (nonatomic, readwrite) Boolean verbose;

@property (readonly) NSMutableData *pcmData;
@property (weak, readonly) NSMutableData *lameData;
@property (weak) id delegate;

- (instancetype)init;
- (instancetype)initWithRecordingFormat:(AudioStreamBasicDescription *)recordingFormatRef;

- (void)start;
- (void)stop;

- (void)writeTagsFid:(FILE *)fid;

@end
