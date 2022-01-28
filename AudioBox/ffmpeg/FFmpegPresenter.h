//
//  FFmpegPresenter.h
//  TestFFmpeg
//
//  Created by anker on 2022/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FFmpegPresenter : NSObject

- (BOOL)initDevice;
- (void)startRecordPCMWithPath:(NSString *)path;
- (void)stopRecordPCM;
- (void)coverToWAV;
- (void)playWAV;

@end

NS_ASSUME_NONNULL_END
