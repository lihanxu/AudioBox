//
//  AudioRecord.hpp
//  TestFFmpeg
//
//  Created by anker on 2022/1/24.
//

#ifndef AudioRecord_hpp
#define AudioRecord_hpp

#include <stdio.h>
#include <memory>

class AudioRecord {
    
public:
    AudioRecord();
    ~AudioRecord();
    bool startRecordAudio(const char *path);
    void stopRecordAudio();

private:
    class AudioRecordImpl;
    std::unique_ptr<AudioRecordImpl> m_impl;

};

#endif /* AudioRecord_hpp */
