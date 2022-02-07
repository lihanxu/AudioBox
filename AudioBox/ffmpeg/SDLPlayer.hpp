//
//  SDLPlayer.hpp
//  AudioBox
//
//  Created by anker on 2022/2/7.
//

#ifndef SDLPlayer_hpp
#define SDLPlayer_hpp

#include <stdio.h>
#include <string>
#include <libSDL2/SDL.h>

using namespace std;

class SDLPlayer {
    
public:
    typedef struct AudioBufferS {
        int len = 0;
        int pullLen = 0;
        uint8_t *data = nullptr;
    } AudioBuffer;
    
    SDLPlayer();
    // 采样率
    uint32_t _sample_rate;
    // 采样格式
    uint32_t _sample_format;
    // 采样大小
    uint16_t _sample_size;
    // 声道数
    uint16_t _channels;
    // 音频缓冲区的样本数量
    uint16_t _samples;
    
    bool initSDL();
    bool play_file(string file_path);
    
private:
    uint16_t bytes_pre_sample;
    
    SDL_AudioSpec spec;
    AudioBuffer buffer;
    uint32_t buffer_size;
    
    bool isInterruptionRequested();
};
#endif /* SDLPlayer_hpp */
