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
    AudioRecord *_audioRecorder;
    SDLPlayer *_player;
}

@property (strong, nonatomic) NSString *path;

@end

@implementation FFmpegPresenter

+ (void)load {
    avdevice_register_all();
}

- (void)dealloc {
    delete _audioRecorder;
    delete _player;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioRecorder = new AudioRecord();
        _player = new SDLPlayer();
    }
    return self;
}

- (BOOL)startRecordPCMWithPath:(NSString *)path {
    self.path = path;
    const char *c_path = [path cStringUsingEncoding:NSString.defaultCStringEncoding];
    return _audioRecorder->startRecordAudio(c_path);
}

- (void)stopRecordPCM {
    _audioRecorder->stopRecordAudio();
}

- (void)encodePCM:(NSString *)pcmPath ToWAV:(NSString *)wavPath {
    const char *pcm_path = [pcmPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    const char *wav_path = [wavPath cStringUsingEncoding:NSString.defaultCStringEncoding];

    WAVHeader header;
    header.numChannels = 1;
    header.sampleRate = 44100;
    header.bitsPerSample = 16;
    
    AudioEncoder::pcm2wav(pcm_path, header, wav_path);
}

- (BOOL)playRecordedPCM {
    // SDL_audio AUDIO_S16LSB 0x8010
    return [self playPCM:self.path sampleRate:44100 format:0x8010 channle:1];
}

- (BOOL)playPCM:(NSString *)pcmPath sampleRate:(NSInteger)sampleRate format:(NSInteger)format channle:(NSInteger)channel {
    const char *pcm_path = [pcmPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    NSLog(@"%s", pcm_path);
    SDLPlayer::PCMHeader header;
    header.sample_rate = (uint32_t)sampleRate;
    header.channels = channel;
    header.sample_format = (uint32_t)format;
    return _player->playPCM(pcm_path, header);
}

- (BOOL)playWAV:(NSString *)wavPath {
    const char *wav_path = [wavPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    return _player->playWAV(wav_path);
}

- (void)stopPlay {
    _player->stopPlay();
}

- (void)resamlePCM:(NSString *)path toSampleRate:(NSInteger)sampleRate saveTo:(NSString *)savePath {
    const char *pcm_path = [path cStringUsingEncoding:NSString.defaultCStringEncoding];
    ResampleAudioSpec inSpec;
    inSpec.filename = pcm_path;
    inSpec.sampleRate = 44100;
    inSpec.sampleFmt = AV_SAMPLE_FMT_S16;
    inSpec.chLayout = AV_CH_LAYOUT_MONO;
    
    const char *out_path = [savePath cStringUsingEncoding:NSString.defaultCStringEncoding];
    ResampleAudioSpec outSpec;
    outSpec.filename = out_path;
    outSpec.sampleRate = (int)sampleRate;
    outSpec.sampleFmt = AV_SAMPLE_FMT_FLT;
    outSpec.chLayout = AV_CH_LAYOUT_STEREO;

    AudioResample::resampleAudio(inSpec, outSpec);
}

- (BOOL)playResamplePCM:(NSString *)path sampleRate:(NSInteger)sampleRate {
    // SDL_audio AUDIO_F32LSB 0x8120
    return [self playPCM:path sampleRate:sampleRate format:0x8120 channle:2];
}

@end
