//
//  AudioResample.hpp
//  AudioBox
//
//  Created by anker on 2022/2/8.
//

#ifndef AudioResamle_hpp
#define AudioResamle_hpp

#include <stdio.h>

extern "C" {
#include <libavcodec/avcodec.h>
}

typedef struct ResampleAudioSpec {
    const char *filename;
    int sampleRate;
    AVSampleFormat sampleFmt;
    int chLayout;
} ResampleAudioSpec;

class AudioResample {
public:
    static void resampleAudio(ResampleAudioSpec &in, ResampleAudioSpec &out);
};

#endif /* AudioResamle_hpp */
