//
//  FFmpegPresenter.m
//  TestFFmpeg
//
//  Created by anker on 2022/1/20.
//

#import "FFmpegPresenter.h"
#import "AudioRecord.hpp"
#import "AudioEncoder.hpp"
#import "SDLPlayer.hpp"
#import "AudioResample.hpp"

extern "C" {
#include <libavdevice/avdevice.h>
}


@interface FFmpegPresenter() {
    AudioRecord _audioRecorder;
}

@property (strong, nonatomic) NSString *path;

@end

@implementation FFmpegPresenter

+ (void)load {
    avdevice_register_all();
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioRecorder = AudioRecord();
        _audioRecorder.initDevice();
    }
    return self;
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

- (void)playPCM {
    const char *pcm_path = [self.path cStringUsingEncoding:NSString.defaultCStringEncoding];
    SDLPlayer player = SDLPlayer();
    player.initSDL();
    player.play_pcm(pcm_path);
}

- (void)playWAV {
    NSString *wavPath = [self.path.stringByDeletingPathExtension stringByAppendingPathExtension:@"wav"];
    const char *wav_path = [wavPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    SDLPlayer player = SDLPlayer();
    player.initSDL();
    player.play_wav(wav_path);
}

- (void)resamlePCM:(NSString *)path {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self startRecordPCMWithPath:path];
    });
    [self performSelector:@selector(startResamplePCM) withObject:nil afterDelay:10.0];
}

- (void)startResamplePCM {
    [self stopRecordPCM];
    const char *pcm_path = [self.path cStringUsingEncoding:NSString.defaultCStringEncoding];
    ResampleAudioSpec inSpec;
    inSpec.filename = pcm_path;
    inSpec.sampleRate = 44100;
    inSpec.sampleFmt = AV_SAMPLE_FMT_S16;
    inSpec.chLayout = AV_CH_LAYOUT_MONO;
    
    NSString *outPath = [self.path.stringByDeletingPathExtension stringByAppendingString:@"2.pcm"];
    const char *out_path = [outPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    ResampleAudioSpec outSpec;
    outSpec.filename = out_path;
    outSpec.sampleRate = 48000;
    outSpec.sampleFmt = AV_SAMPLE_FMT_FLT;
    outSpec.chLayout = AV_CH_LAYOUT_STEREO;

    AudioResample::resampleAudio(inSpec, outSpec);
}

@end
