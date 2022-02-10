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
#import "AudioDecoder.hpp"

extern "C" {
#include <libavdevice/avdevice.h>
}

@interface FFmpegPresenter() {
    AudioRecord *_audioRecorder;
    SDLPlayer *_player;
}

@property (strong, nonatomic) NSString *currentPath;
@property (assign, nonatomic) NSInteger currentSampleRate;
@property (assign, nonatomic) NSInteger currentSampleFormat;
@property (assign, nonatomic) NSInteger currentChannels;

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
        _currentSampleRate = 44100;
        _currentSampleFormat = 0x8010;     // SDL_audio AUDIO_S16LSB 0x8010
        _currentChannels = 1;
    }
    return self;
}

- (BOOL)startRecordPCMWithPath:(NSString *)path {
    self.currentPath = path;
    self.currentSampleRate = 44100;
    self.currentSampleFormat = 0x8010;  // SDL_audio AUDIO_S16LSB 0x8010
    self.currentChannels = 1;
    
    self.currentPath = path;
    const char *c_path = [path cStringUsingEncoding:NSString.defaultCStringEncoding];
    return _audioRecorder->startRecordAudio(c_path);
}

- (void)stopRecordPCM {
    _audioRecorder->stopRecordAudio();
}

- (BOOL)playRecordedPCM {
    return [self playCurrentPCM];
}

- (BOOL)playCurrentPCM {
    return [self playPCM:self.currentPath sampleRate:self.currentSampleRate format:self.currentSampleFormat channle:self.currentChannels];
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
    self.currentPath = savePath;
    self.currentSampleRate = sampleRate;
    self.currentSampleFormat = 0x8120; // SDL_audio AUDIO_F32LSB 0x8120
    self.currentChannels = 2;
    
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

- (BOOL)playResamplePCM {
    return [self playCurrentPCM];
}

// MARK: Encode
- (void)encodePCM:(NSString *)pcmPath ToWAV:(NSString *)wavPath {
    const char *pcm_path = [pcmPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    const char *wav_path = [wavPath cStringUsingEncoding:NSString.defaultCStringEncoding];

    WAVHeader header;
    header.numChannels = 1;
    header.sampleRate = 44100;
    header.bitsPerSample = 16;
    
    AudioEncoder::pcm2wav(pcm_path, header, wav_path);
}

- (void)encodePCM:(NSString *)pcmPath ToAAC:(nonnull NSString *)aacPath {
    const char *pcm_path = [pcmPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    const char *aac_path = [aacPath cStringUsingEncoding:NSString.defaultCStringEncoding];

    AudioEncodeSpec spec;
    spec.filename = pcm_path;
    spec.sampleRate = 44100;
    spec.sampleFmt = AV_SAMPLE_FMT_S16;
    spec.chLayout = AV_CH_LAYOUT_MONO;
    
    AudioEncoder::pcm2aac(spec, aac_path);
}

- (void)decodeAAC:(NSString *)aacPath saveTo:(NSString *)pcmPath {
    const char *acc_path = [aacPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    const char *pcm_path = [pcmPath cStringUsingEncoding:NSString.defaultCStringEncoding];
    AudioDecodeSpec spec;
    spec.filename = pcm_path;
    AudioDecoder::aacDecode(acc_path, spec);
    
    self.currentPath = pcmPath;
    self.currentSampleRate = spec.sampleRate;
    self.currentSampleFormat = 0x8010;
    self.currentChannels = av_get_channel_layout_nb_channels(spec.chLayout);
    NSLog(@"pcm sample rate: %d", spec.sampleRate);
    NSLog(@"pcm sample format: %s", av_get_sample_fmt_name(spec.sampleFmt));
    NSLog(@"pcm channels: %d", av_get_channel_layout_nb_channels(spec.chLayout));
}

- (BOOL)playDecodedPCM {
    return [self playCurrentPCM];
}

@end
