//
//  FFmpegPresenter.h
//  TestFFmpeg
//
//  Created by anker on 2022/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FFmpegPresenter : NSObject

- (BOOL)startRecordPCMWithPath:(NSString *)path;
- (void)stopRecordPCM;
- (BOOL)playRecordedPCM;

- (BOOL)playWAV:(NSString *)wavPath;
- (void)stopPlay;

- (void)resamlePCM:(NSString *)path toSampleRate:(NSInteger)sampleRate saveTo:(NSString *)savePath;
- (BOOL)playResamplePCM;


- (void)encodePCM:(NSString *)pcmPath ToWAV:(NSString *)wavPath;
- (void)encodePCM:(NSString *)pcmPath ToAAC:(NSString *)aacPath;

- (void)decodeAAC:(NSString *)aacPath saveTo:(NSString *)pcmPath;
- (BOOL)playDecodedPCM;
@end

NS_ASSUME_NONNULL_END
