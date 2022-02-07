//
//  KarplusStrongPlayer.m
//  LiveStudio
//
//  Created by hxli on 2019/8/20.
//  Copyright © 2019年 ImageVision. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "KarplusStrongPlayer.h"
#import "ErrorCheck.h"

#define Count (70)

@interface KarplusStrongPlayer() {
    AUGraph _audioGraph;
    AUNode _playerNode;
    AudioUnit _playerUnit;
    
    AudioStreamBasicDescription _outputFormat;
    
    double _frequency;
    double _sampleRate;
    double _theta;
    double _amplitude;
    Float32 _buffer[Count * 2];
    NSInteger _index;
    NSInteger _count;
}

@property (strong, nonatomic) NSTimer *timer;

@end


@implementation KarplusStrongPlayer

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _frequency = 440; //Hz
        _sampleRate = 44100; //Hz
        _theta = 0;
        _amplitude = 0.25;
        _index = 0;
        _count = Count;
        [self initAudioGraph];
    }
    return self;
}

- (void)initAudioGraph
{
    OSStatus status = noErr;
    status = NewAUGraph(&_audioGraph);
    CheckStatus(status, @"new AUGraph failed", YES);
    [self initAudioNode];
    
    status = AUGraphOpen(_audioGraph);
    CheckStatus(status, @"open graph failed", YES);
    
    [self setAudioUnitProperty];
    
    AUGraphInitialize(_audioGraph);
    status = AUGraphUpdate(_audioGraph, NULL);
    CheckStatus(status, @"Could not Update AUGraph", YES);
}

- (void)initAudioNode
{
    OSStatus status = noErr;
    
    AudioComponentDescription ioDes;
    bzero(&ioDes, sizeof(ioDes));
    ioDes.componentType = kAudioUnitType_Output;
//    ioDes.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    ioDes.componentSubType = kAudioUnitSubType_RemoteIO;
    ioDes.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioDes.componentFlags = 0;
    ioDes.componentFlagsMask = 0;
    status = AUGraphAddNode(_audioGraph, &ioDes, &_playerNode);
    CheckStatus(status, @"Add _playerNode failed", YES);
}

- (void)setAudioUnitProperty
{
    OSStatus status = noErr;
    // Get audio unit
    status = AUGraphNodeInfo(_audioGraph, _playerNode, NULL, &_playerUnit);
    CheckStatus(status, @"Could not retrieve node info for _playerNode", YES);
    
    // Set the format to 32 bit, single channel, floating point, linear PCM
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte = 8;
    bzero(&_outputFormat, sizeof(_outputFormat));
    _outputFormat.mSampleRate       = 44100.0;
    _outputFormat.mFormatID         = kAudioFormatLinearPCM;
//    _outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _outputFormat.mFormatFlags      = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    _outputFormat.mFramesPerPacket  = 1;
    _outputFormat.mChannelsPerFrame = 1;
    _outputFormat.mBitsPerChannel   = four_bytes_per_float * eight_bits_per_byte;
    _outputFormat.mBytesPerFrame    = four_bytes_per_float;
    _outputFormat.mBytesPerPacket   = four_bytes_per_float;
    
    status = AudioUnitSetProperty(_playerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, OUTPUT_BUS, &_outputFormat, sizeof(_outputFormat));
    CheckStatus(status, @"Could not StreamFormat", YES);
    
    AURenderCallbackStruct renderCB;
    renderCB.inputProc = &PlayCallback;
    renderCB.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(_playerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, OUTPUT_BUS, &renderCB, sizeof(renderCB));
    CheckStatus(status, @"_audioMixerNode AUGraphSetNodeInputCallback failed", YES);
    UInt32 flag = 1;
    status = AudioUnitSetProperty(_playerUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, OUTPUT_BUS, &flag, sizeof(flag));
}

#pragma mark - Action
- (void)start
{
    [self createTimer];
    // AUGraphStart is time-consuming
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Boolean isRunning;
        AUGraphIsRunning(self->_audioGraph, &isRunning);
        if (isRunning == NO) {
            AUGraphStart(self->_audioGraph);
        }
    });
}

- (void)stop
{
    [self cancelTimer];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Boolean isRunning;
        AUGraphIsRunning(self->_audioGraph, &isRunning);
        if (isRunning) {
            AUGraphStop(self->_audioGraph);
        }
    });
}

- (void)updateFrequency:(double)frequency {
    _frequency = frequency;
}

- (void)cancelTimer {
    if (self.timer == nil) {
        return;
    }
    [self.timer invalidate];
    self.timer = nil;
}

- (void)createTimer {
    [self cancelTimer];
    __weak KarplusStrongPlayer *sself = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [sself createBuffer];
    }];
    [self.timer fire];
}

- (void)createBuffer {
    double amplitude = _amplitude;
    
    _count = _count + 5;
    _count = _count > Count * 2 ? Count : _count;
    
    double theta_increment = 2.0 * M_PI * _frequency / _sampleRate;
    for (int i = 0; i < _count; i++) {
        _buffer[i] = sin(_theta) * amplitude;
        _theta += theta_increment;
        if (_theta > 2.0 * M_PI) {
            _theta -= 2.0 * M_PI;
        }
    }
}

#pragma mark - Callback
OSStatus PlayCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    // Fixed amplitude is good enough for our purposes
//    const double amplitude = 0.25;

    KarplusStrongPlayer *player = (__bridge KarplusStrongPlayer *)inRefCon;
    
//    double theta = player->_theta;
//    double theta_increment = 2.0 * M_PI * player->_frequency / player->_sampleRate;
//
//    // This is a mono tone generator so we only need the first buffer
//    const int channel = 0;
//    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
//
//    // Generate the samples
//    for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
//        buffer[frame] = sin(theta) * amplitude;
//        theta += theta_increment;
//        if (theta > 2.0 * M_PI) {
//            theta -= 2.0 * M_PI;
//        }
//    }
//
//    // Store the theta back in the view controller
//    player->_theta = theta;
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    NSInteger count = player->_count;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
        buffer[frame] = (player->_buffer[player->_index] + player->_buffer[(player->_index + count - 1) % count]) / 2.0;
        player->_buffer[player->_index] = buffer[frame];
        player->_index = (player->_index + 1) % count;
    }

    return noErr;
}

@end
