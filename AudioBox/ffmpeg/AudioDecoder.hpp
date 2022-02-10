//
//  AudioDecoder.hpp
//  AudioBox
//
//  Created by anker on 2022/2/10.
//

#ifndef AudioDecoder_hpp
#define AudioDecoder_hpp

#include <stdio.h>
extern "C" {
#include <libavcodec/avcodec.h>
}

// 解码后的PCM参数
typedef struct {
    const char *filename;
    int sampleRate;
    AVSampleFormat sampleFmt;
    int chLayout;
} AudioDecodeSpec;

class AudioDecoder {
public:
    AudioDecoder();

    static void aacDecode(const char *inFilename, AudioDecodeSpec &out);
};


#endif /* AudioDecoder_hpp */
