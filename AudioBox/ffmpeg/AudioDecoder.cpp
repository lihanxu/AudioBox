//
//  AudioDecoder.cpp
//  AudioBox
//
//  Created by anker on 2022/2/10.
//

#include "AudioDecoder.hpp"
#include <iostream>
#include <fstream>
extern "C" {
#include <libavutil/avutil.h>
}

#define ERROR_BUF(ret) \
    char errbuf[1024]; \
    av_strerror(ret, errbuf, sizeof (errbuf));

// 输入缓冲区的大小
#define IN_DATA_SIZE 20480
// 需要再次读取输入文件数据的阈值
#define REFILL_THRESH 4096

using namespace std;

static int decode(AVCodecContext *ctx, AVPacket *pkt, AVFrame *frame, ofstream &outFile) {
    // 发送压缩数据到解码器
    int ret = avcodec_send_packet(ctx, pkt);
    if (ret < 0) {
        ERROR_BUF(ret);
        cout<< "avcodec_send_packet error" << errbuf <<endl;
        return ret;
    }

    while (true) {
        // 获取解码后的数据
        ret = avcodec_receive_frame(ctx, frame);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
            return 0;
        } else if (ret < 0) {
            ERROR_BUF(ret);
            cout<< "avcodec_receive_frame error" << errbuf <<endl;
            return ret;
        }
        // 将解码后的数据写入文件
        outFile.write((char *) frame->data[0], frame->linesize[0]);
    }
}

void AudioDecoder::aacDecode(const char *inFilename, AudioDecodeSpec &out) {
    // 返回结果
    int ret = 0;

    // 每次从输入文件中读取的长度
    int inLen = 0;
    // 是否已经读取到了输入文件的尾部
    int inEnd = 0;

    // 用来存放读取的文件数据
    // 加上AV_INPUT_BUFFER_PADDING_SIZE是为了防止某些优化过的reader一次性读取过多导致越界
    char inDataArray[IN_DATA_SIZE + AV_INPUT_BUFFER_PADDING_SIZE];
    char *inData = inDataArray;

    // 文件
    ifstream inFile(inFilename, ios::in);
    ofstream outFile(out.filename, ios::out);

    // 解码器
    AVCodec *codec = nullptr;
    // 上下文
    AVCodecContext *ctx = nullptr;
    // 解析器上下文
    AVCodecParserContext *parserCtx = nullptr;

    // 存放解码前的数据
    AVPacket *pkt = nullptr;
    // 存放解码后的数据
    AVFrame *frame = nullptr;
    
// 获取解码器
    codec = avcodec_find_decoder_by_name("libfdk_aac");
    if (!codec) {
        cout<< "decoder libfdk_aac not found" <<endl;
        return;
    }
// 初始化解析器上下文
    parserCtx = av_parser_init(codec->id);
    if (!parserCtx) {
        cout<< "av_parser_init error" <<endl;
        return;
    }
    
// 创建上下文
    ctx = avcodec_alloc_context3(codec);
    if (!ctx) {
        cout << "avcodec_alloc_context3 error" <<endl;
        goto end;
    }
    
// 创建AVPacket
    pkt = av_packet_alloc();
    if (!pkt) {
        cout<< "av_packet_alloc error" <<endl;
        goto end;
    }
    
// 创建AVFrame
    frame = av_frame_alloc();
    if (!frame) {
        cout<< "av_frame_alloc error" <<endl;
        goto end;
    }

// 打开解码器
    ret = avcodec_open2(ctx, codec, nullptr);
    if (ret < 0) {
        ERROR_BUF(ret);
        cout<< "avcodec_open2 error" << errbuf <<endl;
        goto end;
    }

    // 打开文件
    if (inFile.is_open() == false) {
        cout<< "file open error:" << inFilename <<endl;
        goto end;
    }
    if (outFile.is_open() == false) {
        cout<< "file open error:" << out.filename <<endl;
        goto end;
    }
    
// 读取数据
    inLen = (int)inFile.read(inData, IN_DATA_SIZE).gcount();
    while (inLen > 0) {
        // 经过解析器上下文处理
        ret = av_parser_parse2(parserCtx, ctx, &pkt->data, &pkt->size, (uint8_t *) inData, inLen, AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);
        if (ret < 0) {
            ERROR_BUF(ret);
            cout<< "av_parser_parse2 error" << errbuf <<endl;
            goto end;
        }
        // 跳过已经解析过的数据
        inData += ret;
        // 减去已经解析过的数据大小
        inLen -= ret;

        // 解码
        if (pkt->size > 0 && decode(ctx, pkt, frame, outFile) < 0) {
            goto end;
        }

        // 如果数据不够了，再次读取文件
        if (inLen < REFILL_THRESH && !inEnd) {
            // 剩余数据移动到缓冲区前
            memmove(inDataArray, inData, inLen);
            inData = inDataArray;

            // 跨过已有数据，读取文件数据
            int len = (int)inFile.read(inData + inLen, IN_DATA_SIZE - inLen).gcount();
            if (len > 0) {
                inLen += len;
            } else {
                inEnd = 1;
            }
        }
    }

    // flush解码器
    //    pkt->data = NULL;
    //    pkt->size = 0;
    decode(ctx, nullptr, frame, outFile);
    
// 设置输出参数
    out.sampleRate = ctx->sample_rate;
    out.sampleFmt = ctx->sample_fmt;
    out.chLayout = (int)ctx->channel_layout;

end:
    inFile.close();
    outFile.close();
    av_frame_free(&frame);
    av_packet_free(&pkt);
    av_parser_close(parserCtx);
    avcodec_free_context(&ctx);
}
