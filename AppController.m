// AppController.h -- application controller for Recordotron

// Copyright (C) 2003 Borkware
// We use the BSD License.  Check out http://borkware.com/license


#import "AppController.h"
#import <MTCoreAudio/MTCoreAudio.h>

// about 25 seconds of recording time
#define SOUND_BUFFER_SIZE (8 * 1024 * 1024) 
static unsigned char g_soundBuffer[SOUND_BUFFER_SIZE];

// for recording and playback, this is where we are in the buffer
static int g_lastIndex;

// how much data is in the buffer
static int g_bufferSize;


@implementation AppController

// this is the MTCoreAudioDevice IO target for recording. It's
// callback saying that there is new data to be read.  Since we're
// just doing real simple buffering of data, and then regurgitating it
// when we play, we don't mess with too many of the arguments.

- (OSStatus) readCycleForDevice: (MTCoreAudioDevice *) theDevice 
		      timeStamp: (const AudioTimeStamp *) now 
		      inputData: (const AudioBufferList *) inputData 
		      inputTime: (const AudioTimeStamp *) inputTime 
		     outputData: (AudioBufferList *) outputData 
		     outputTime: (const AudioTimeStamp *) outputTime 
		     clientData: (void *) clientData
{
    // peer into the data

    const AudioBuffer *buffer;
    buffer = &inputData->mBuffers[0];

    // will this sample put us over the line?  If so, dump the data
    // and tell the UI to stop the recording and disable the Stop
    // button.  We don't stop the actual reading from here
    // because it seems to leave some stale locks in the MTCoreAudio
    // guts.

    if (g_lastIndex + buffer->mDataByteSize > SOUND_BUFFER_SIZE) {
	[self performSelectorOnMainThread: @selector(stopRecording:)
	      withObject: self
	      waitUntilDone: NO];

    } else {

	// append the data to the end of our buffer
	memcpy (g_soundBuffer + g_lastIndex,
		buffer->mData, buffer->mDataByteSize);
	g_lastIndex += buffer->mDataByteSize;
    }

    return (noErr);

} // readCycleForDevice



// the MTCoreAudioDevice IO target for playback.  We feed data from
// our buffer into the sound system

- (OSStatus) writeCycleForDevice: (MTCoreAudioDevice *) theDevice 
		       timeStamp: (const AudioTimeStamp *) now 
		       inputData: (const AudioBufferList *) inputData 
		       inputTime: (const AudioTimeStamp *) inputTime 
		      outputData: (AudioBufferList *) outputData 
		      outputTime: (const AudioTimeStamp *) outputTime 
		      clientData: (void *) clientData
{
    // are we done? 

    if (g_lastIndex >= g_bufferSize) {

	// yep.  tell the UI part to shut down the playback.
	[self performSelectorOnMainThread: @selector(stopPlaying:)
	      withObject: self
	      waitUntilDone: NO];

    } else {

	// otherwise stick some data into the buffer
	AudioBuffer *buffer;
	buffer = &outputData->mBuffers[0];
	
	memcpy (buffer->mData,
		g_soundBuffer + g_lastIndex,
		buffer->mDataByteSize);

	g_lastIndex += buffer->mDataByteSize;
    }
	
    return (noErr);
    
} // writeCycleForDevice


// update the UI based on the current sytem volume and input volume

- (void) setStuffBasedOnVolume
{
    MTCoreAudioVolumeInfo volumeInfo;

    volumeInfo = [inputDevice volumeInfoForChannel: 1
			      forDirection: kMTCoreAudioDeviceRecordDirection];
    [inputVolumeSlider setFloatValue: volumeInfo.theVolume];

    volumeInfo = [outputDevice volumeInfoForChannel: 1
			       forDirection: kMTCoreAudioDevicePlaybackDirection];
    [outputVolumeSlider setFloatValue: volumeInfo.theVolume];


} // setStuffBasedOnVolume



// we've been intantiated.  acquire our audio devices and set up the UI

- (void) awakeFromNib
{
    inputDevice = [MTCoreAudioDevice defaultInputDevice];
    [inputDevice retain];

    outputDevice = [MTCoreAudioDevice defaultOutputDevice];
    [outputDevice retain];

    // set up the recording callback
    [inputDevice setIOTarget: self
		 withSelector: @selector(readCycleForDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
		 withClientData: NULL];
    
    // set up the palyback callback
    [outputDevice setIOTarget: self
		  withSelector: @selector(writeCycleForDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
		  withClientData: NULL];

    // update the UI

    [self setStuffBasedOnVolume];
    
} // awakeFromNib



// clean up our mess

- (void) dealloc
{
    [inputDevice release];
    [outputDevice release];

    [super dealloc];

} // dealloc



// button handler.  kick off the recording

- (IBAction) startRecording: (id) sender
{
    // reset our buffer position to the start
    g_lastIndex = 0;
    g_bufferSize = 0;

    // update the UI so the user can stop the recording
    [recordStopButton setEnabled: YES];

    // start recording
    [inputDevice deviceStart];

} // startRecording



// button handler.  cease recording.

- (IBAction) stopRecording: (id) sender
{
    // stop recording
    [inputDevice deviceStop];

    // snarf how much data we've gotten
    g_bufferSize = g_lastIndex;

    // update the UI to turn off the 'stop' button
    [recordStopButton setEnabled: NO];

} // stopRecording



// button handler, start playback of our data

- (IBAction) startPlaying: (id) sender
{
    // start playing from the beginning
    g_lastIndex = 0;

    // update the UI so the user can stop the playback
    [playStopButton setEnabled: YES];

    // start playback
    [outputDevice deviceStart];

} // play



// button handler.  cease playback

- (IBAction) stopPlaying: (id) sender
{
    // stop playback
    [outputDevice deviceStop];

    // update the UI to turn off the 'stop' button
    [playStopButton setEnabled: NO];

} // stopPlaying



// slider action handler.  set the recording volume (the gain on the
// microphone)

- (IBAction) changeInputVolume: (id) sender
{
    // setting volume on channel zero (the master channel) doesn't
    // seem to affect the actual recording volume.  So set each
    // side of the input volume independently

    [inputDevice setVolume: [inputVolumeSlider floatValue]
		 forChannel: 1
		 forDirection: kMTCoreAudioDeviceRecordDirection];

    [inputDevice setVolume: [inputVolumeSlider floatValue]
		 forChannel: 2
		 forDirection: kMTCoreAudioDeviceRecordDirection];

} // changeInputVolume


// slider action handler.  set the playback volume.
- (IBAction) changeOutputVolume: (id) sender
{
    // setting volume on channel zero (the master channel) doesn't
    // seem to affect the actual playback volume.  So set each
    // side of the input volume independently

    [outputDevice setVolume: [outputVolumeSlider floatValue]
		 forChannel: 1
		 forDirection: kMTCoreAudioDevicePlaybackDirection];

    [outputDevice setVolume: [outputVolumeSlider floatValue]
		 forChannel: 2
		 forDirection: kMTCoreAudioDevicePlaybackDirection];
} // changeOutputVolume



@end // AppController


