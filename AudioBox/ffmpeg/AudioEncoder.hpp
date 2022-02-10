//
//  AudioEncoder.hpp
//  TestFFmpeg
//
//  Created by anker on 2022/1/26.
//

#ifndef AudioEncoder_hpp
#define AudioEncoder_hpp

#include <stdio.h>
#include <string>
extern "C" {
#include <libavcodec/avcodec.h>
}

using namespace std;

#define AUDIO_FORMAT_PCM 1
#define AUDIO_FORMAT_FLOAT 3

typedef struct WAVFileHeader {
    // RIFF chunk的id
    uint8_t riffChunkID[4] = {'R', 'I', 'F', 'F'};
    // RIFF chunk的data大小，即文件总长度减去8字节
    uint32_t riffChunkDataSize;
    // WAVE
    uint8_t format[4] = {'W', 'A', 'V', 'E'};
    // fmt chunk的id
    uint8_t fmtChunID[4] = {'f', 'm', 't', ' '};
    // fmt chunk的data大小：存储PCM数据时是16
    uint32_t fmtChunDataSize = 16;
    
    // fmt data 数据内容
    // 1. 2字节：音频编码， 1表示PCM，3表示Floating Point
    // 2. 2字节：声道数
    // 3. 4字节：采样率
    // 4. 4字节：字节率 = sampleRate * blockAlign
    // 5. 2字节：一个样本的字节数 = bitsPerSample * numChannels >> 3
    // 6. 2字节：位深度
    uint16_t audioFormat = AUDIO_FORMAT_PCM;
    uint16_t numChannels;
    uint32_t sampleRate;
    uint32_t byteRate;
    uint16_t blockAlign;
    uint16_t bitsPerSample;
    
    // data chunk id
    uint8_t dataChunkID[4] = {'d', 'a', 't', 'a'};
    // data chunk的data大小：音频数据的总长度，即文件总长度减去文件头的长度(一般是44)
    uint32_t dataChunkDataSize;
} WAVHeader;

typedef struct {
    const char *filename;
    int sampleRate;
    AVSampleFormat sampleFmt;
    int chLayout;
} AudioEncodeSpec;

class AudioEncoder {
public:
    AudioEncoder();
    static bool pcm2wav(string pcmPath, WAVHeader &header, string wavPath);
    static void pcm2aac(AudioEncodeSpec &in, const char *outFilename);
};

#endif /* AudioEncoder_hpp */
