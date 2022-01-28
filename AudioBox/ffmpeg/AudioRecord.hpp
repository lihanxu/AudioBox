//
//  AudioRecord.hpp
//  TestFFmpeg
//
//  Created by anker on 2022/1/24.
//

#ifndef AudioRecord_hpp
#define AudioRecord_hpp

#include <stdio.h>
#include <string>
extern "C" {
    #include <libavformat/avformat.h>
}

using namespace std;

class AudioRecord {
    
public:
    bool initDevice();
    bool startRecordAudio(string path);
    void stopRecordAudio();

private:
    bool runing;
    AVFormatContext *ctx;
    void closeInput();
};

#endif /* AudioRecord_hpp */
