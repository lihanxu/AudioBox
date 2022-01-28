//
//  FFmpegPresenter.m
//  TestFFmpeg
//
//  Created by anker on 2022/1/20.
//

#import "FFmpegPresenter.h"
#import "AudioRecord.hpp"
#import "AudioEncoder.hpp"

@interface FFmpegPresenter() {
    AudioRecord _audioRecorder;
}

@property (strong, nonatomic) NSString *path;

@end

@implementation FFmpegPresenter

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioRecorder = AudioRecord();
    }
    return self;
}

- (BOOL)initDevice {
    return _audioRecorder.initDevice();
}

- (void)startRecordPCMWithPath:(NSString *)path {
    self.path = path;
    const char *c_path = [path cStringUsingEncoding:NSString.defaultCStringEncoding];
    _audioRecorder.startRecordAudio(c_path);
}

- (void)stopRecordPCM {
    _audioRecorder.stopRecordAudio();
}

- (void)coverToWAV {
    NSString *wavPath = [self.path.stringByDeletingPathExtension stringByAppendingPathExtension:@"wav"];
    const char *pcm_path = [self.path cStringUsingEncoding:NSString.defaultCStringEncoding];
    const char *wav_path = [wavPath cStringUsingEncoding:NSString.defaultCStringEncoding];

    WAVHeader header;
    header.numChannels = 1;
    header.sampleRate = 44100;
    header.bitsPerSample = 16;
    
    AudioEncoder::pcm2wav(pcm_path, header, wav_path);
}

- (void)playWAV {
    
}


@end