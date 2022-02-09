//
//  AudioRecord.cpp
//  TestFFmpeg
//
//  Created by anker on 2022/1/24.
//

#include "AudioRecord.hpp"
#include <string>
#include <iostream>
#include <thread>
#include <fstream>
#include <unistd.h>
extern "C" {
    #include <libavcodec/avcodec.h>
    #include <libavutil/avutil.h>
    #include <libavformat/avformat.h>
}

using namespace std;

extern void showSpec(AVFormatContext *ctx);
extern void showDevice();

class AudioRecord::AudioRecordImpl {
    
public:
    AudioRecordImpl() {
        m_running = false;
        m_ctx = nullptr;
    }
    ~AudioRecordImpl() {
        // 关闭设备
        m_running = false;
        avformat_close_input(&m_ctx);
    }
    
private:
    bool m_running;
    AVFormatContext *m_ctx;
    ofstream m_outFile;
    thread m_threadRecord;
    
public:
    bool startRecordAudio(const char *path) {
        initDevice();
        if (m_ctx == nullptr) {
            cout<<"error: 设备没有初始化！"<<endl;
            return false;
        }
        // 打开输出路径文件
        m_outFile = ofstream(path, ios::out | ios::trunc);
        if (m_outFile.is_open() == false) {
            cout<<"error: 打开文件失败！"<<endl;
            return false;
        }
        m_running = true;
        thread t(&AudioRecordImpl::recordAudio, this);
        t.detach();
        return true;
    }

    void stopRecordAudio() {
        if (m_running == false) {
            return;
        }
        m_running = false;
        avformat_close_input(&m_ctx);
    }
    
private:
   bool initDevice(){
    //    showDevice();
        AVInputFormat *fmt = av_find_input_format("avfoundation");
        if (fmt == nullptr) {
            cout<<"error: 没有找到输入格式！！！"<<endl;
            return false;
        }

        int ret = avformat_open_input(&m_ctx, ":0", fmt, NULL);
        if (ret < 0) {
            char errbuf[1024] = {0};
            av_strerror(ret, errbuf, sizeof (errbuf));
            cout<<"error: 打开设备失败！"<< errbuf <<endl;
            return false;
        }
        showSpec(m_ctx);
        return true;
    }
    
    void recordAudio() {
        int ret = 0;
        // 数据包
        AVPacket *packet = av_packet_alloc();
        while (m_running) {
            // 从设备中采集数据
            ret = av_read_frame(m_ctx, packet);
            if (ret == 0) {
                // 将采集的数据写入文件
                m_outFile.write((const char *)packet->data, packet->size);
                cout<< "did write packet size: "<< packet->size <<endl;
                // 释放资源
                av_packet_unref(packet);
            } else if (ret == AVERROR(EAGAIN)) { // 资源临时不可用
                usleep(10 * 1000);
//                cout<< "error: EAGAIN" <<endl;
                continue;
            } else { // 出错了
                char errbuf[1024];
                av_strerror(ret, errbuf, sizeof(errbuf));
                cout<< "av_read_frame error" << errbuf << ret <<endl;
                break;
            }
        }
        // 释放资源
        av_packet_free(&packet);
        // 关闭文件
        m_outFile.close();
        cout<< "record audio finish!!" <<endl;
    }
};

// MARK: AudioRecord

AudioRecord::AudioRecord() {
    m_impl = make_unique<AudioRecordImpl>();
}

AudioRecord::~AudioRecord() {
    
}

bool AudioRecord::startRecordAudio(const char *path) {
    return m_impl->startRecordAudio(path);
}

void AudioRecord::stopRecordAudio() {
    m_impl->stopRecordAudio();
}

void showSpec(AVFormatContext *ctx) {
    int count = ctx->nb_streams;
    // 输入流数量
    cout<< "输入流数量:" << count <<endl;
    for (int i = 0; i < count; i++) {
        cout<< "streams: " << i <<endl;
        AVStream *stream = ctx->streams[i];
        AVCodecParameters *params = stream->codecpar;
        cout<< "声道数:" << params->channels <<endl;
        cout<< "采样率:" <<  params->sample_rate <<endl;
        cout<< "采样格式:" << params->format <<endl;
        // 一次采样的一个声道占用多少个字节
        cout<< "字节:" << av_get_bytes_per_sample((AVSampleFormat)params->format) <<endl;
        cout<< "编码ID:" << params->codec_id <<endl;
        // 一次采样的一个声道占用多少位
        cout<< "bits:" << av_get_bits_per_sample(params->codec_id) <<endl;
    }
}

void showDevice() {
    AVFormatContext *pFormatCtx = avformat_alloc_context();
    AVDictionary* options = NULL;
    av_dict_set(&options,"list_devices","true",0);
    AVInputFormat *iformat = av_find_input_format("avfoundation");
    printf("==AVFoundation Device Info===\n");
    avformat_open_input(&pFormatCtx,"",iformat,&options);
    printf("=============================\n");
    if(avformat_open_input(&pFormatCtx,"0",iformat,NULL)!=0){
        printf("Couldn't open input stream.\n");
        return ;
    }
}
