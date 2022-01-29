//
//  KarplusStrongPlayer.h
//  LiveStudio
//
//  Created by hxli on 2019/8/20.
//  Copyright © 2019年 ImageVision. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KarplusStrongPlayer : NSObject

- (void)stop;
- (void)start;
- (void)updateFrequency:(double)frequency;

@end

NS_ASSUME_NONNULL_END
