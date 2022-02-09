//
//  AudioResample.cpp
//  AudioBox
//
//  Created by anker on 2022/2/8.
//

#include "AudioResample.hpp"
#include <iostream>
#include <fstream>

extern "C" {
#include <libswresample/swresample.h>
}

using namespace std;

void AudioResample::resampleAudio(ResampleAudioSpec &in, ResampleAudioSpec &out) {
    ifstream inFile(in.filename, ios::in);
    ofstream outFile(out.filename, ios::out);
    
    // 输入缓冲区
    // 指向缓冲区的指针
    uint8_t **inData = nullptr;
    // 缓冲区的大小
    int inLinesize = 0;
    // 声道数
    int inChs = av_get_channel_layout_nb_channels(in.chLayout);
    // 一个样本的大小
    int inBytesPerSample = inChs * av_get_bytes_per_sample(in.sampleFmt);
    // 缓冲区的样本数量
    int inSamples = 1024;
    // 读取文件数据的大小
    int len = 0;
    
    // 输出缓冲区
    // 指向缓冲区的指针
    uint8_t **outData = nullptr;
    // 缓冲区的大小
    int outLinesize = 0;
    // 声道数
    int outChs = av_get_channel_layout_nb_channels(out.chLayout);
    // 一个样本的大小
    int outBytesPerSample = outChs * av_get_bytes_per_sample(out.sampleFmt);
    // 缓冲区的样本数量（AV_ROUND_UP是向上取整）
    int outSamples = (int)av_rescale_rnd(out.sampleRate, inSamples, in.sampleRate, AV_ROUND_UP);
    
    SwrContext *ctx = swr_alloc_set_opts(nullptr, out.chLayout, out.sampleFmt, out.sampleRate, in.chLayout, in.sampleFmt, in.sampleRate, 0, nullptr);
    if (!ctx) {
        cout<< "swr_alloc_set_opts failed!!!" <<endl;
        return;
    }
    int ret = swr_init(ctx);
    if (ret < 0) {
        cout<< "swr_init failed!!!" <<endl;
        goto failed;
    }
    
    ret = av_samples_alloc_array_and_samples(&inData, &inLinesize, inChs, inSamples, in.sampleFmt, 1);
    if (ret < 0) {
        cout<< "swr_init failed!!!" <<endl;
        goto failed;
    }
    
    ret = av_samples_alloc_array_and_samples(&outData, &outLinesize, outChs, outSamples, out.sampleFmt, 1);
    if (ret < 0) {
        cout<< "swr_init failed!!!" <<endl;
        goto failed;
    }
    
    if (inFile.is_open() == false) {
        cout<<"error: inFile 打开文件失败！"<<endl;
        goto failed;
    }
    if (outFile.is_open() == false) {
        cout<<"error: outFile 打开文件失败！"<<endl;
        goto failed;
    }
    
    while ((len = (int)inFile.read((char *)inData[0], inLinesize).gcount()) > 0) {
        inSamples = len / inBytesPerSample;
        ret = swr_convert(ctx, outData, outSamples, (const uint8_t **)inData, inSamples);
        if (ret < 0) {
            cout<< "swr_convert faile!!!" <<endl;
            goto failed;
        }
        outFile.write((char *)outData[0], ret * outBytesPerSample);
    }
    
    // 检查一下输出缓冲区是否还有残留的样本（已经重采样过的，转换过的）
    while ((ret = swr_convert(ctx, outData, outSamples, nullptr, 0)) > 0) {
        outFile.write((char *) outData[0], ret * outBytesPerSample);
    }
    cout<< "swr_convert finish!!!" <<endl;

failed:
    inFile.close();
    outFile.close();
    
    if (inData) {
        av_freep(&inData[0]);
    }
    av_freep(&inData);
    
    if (outData) {
        av_freep(&outData[0]);
    }
    av_freep(&outData);
    
    swr_free(&ctx);
}
