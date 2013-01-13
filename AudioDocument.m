//
//  AudioDocument.m
//  Recorder
//
//  Created by Daniel Ringwalt on 12/26/11.
//

#import "AudioDocument.h"

@implementation AudioDocument
@synthesize audioView, recordButton;

- (instancetype)init
{
	self = [super init];
	if (self) {
		recorder = [Recorder new];
		recorder.delegate = self;
	}
	return self;
}

- (NSString *)windowNibName {
	return @"AudioDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSData *pcm = [recorder pcmData];
	if (pcm) {
		if ([typeName isEqualToString:@"com.microsoft.waveform-audio"]) {
			NSMutableData *wav = [NSMutableData dataWithBytes:"\x52\x49\x46\x46\x00\x00\x00\x00\x57\x41\x56\x45\x66\x6d\x74\x20\x10\x00\x00\x00\x01\x00\x02\x00\x44\xac\x00\x00\x10\xb1\x02\x00\x04\x00\x10\x00\x64\x61\x74\x61" length:40];
			unsigned long len = pcm.length;
			int i;
			unsigned char lendian[4];
			for (i = 0; i < 4; i++) {
				lendian[i] = (len % 256);
				len /= 256;
			}
			[wav appendBytes: lendian length: 4];
			[wav appendData: pcm];
			return wav;
		}
		else if ([typeName isEqualToString:@"public.mp3"]) {
			return [recorder lameData];
		}
		else NSLog(@"unknown typeName %@", typeName);
	}
	return nil;
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type error:(NSError **)err {
	NSError *dataError = nil;
	NSData *data = [self dataOfType:type error:&dataError];
	if (dataError) {
		if (err) *err = dataError;
		return NO;
	}
	FILE *fout = fopen([fileName UTF8String], "w+");
	if (fout == NULL) {
		NSLog(@"Error %s\n", strerror(errno));
		if (err) *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
		return NO;
	}
	fwrite(data.bytes, data.length, 1, fout);
	if ([type isEqualToString: @"public.mp3"]) {
		[recorder writeTagsFid:fout];
	}
	fclose(fout);
	return YES;
}
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type {
	return [self writeToFile:fileName ofType:type error:NULL];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	/*
	Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
	You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
	If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
	*/
	if (outError) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return YES;
}

+ (BOOL)autosavesInPlace
{
	return YES;
}

- (void)_updateAVTime {
	@autoreleasepool {
		while (recording) {
			audioView.position = audioView.length = [recorder pcmData].length / 4 / 44100.;
			usleep(50000);
		}
	}
}

- (IBAction)recordClicked:(NSButton *)sender {
	switch (sender.state) {
		case 0:
			[recorder stop];
			recording = NO;
			[audioView setIsRecording: NO];
			break;
		case 1:
			// Open new document if there is already a recording
			if (recorder.pcmData.length > 0) {
				sender.state = 0;
				NSError *err = nil;
				AudioDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&err];
				if (err) NSLog(@"Couldn't open new recording: %@", err);
				else {
					NSLog(@"doc %@", doc);
					[doc.recordButton setState: 1];
					[doc recordClicked: doc.recordButton];
					return;
				}
			}
			[recorder start];
			recording = YES;
			[audioView setIsRecording: YES];
			[self performSelectorInBackground: @selector(_updateAVTime) withObject: nil];
	}
}

- (void)recordedPcmSamples:(void *)samples count:(long)count
					 start:(double)start
					   end:(double)end {
	//printf("%f -> %f\n", start, end);
	[audioView displayPcmSamples:samples count:count startTime:start endTime:end];
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
	return nil;
}

@end
