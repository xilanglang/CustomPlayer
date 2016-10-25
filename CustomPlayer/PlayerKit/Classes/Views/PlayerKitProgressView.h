//
//  PlayerKitProgressView.h
//  CustomPlayer
//
//  Created by miniu on 16/10/13.
//  Copyright © 2016年 mini. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerKitProgressView : UISlider

@property (nonatomic, assign)CGFloat progressTrackHeight;//滑块轨道的粗细(轨道的高度)

@property (nonatomic, strong)UIColor *bufferProgressTintColor;

@property (nonatomic, assign)CGFloat bufferProgress;
@property (nonatomic, assign)CGFloat progress;

- (void)setBufferProgress:(CGFloat)bufferProgress animated:(BOOL)animated;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

+ (instancetype)initilzerProgressViewWithFrame:(CGRect)frame;

@end
