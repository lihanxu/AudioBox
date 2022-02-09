//
//  SDLPlayer.hpp
//  AudioBox
//
//  Created by anker on 2022/2/7.
//

#ifndef SDLPlayer_hpp
#define SDLPlayer_hpp

#include <memory>

using namespace std;

class SDLPlayer {
    
public:
    typedef struct PCMHeader {
        // 采样率
        uint32_t sample_rate;
        // 采样格式
        uint32_t sample_format;
        // 声道数
        uint16_t channels;
    } PCMHeader;
    
    SDLPlayer();
    ~SDLPlayer();
    
    bool playPCM(const char *file_path, PCMHeader &header);
    bool playWAV(const char * file_path);
    void stopPlay();
    
private:
    class SDLPlayerImpl;
    std::unique_ptr<SDLPlayerImpl> m_impl;
};
#endif /* SDLPlayer_hpp */
