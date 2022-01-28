//
//  AudioEncoder.cpp
//  TestFFmpeg
//
//  Created by anker on 2022/1/26.
//

#include "AudioEncoder.hpp"
#include <iostream>
#include <fstream>

bool AudioEncoder::pcm2wav(string pcmPath, WAVHeader &header, string wavPath) {
    header.blockAlign = header.bitsPerSample * header.numChannels >> 3;
    header.byteRate = header.sampleRate * header.blockAlign;
    
    ifstream pcmFile(pcmPath, ios::in);
    if (pcmFile.is_open() == false) {
        cout<<"error: pcmPath 打开文件失败！"<<endl;
        return false;
    }
    ofstream wavFile(wavPath, ios::out);
    if (wavFile.is_open() == false) {
        cout<<"error: wavPath 打开文件失败！"<<endl;
        return false;
    }
    
    pcmFile.seekg(0, ios::end);
    uint32_t size = (uint32_t)pcmFile.tellg();
    header.dataChunkDataSize = size;
    header.riffChunkDataSize = header.dataChunkDataSize + sizeof(WAVHeader) - 8;
    wavFile.write((const char *)&header, sizeof(WAVHeader));
    
    pcmFile.seekg(0, ios::beg);
    char buffer[1024];
    uint32_t remaining = size;
    while (remaining > 0) {
        uint32_t willRead = remaining > 1024 ? 1024 : remaining;
        remaining = remaining - willRead;
        pcmFile.read(buffer, willRead);
        wavFile.write(buffer, willRead);
    }
    pcmFile.close();
    wavFile.close();
    cout<<"pcm to wav success!!!"<<endl;
    return true;
}
