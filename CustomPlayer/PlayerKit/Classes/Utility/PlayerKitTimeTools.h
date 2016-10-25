//
//  PlayerKitTimeTools.h
//  PlayerKit
//
//  Created by Jack MacBook on 15/12/31.
//  Copyright © 2016年 嗨，我是曾宪华(@xhzengAIB)，曾加入YY Inc.担任高级移动开发工程师，拍立秀App联合创始人，热衷于简洁、而富有理性的事物 QQ:543413507 主页:http://zengxianhua.com All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface PlayerKitTimeTools : NSObject

+ (NSString *)convertSecond:(Float64)second;

+ (NSString *)converTime:(CMTime)time;

+ (NSMutableAttributedString *)processingTimeAttributedString:(NSString *)processingTimeString
                                            playingTimeString:(NSString *)playingTimeString
                                              totalTimeString:(NSString *)totalTimeString;

@end
