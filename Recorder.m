//
//  Recorder.m
//  Recorder
//
//  Created by Daniel Ringwalt on 11/29/11.
//

#import "Recorder.h"
#include <lame/lame.h>
#import "AudioDocument.h"

#define kNumberRecordBuffers	3

@implementation Recorder

// ____________________________________________________________________________________
// Determine the size, in bytes, of a buffer necessary to represent the supplied number
// of seconds of audio data.
static int MyComputeRecordBufferSize(const AudioStreamBasicDescription *format, AudioQueueRef queue, float seconds)
{
	int packets, frames, bytes;
	
	frames = (int)ceil(seconds * format->mSampleRate);
	
	if (format->mBytesPerFrame > 0)
		bytes = frames * format->mBytesPerFrame;
	else {
		UInt32 maxPacketSize;
		if (format->mBytesPerPacket > 0)
			maxPacketSize = format->mBytesPerPacket;	// constant packet size
		else {
			UInt32 propertySize = sizeof(maxPacketSize); 
			if(AudioQueueGetProperty(queue, kAudioConverterPropertyMaximumOutputPacketSize, &maxPacketSize,
									 &propertySize) != 0)
				fprintf(stderr, "couldn't get queue's maximum output packet size");
		}
		if (format->mFramesPerPacket > 0)
			packets = frames / format->mFramesPerPacket;
		else
			packets = frames;	// worst-case scenario: 1 frame in a packet
		if (packets == 0)		// sanity check
			packets = 1;
		bytes = packets * maxPacketSize;
	}
	return bytes;
}

// ____________________________________________________________________________________
// AudioQueue callback function, called when a property changes.
static void MyPropertyListener(void *userData, AudioQueueRef queue, AudioQueuePropertyID propertyID)
{
	Recorder *aqr = (__bridge Recorder *)userData;
	if (propertyID == kAudioQueueProperty_IsRunning)
		aqr.queueStartStopTime = CFAbsoluteTimeGetCurrent();
}

// ____________________________________________________________________________________
// AudioQueue callback function, called when an input buffers has been filled.
static void MyInputBufferHandler(void *						  inUserData,
								 AudioQueueRef				   inAQ,
								 AudioQueueBufferRef			 inBuffer,
								 const AudioTimeStamp *		  inStartTime,
								 UInt32							inNumPackets,
								 const AudioStreamPacketDescription *inPacketDesc)
{
	Recorder *aqr = (__bridge Recorder *)inUserData;
	
	@autoreleasepool {
		if (aqr.verbose) {
			fprintf(stderr, "buf data %p, 0x%x bytes, 0x%x packets\n", inBuffer->mAudioData,
					(int)inBuffer->mAudioDataByteSize, (int)inNumPackets);
		}
		
		if (inNumPackets > 0) {
			long originalPcmLength = aqr.pcmData.length;
			[aqr.pcmData appendBytes: inBuffer->mAudioData length: inBuffer->mAudioDataByteSize];
			aqr.recordPacket += inNumPackets;
			
			UInt32 bytesPerPacket = aqr.recordingFormat.mBytesPerPacket;
			Float64 sampleRate = aqr.recordingFormat.mSampleRate;
			[aqr.delegate recordedPcmSamples:inBuffer->mAudioData count:inBuffer->mAudioDataByteSize/bytesPerPacket
									   start:(double)originalPcmLength / (bytesPerPacket * sampleRate)
										 end:(double)aqr.pcmData.length / (bytesPerPacket * sampleRate)];
		}
		
		// if we're not stopping, re-enqueue the buffer so that it gets filled again
		if (aqr.running)
			if (AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL) != 0)
				fprintf(stderr, "AudioQueueEnqueueBuffer failed");
	} 
}

// ____________________________________________________________________________________
// get sample rate of the default input device
OSStatus	MyGetDefaultInputDeviceSampleRate(Float64 *outSampleRate)
{
	OSStatus err;
	AudioDeviceID deviceID = 0;
	
	// get the default input device
	AudioObjectPropertyAddress addr;
	UInt32 size;
	addr.mSelector = kAudioHardwarePropertyDefaultInputDevice;
	addr.mScope = kAudioObjectPropertyScopeGlobal;
	addr.mElement = 0;
	size = sizeof(AudioDeviceID);
	err = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &addr, 0, NULL, &size, &deviceID);
	if (err) return err;
	
	// get its sample rate
	addr.mSelector = kAudioDevicePropertyNominalSampleRate;
	addr.mScope = kAudioObjectPropertyScopeGlobal;
	addr.mElement = 0;
	size = sizeof(Float64);
	err = AudioHardwareServiceGetPropertyData(deviceID, &addr, 0, NULL, &size, outSampleRate);
	
	return err;
}

- (instancetype)init {
	return [self initWithRecordingFormat:NULL];
}

- (instancetype)initWithRecordingFormat:(AudioStreamBasicDescription *)recordingFormatRef {
	self = [super init];
	if (self) {
		_pcmData = [NSMutableData new];
		
		if (recordingFormatRef == NULL) {
			// adapt record format to hardware and apply defaults
			//if (_recordingFormat.mSampleRate == 0.)
			_recordingFormat.mSampleRate = 44100;
			
			//if (_recordingFormat.mChannelsPerFrame == 0)
			_recordingFormat.mChannelsPerFrame = 2;
			
			_recordingFormat.mFormatID = kAudioFormatLinearPCM;
			if (_recordingFormat.mFormatID == 0 || _recordingFormat.mFormatID == kAudioFormatLinearPCM) {
				// default to PCM, 16 bit int
				_recordingFormat.mFormatID = kAudioFormatLinearPCM;
				_recordingFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
				_recordingFormat.mBitsPerChannel = 16;
				_recordingFormat.mBytesPerPacket = _recordingFormat.mBytesPerFrame =
				(_recordingFormat.mBitsPerChannel / CHAR_BIT) * _recordingFormat.mChannelsPerFrame;
				_recordingFormat.mFramesPerPacket = 1;
				_recordingFormat.mReserved = 0;
			}
		}
		else {
			_recordingFormat = *recordingFormatRef;
		}
	}
	
	// create the queue
	if (AudioQueueNewInput(&_recordingFormat,
						   MyInputBufferHandler,
						   (__bridge void *)self /* userData */,
						   NULL /* run loop */, NULL /* run loop mode */,
						   0 /* flags */, &(_queue)) != 0) {
		fprintf(stderr, "AudioQueueNewInput failed");
		return nil;
	}
	
	// get the record format back from the queue's audio converter --
	// the file may require a more specific stream description than was necessary to create the encoder.
	UInt32 recordingFormatSize = sizeof(_recordingFormat);
	if (AudioQueueGetProperty(_queue, kAudioConverterCurrentOutputStreamDescription,
							  &_recordingFormat, &recordingFormatSize) != 0)
		fprintf(stderr, "couldn't get queue's format");
	
	// allocate and enqueue buffers
	int bufferByteSize = MyComputeRecordBufferSize(&_recordingFormat, _queue, 0.01);
	for (int i = 0; i < kNumberRecordBuffers; ++i) {
		AudioQueueBufferRef buffer;
		if (AudioQueueAllocateBuffer(_queue, bufferByteSize, &buffer) != 0)
			fprintf(stderr, "AudioQueueAllocateBuffer failed");
		if (AudioQueueEnqueueBuffer(_queue, buffer, 0, NULL) != 0)
			fprintf(stderr, "AudioQueueEnqueueBuffer failed");
	}
	
	return self;
}

- (void)start {
	NSLog(@"start");
	self.running = TRUE;
	if (AudioQueueStart(_queue, NULL) != 0)
		fprintf(stderr, "AudioQueueStart failed");
}
- (void)stop {
	self.running = FALSE;
	if (AudioQueueStop(_queue, TRUE) != 0)
		fprintf(stderr, "AudioQueueStop failed");
}

- (NSData *)lameData {
	lame_flags = lame_init();
	lame_set_num_samples(lame_flags, _pcmData.length/4);
	lame_set_in_samplerate(lame_flags, _recordingFormat.mSampleRate);
	lame_set_num_samples(lame_flags, 2);
	lame_set_VBR(lame_flags, vbr_mtrh);
	lame_set_VBR_q(lame_flags, 0);
	lame_set_errorf(lame_flags, NULL);
	lame_set_bWriteVbrTag(lame_flags, true);
	if (lame_init_params(lame_flags) == -1)
		NSLog(@"<Error> in lame");
	int mp3len = (int)(_pcmData.length*1.25/2) + 7200;
	unsigned char *mp3buf = malloc(mp3len);
	int result = lame_encode_buffer_interleaved(lame_flags, (short*)_pcmData.bytes, _pcmData.length/4, mp3buf, mp3len);
	if (result <= 0) {
		NSLog(@"<Error> from lame: %d", result);
		return nil;
	}
	result += lame_encode_flush(lame_flags, mp3buf, mp3len);
	const int lametag_size = 2880;
	unsigned char *lametag = malloc(lametag_size);
	size_t taglen = lame_get_lametag_frame(lame_flags, lametag, lametag_size);
	if (taglen > 0) bcopy(lametag, mp3buf, taglen);
	return [NSData dataWithBytesNoCopy:mp3buf length:result freeWhenDone:YES];
}

- (void)writeTagsFid:(FILE *)fid {
	lame_mp3_tags_fid(lame_flags, fid);
}

@end
