//
//  SDLPlayer.cpp
//  AudioBox
//
//  Created by anker on 2022/2/7.
//

#include "SDLPlayer.hpp"
#include <iostream>
#include <fstream>


SDLPlayer::SDLPlayer():
_sample_rate(44100),
_sample_format(AUDIO_S16LSB),
_sample_size(SDL_AUDIO_BITSIZE(_sample_format)),
_channels(1),
_samples(1024),
bytes_pre_sample((_sample_size * _channels) / 8),
buffer_size(_samples * bytes_pre_sample)
{
    
}

extern void pull_audio_data(void *userdata, Uint8 *stream, int len);

bool SDLPlayer::initSDL() {
// print SDL version
    SDL_version v;
    SDL_VERSION(&v);
    printf("SDL Version: %d.%d.%d\n", v.major, v.minor, v.patch);
// init SDL
    SDL_SetMainReady();
    int res = SDL_Init(SDL_INIT_AUDIO);
    if (res != 0) {
        const char *error = SDL_GetError();
        cout<< "初始化 SDL 失败: "<< error <<endl;
        return false;
    }
    
// open audio
    spec.freq = _sample_rate;
    spec.format = _sample_format;
    spec.channels = _channels;
    spec.samples = _samples;
    spec.callback = pull_audio_data;
    spec.userdata = &buffer;
    
    res = SDL_OpenAudio(&spec, nullptr);
    if (res != 0) {
        cout<< "SDL Open Audio Failed!!!" <<endl;
        SDL_Quit();
        return false;
    }
    return true;
}

bool SDLPlayer::play_file(string file_path) {
// open file
    ifstream audioFile(file_path, ios::in);
    if (audioFile.is_open() == false) {
        cout<<"error: file_path 打开文件失败！"<<endl;
        SDL_CloseAudio();
        SDL_Quit();
        return false;
    }
    // 开始播放
    SDL_PauseAudio(0);
    char data[1024 * 10];
    
    while (!isInterruptionRequested()) {
        // 只要从文件中读取的音频数据，还没有填充完毕，就跳过
        if (buffer.len > 0) continue;
        buffer.len = (int)audioFile.read(data, buffer_size).gcount();
        printf("buffer.len = %d\n", buffer.len);
        if (buffer.len <= 0) {
            int samples = buffer.pullLen / bytes_pre_sample;
            int ms = samples * 1000 / _sample_rate;
            SDL_Delay(ms);
            break;
        }
        buffer.data = (uint8_t *)data;
        SDL_Delay(20);
    }
    audioFile.close();
    SDL_CloseAudio();
    SDL_Quit();
    return true;
}

bool SDLPlayer::isInterruptionRequested() {
    return false;
}

void pull_audio_data(void *userdata, Uint8 *stream, int len) {
    // 清空stream
    SDL_memset(stream, 0, len);
    printf("%d\n", len);
    // 去除缓存信息
    SDLPlayer::AudioBuffer *buffer = (SDLPlayer::AudioBuffer *)userdata;
    if (buffer->len == 0) return;
    buffer->pullLen = (len > buffer->len) ? buffer->len : len;
    
    // 填充数据
    SDL_MixAudio(stream, buffer->data, buffer->pullLen, SDL_MIX_MAXVOLUME);
    buffer->data += buffer->pullLen;
    buffer->len -= buffer->pullLen;
}
