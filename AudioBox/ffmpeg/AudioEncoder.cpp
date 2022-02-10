//
//  AudioEncoder.cpp
//  TestFFmpeg
//
//  Created by anker on 2022/1/26.
//

#include "AudioEncoder.hpp"
#include <iostream>
#include <fstream>
extern "C" {
#include <libavutil/avutil.h>
}

// 错误处理
#define ERROR_BUF(ret) \
    char errbuf[1024]; \
    av_strerror(ret, errbuf, sizeof (errbuf));

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

// 检查编码器codec是否支持采样格式sample_fmt
static int check_sample_fmt(const AVCodec *codec,
                            enum AVSampleFormat sample_fmt) {
    const enum AVSampleFormat *p = codec->sample_fmts;
    while (*p != AV_SAMPLE_FMT_NONE) {
        cout<< "sample_fmt: " << *p <<endl;
        if (*p == sample_fmt) return 1;
        p++;
    }
    return 0;
}

// 音频编码
// 返回负数：中途出现了错误
// 返回0：编码操作正常完成
static int encode(AVCodecContext *ctx, AVFrame *frame, AVPacket *pkt, ofstream &outFile) {
    // 发送数据到编码器
    int ret = avcodec_send_frame(ctx, frame);
    if (ret < 0) {
        ERROR_BUF(ret);
        cout<< "avcodec_send_frame error" << errbuf <<endl;
        return ret;
    }

    while (true) {
        // 从编码器中获取编码后的数据
        ret = avcodec_receive_packet(ctx, pkt);
        // packet中已经没有数据，需要重新发送数据到编码器（send frame）
        if (ret == AVERROR(EAGAIN)) {
            cout<< "avcodec_receive_packet error EAGAIN" <<endl;
            ret = 0;
            break;
        } else if (ret == AVERROR_EOF) {
            cout<< "encode aac done!!!" <<endl;
            ret = 0;
            break;
        } else if (ret < 0) { // 出现了其他错误
            ERROR_BUF(ret);
            cout<< "avcodec_receive_packet error" << errbuf <<endl;
            break;
        }

        // 将编码后的数据写入文件
        outFile.write((char *) pkt->data, pkt->size);

        // 释放资源
        av_packet_unref(pkt);
    }
    return ret;
}

void AudioEncoder::pcm2aac(AudioEncodeSpec &in, const char *outFilename) {
    // 编码器
    AVCodec *codec = nullptr;
    // 上下文
    AVCodecContext *ctx = nullptr;
    // 用来存放编码前的数据
    AVFrame *frame = nullptr;
    // 用来存放编码后的数据
    AVPacket *pkt = nullptr;
    // 输入文件
    ifstream inFile(in.filename, ios::in);
    // 输出文件
    ofstream outFile(outFilename, ios::out);
    // 返回结果
    int ret = 0;
    
// 查找编码器
//   codec = avcodec_find_encoder(AV_CODEC_ID_AAC);
//    AVCodec *codec2 = avcodec_find_encoder_by_name("aac");
    codec = avcodec_find_encoder_by_name("libfdk_aac");
    if (!codec) {
        cout<< "encoder libfdk_aac not found" <<endl;
        return;
    }
    // 检查采样格式
    if (!check_sample_fmt(codec, in.sampleFmt)) {
        cout<< "Encoder does not support sample format" << av_get_sample_fmt_name(in.sampleFmt) <<endl;
        return;
    }
    
// 创建上下文
    ctx = avcodec_alloc_context3(codec);
    if (!ctx) {
        cout<< "avcodec_alloc_context3 error" <<endl;
        return;
    }

    // 设置参数
    ctx->sample_fmt = in.sampleFmt;
    ctx->sample_rate = in.sampleRate;
    ctx->channel_layout = in.chLayout;
    // 比特率
    ctx->bit_rate = 32000;
    // 规格
    ctx->profile = FF_PROFILE_AAC_HE;
    
// 打开编码器
    //    AVDictionary *options = nullptr;
    //    av_dict_set(&options, "vbr", "1", 0);
    //    ret = avcodec_open2(ctx, codec, &options);
    ret = avcodec_open2(ctx, codec, nullptr);
    if (ret < 0) {
        ERROR_BUF(ret);
        cout<< "avcodec_open2 error" << errbuf <<endl;
        goto end;
    }
    
// 创建AVFrame
    frame = av_frame_alloc();
    if (!frame) {
        cout<< "av_frame_alloc error" <<endl;
        goto end;
    }

    // 样本帧数量（由frame_size决定）
    frame->nb_samples = ctx->frame_size;
    // 采样格式
    frame->format = ctx->sample_fmt;
    // 声道布局
    frame->channel_layout = ctx->channel_layout;
    // 创建AVFrame内部的缓冲区
    ret = av_frame_get_buffer(frame, 0);
    if (ret < 0) {
        ERROR_BUF(ret);
        cout<< "av_frame_get_buffer error" << errbuf <<endl;
        goto end;
    }
    
// 创建AVPacket
    pkt = av_packet_alloc();
    if (!pkt) {
        cout<< "av_packet_alloc error" <<endl;
        goto end;
    }
    
    if (inFile.is_open() == false) {
        cout<< "file open error" << in.filename <<endl;
        goto end;
    }
    if (outFile.is_open() == false) {
        cout<< "file open error" << outFilename <<endl;
        goto end;
    }
    
    // frame->linesize[0]是缓冲区的大小
    // 读取文件数据
    while ((ret = (int)inFile.read((char *) frame->data[0], frame->linesize[0]).gcount()) > 0) {
        // 最后一次读取文件数据时，有可能并没有填满frame的缓冲区
        if (ret < frame->linesize[0]) {
            // 声道数
            int chs = av_get_channel_layout_nb_channels(frame->channel_layout);
            // 每个样本的大小
            int bytes = av_get_bytes_per_sample((AVSampleFormat) frame->format);
            // 改为真正有效的样本帧数量
            frame->nb_samples = ret / (chs * bytes);
        }

        // 编码
        if (encode(ctx, frame, pkt, outFile) < 0) {
            goto end;
        }
    }

    // flush编码器
    encode(ctx, nullptr, pkt, outFile);
    
end:
    // 关闭文件
    inFile.close();
    outFile.close();

    // 释放资源
    av_frame_free(&frame);
    av_packet_free(&pkt);
    avcodec_free_context(&ctx);
}
