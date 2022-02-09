//
//  SDLPlayer.cpp
//  AudioBox
//
//  Created by anker on 2022/2/7.
//

#include "SDLPlayer.hpp"
#include <iostream>
#include <fstream>
#include <libSDL2/SDL.h>
#include <thread>

class SDLPlayer::SDLPlayerImpl {
public:
    
private:
    typedef struct AudioBufferS {
        int len = 0;
        int pullLen = 0;
        uint8_t *data = nullptr;
    } AudioBuffer;

    string m_playType;
    bool m_isRunning;
    uint16_t m_samples;
    SDL_AudioSpec m_spec;
    AudioBuffer m_buffer;
    Uint8 *temData;
    ifstream m_audioFile;

public:
    SDLPlayerImpl()
        : m_playType("pcm"),
          m_isRunning(false),
          m_samples(1024),
          temData(nullptr) {
        // if start record pcm, sdl will be quit.
//        initSDL();
    }
    ~SDLPlayerImpl() {
        if (m_isRunning) {
            stopPlay();
        }
        SDL_Quit();
    }
    
    bool play_pcm(const char *file_path, PCMHeader &header) {
        if (m_isRunning) {
            cout<< "error: player is running." <<endl;
            return false;
        }
        // open file
        m_audioFile = ifstream(file_path, ios::in);
        if (m_audioFile.is_open() == false) {
            cout<< "error: file_path 打开文件失败！" << file_path <<endl;
            return false;
        }
        initSDL();
    // open audio
//        m_samples = ceil(1024 * header.sample_rate * 1.0 / 44100);
        m_spec.freq = header.sample_rate;
        m_spec.format = header.sample_format;
        m_spec.channels = header.channels;
        m_spec.samples = m_samples;
        m_spec.callback = pull_audio_data;
        m_spec.userdata = &m_buffer;
        
        int res = SDL_OpenAudio(&m_spec, nullptr);
        if (res != 0) {
            cout<< "SDL Open Audio Failed!!!" <<endl;
            cout<< "error: " << SDL_GetError() <<endl;
            return false;
        }
        
        // 开始播放
        cout<< "play pcm: " << file_path <<endl;
        thread t(&SDLPlayerImpl::readPCM, this);
        t.detach();
        return true;
    }

    bool play_wav(const char * file_path) {
        if (m_isRunning) {
            cout<< "error: player is running." <<endl;
            return false;
        }
        initSDL();
        Uint32 len;
        if (!SDL_LoadWAV(file_path, &m_spec, &temData, &len)) {
            cout<< "SDL load wav failed: "<< SDL_GetError() <<endl;
            return false;
        }
        m_buffer.len = len;
        m_buffer.data = temData;
        m_spec.callback = pull_audio_data;
        m_spec.userdata = &m_buffer;
        // 打开设备
        if (SDL_OpenAudio(&m_spec, nullptr) != 0) {
            cout<< "SDL_OpenAudio error:" << SDL_GetError() << endl;
            SDL_FreeWAV(temData);
            return false;
        }
        // 开始播放
        cout<< "play wav: " << file_path <<endl;
        m_playType = "wav";
        SDL_PauseAudio(0);
        
        return true;
    }
    
    void stopPlay() {
        m_isRunning = false;
        if (m_playType == "wav") {
            SDL_FreeWAV(temData);
        }
        SDL_CloseAudio();
    }
    
private:
    bool initSDL() {
    // print SDL version
//        SDL_version v;
//        SDL_VERSION(&v);
//        printf("SDL Version: %d.%d.%d\n", v.major, v.minor, v.patch);
    // init SDL
        SDL_SetMainReady();
        int res = SDL_Init(SDL_INIT_AUDIO);
        if (res != 0) {
            const char *error = SDL_GetError();
            cout<< "初始化 SDL 失败: "<< error <<endl;
            return false;
        }
        return true;
    }
    
    void readPCM() {
        // 开始播放
        m_playType = "pcm";
        m_isRunning = true;
        m_buffer.len = 0;
        SDL_PauseAudio(0);
        uint16_t bytes_pre_sample = SDL_AUDIO_BITSIZE(m_spec.format) * m_spec.channels / 8;
        uint16_t buffer_size = m_samples * bytes_pre_sample;
        char data[1024 * 10];
        while (m_isRunning) {
            // 只要从文件中读取的音频数据，还没有填充完毕，就跳过
            if (m_buffer.len > 0) {
                SDL_Delay(10);
                continue;
            }
            m_buffer.len = (int)m_audioFile.read(data, buffer_size).gcount();
            printf("did read data: %d\n", m_buffer.len);
            if (m_buffer.len <= 0) {
//                int samples = m_buffer.pullLen / bytes_pre_sample;
//                int ms = samples * 1000 / m_spec.freq;
//                SDL_Delay(ms);
                break;
            }
            m_buffer.data = (uint8_t *)data;
        }
        m_audioFile.close();
        printf("readPCM finish!!!");
    }

    static void pull_audio_data(void *userdata, Uint8 *stream, int len) {
        // 清空stream
        SDL_memset(stream, 0, len);
//        printf("%d\n", len);
        // 去除缓存信息
        AudioBuffer *buffer = (AudioBuffer *)userdata;
        if (buffer->len <= 0) return;
        buffer->pullLen = (len > buffer->len) ? buffer->len : len;
        
        // 填充数据
        SDL_MixAudio(stream, buffer->data, buffer->pullLen, SDL_MIX_MAXVOLUME);
        buffer->data += buffer->pullLen;
        buffer->len -= buffer->pullLen;
    }

};

// MARK: SDLPlayer
SDLPlayer::SDLPlayer() {
    m_impl = make_unique<SDLPlayerImpl>();
}

SDLPlayer::~SDLPlayer() {
    
}

bool SDLPlayer::playPCM(const char *file_path, PCMHeader &header) {
    return m_impl->play_pcm(file_path, header);
}

bool SDLPlayer::playWAV(const char * file_path) {
    return m_impl->play_wav(file_path);
}

void SDLPlayer::stopPlay() {
    m_impl->stopPlay();
}
