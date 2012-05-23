//
//  AudioView.m
//  Recorder
//
//  Created by Daniel Ringwalt on 11/29/11.
//

#import "AudioView.h"

const double AUDIO_VIEW_PREVIEW_SIZE = 10.f;

@implementation AudioVolumeView
@dynamic volume, peakVolume;
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        self.layer.backgroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
        peakLayer = [CALayer new];
        peakLayer.frame = CGRectMake(1, 0, 2, self.layer.bounds.size.height);
        peakLayer.backgroundColor = CGColorCreateGenericRGB(1, 0, 0, 1);
        volumeLayer = [CALayer new];
        volumeLayer.frame = CGRectMake(0, 0, 1, self.layer.bounds.size.height);
        volumeLayer.backgroundColor = CGColorCreateGenericRGB(0, 0, 1, 1);
        [self.layer addSublayer: peakLayer];
        [self.layer addSublayer: volumeLayer];
    }
    return self;
}
- (void)setVolume:(double)_volume {
    volume = _volume;
    CGRect volFrame = volumeLayer.frame;
    volFrame.size.width = self.layer.bounds.size.width * volume;
    volumeLayer.frame = volFrame;
}
- (void)setPeakVolume:(double)_peakVolume {
    peakVolume = _peakVolume;
    CGRect frame = peakLayer.frame;
    frame.origin.x = (self.layer.bounds.size.width - 2) * peakVolume;
    peakLayer.frame = frame;
}
@end

@implementation AudioView
@synthesize position, length, volumeView;
@dynamic recording;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        progressLayer = [[CALayer alloc] init];
        progressLayer.backgroundColor = CGColorCreateGenericRGB(1, .1, .1, 1);
        self.wantsLayer = YES;
        progressLayer.frame = CGRectMake(0, 0, 1, self.layer.bounds.size.height);
        [self.layer addSublayer: progressLayer];
        self.layer.backgroundColor = CGColorCreateGenericRGB(1, 1, 1, 1);
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
}

- (void)setIsRecording:(BOOL)recording {
    NSLog(@"recording? %d", recording);
    isRecording = recording;
    if (isRecording) {
        double time = AUDIO_VIEW_PREVIEW_SIZE - length;
        if (time <= 0) {
            progressLayer.frame = self.layer.bounds;
            return;
        }
        CABasicAnimation *progressAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        progressAnimation.fromValue = [NSValue valueWithRect: NSMakeRect(0, 0,
                                                                         self.layer.bounds.size.width
                                                                             * length / AUDIO_VIEW_PREVIEW_SIZE,
                                                                         self.layer.bounds.size.height)];
        progressAnimation.toValue = [NSValue valueWithRect: NSMakeRect(0, 0,
                                                                       self.layer.bounds.size.width*2,
                                                                       self.layer.bounds.size.height)];
        progressAnimation.duration = 5.f;
        progressAnimation.fillMode = kCAFillModeForwards;
        progressAnimation.delegate = self;
        [progressLayer addAnimation: progressAnimation forKey: @"timeAnimate"];
    }
}

- (void)animationDidStop:(CABasicAnimation *)anim finished:(BOOL)flag {
    [CATransaction begin];
    [CATransaction setValue: (id)kCFBooleanTrue forKey: kCATransactionDisableActions];
    [progressLayer setValue: anim.toValue forKey: anim.keyPath];
    [CATransaction commit];
}

- (void)displayPcmSamples: (void *)samples count: (long)count startTime: (double)start endTime: (double)end {
    double average = 0;
    int32_t *pcm = (int32_t *)samples;
    if (start - peakTime > 2) {
        peakTime = start;
        peakAudio = 0;
    }
    int i;
    for (i = 0; i < count; i++) {
        double this = (double)abs(pcm[i]) / INT32_MAX;
        average += this / count;
    }
    if (average > peakAudio) peakAudio = average;
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    volumeView.volume = average;
    volumeView.peakVolume = peakAudio;
    [CATransaction commit];
}

@end
