//
//  EarsBack.m
//  LiveStudio
//
//  Created by hxli on 2020/4/13.
//  Copyright © 2020 ImageVision. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "EarsBack.h"
#import "ErrorCheck.h"

@interface EarsBack() {
    AUGraph _audioGraph;
    AUNode _playerNode;
    AudioUnit _playerUnit;
}

@end

@implementation EarsBack

- (void)dealloc {
    AUGraphStop(self->_audioGraph);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
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
    
    UInt32 flag = 1;
    status = AudioUnitSetProperty(_playerUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, INPUT_BUS, &flag, sizeof (flag));
    status = AudioUnitSetProperty(_playerUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, OUTPUT_BUS, &flag, sizeof(flag));
    
    AudioStreamBasicDescription outputFormat;
    bzero(&outputFormat, sizeof(outputFormat));
    outputFormat.mSampleRate       = 44100.0;
    outputFormat.mFormatID         = kAudioFormatLinearPCM;
    outputFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    outputFormat.mFramesPerPacket  = 1;
    outputFormat.mChannelsPerFrame = 1;
    outputFormat.mBitsPerChannel   = 16;
    outputFormat.mBytesPerFrame    = outputFormat.mBitsPerChannel / 8 * outputFormat.mChannelsPerFrame;
    outputFormat.mBytesPerPacket   = outputFormat.mBytesPerFrame * outputFormat.mFramesPerPacket;
    
    status = AudioUnitSetProperty(_playerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, OUTPUT_BUS, &outputFormat, sizeof(outputFormat));
    CheckStatus(status, @"Could not StreamFormat", YES);
    status = AudioUnitSetProperty(_playerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, INPUT_BUS, &outputFormat, sizeof(outputFormat));
    CheckStatus(status, @"Could not StreamFormat", YES);
    
    AURenderCallbackStruct renderCB;
    renderCB.inputProc = &EarsPlayCallback;
    renderCB.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(_playerUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, OUTPUT_BUS, &renderCB, sizeof(renderCB));
//    AUGraphSetNodeInputCallback(_audioGraph, _playerNode, 0, &renderCB);
    CheckStatus(status, @"AUGraphSetNodeInputCallback failed", YES);
}

#pragma mark - Action
- (void)start
{
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Boolean isRunning;
        AUGraphIsRunning(self->_audioGraph, &isRunning);
        if (isRunning) {
            AUGraphStop(self->_audioGraph);
        }
    });
}

#pragma mark - Callback
OSStatus EarsPlayCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    EarsBack *earsBack = (__bridge EarsBack *)inRefCon;
    OSStatus err = AudioUnitRender(earsBack->_playerUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    if(err != noErr) {
        NSLog(@"audio unit render error!!! %d", err);
    }
    return err;
}

@end
