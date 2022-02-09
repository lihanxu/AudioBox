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

- (void)encodePCM:(NSString *)pcmPath ToWAV:(NSString *)wavPath;

- (BOOL)playWAV:(NSString *)wavPath;
- (void)stopPlay;

- (void)resamlePCM:(NSString *)path toSampleRate:(NSInteger)sampleRate saveTo:(NSString *)savePath;
- (BOOL)playResamplePCM:(NSString *)path sampleRate:(NSInteger)sampleRate;

@end

NS_ASSUME_NONNULL_END
