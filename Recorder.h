//
//  Recorder.h
//  Recorder
//
//  Created by Daniel Ringwalt on 11/29/11.
//

#import <Foundation/Foundation.h>
#include <lame/lame.h>
#include <AudioToolbox/AudioToolbox.h>

typedef struct MyRecorder {
	AudioQueueRef				queue;
	
	CFAbsoluteTime				queueStartStopTime;
	AudioFileID					recordFile;
	SInt64						recordPacket; // current packet number in record file
	Boolean						running;
	Boolean						verbose;
    NSMutableData *data;
    id delegate;
} MyRecorder;

@interface Recorder : NSObject {
    //MTCoreAudioDevice *inputDevice;
    lame_global_flags *lame_flags;
    NSMutableData *wavData;
    //int STOP;
    //ALCdevice *device;
    /*AVCaptureSession *session;
    AVCaptureAudioDataOutput *dataout;
    AVCaptureAudioPreviewOutput *prevout;
    AVCaptureDevice *device;*/
    //AudioQueueRef aq;
    MyRecorder aqr;
    id delegate;
}
@property (readonly) NSMutableData *pcmData;
@property (readonly) NSMutableData *lameData;
@property (assign) id delegate;
@end
