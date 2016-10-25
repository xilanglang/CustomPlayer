//
//  PlayerKitProgressView.m
//  CustomPlayer
//
//  Created by miniu on 16/10/13.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "PlayerKitProgressView.h"

@interface PlayerKitProgressView ()

@property (nonatomic, strong)CAShapeLayer *bufferProgressLayer;

@end

@implementation PlayerKitProgressView

+ (instancetype)initilzerProgressViewWithFrame:(CGRect)frame {
    PlayerKitProgressView *progressView = [[PlayerKitProgressView alloc] initWithFrame:frame];
    //设置滑块值是否连续变化(默认为YES)
    //这个属性设置为YES则在滑动时，其value就会随时变化，设置为NO，则当滑动结束时，value才会改变。
    progressView.continuous = NO;
    //设置滑块最小边界值（默认为0）
    progressView.minimumValue= 0.0;
    //设置滑块最大边界值（默认为1）
    progressView.maximumValue= 1.0;
    
    progressView.value = 0.0;
    //设置滑块的图片
    [progressView setThumbImage:[UIImage imageNamed:@"player-kit-slider_indicator"] forState:UIControlStateNormal];
    //设置滑块划过部分的线条图案
    [progressView setMinimumTrackImage:[UIImage imageNamed:@"player-kit-slider_track_fill"] forState:UIControlStateNormal];
    //设置滑块未划过部分的线条图案
    [progressView setMaximumTrackImage:[UIImage imageNamed:@"player-kit-slider_track_empty"] forState:UIControlStateNormal];
    
    return progressView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.bufferProgressTintColor =[UIColor colorWithWhite:1.000 alpha:0.500];
    self.progressTrackHeight = 3.0;
    
    CGRect progressBounds = [self trackRectForBounds:self.bounds];
    progressBounds.origin.y -= 1.0;
    
    self.bufferProgressLayer = [CAShapeLayer layer];
    self.bufferProgressLayer.frame = progressBounds;
    self.bufferProgressLayer.fillColor = nil;
    self.bufferProgressLayer.lineWidth = CGRectGetHeight(progressBounds);
    self.bufferProgressLayer.strokeColor = self.bufferProgressTintColor.CGColor;
    self.bufferProgressLayer.strokeStart = 0.0;
    self.bufferProgressLayer.strokeEnd = 0.0;
    [self.layer addSublayer:self.bufferProgressLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bufferProgressLayerFrame = self.bufferProgressLayer.frame;
    bufferProgressLayerFrame.size.width = CGRectGetWidth(self.bounds);
    self.bufferProgressLayer.frame = bufferProgressLayerFrame;
    
    CGRect processBounds = [self trackRectForBounds:self.bounds];
    
    CGFloat halfHeight = CGRectGetHeight(processBounds)/2.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, halfHeight)];
    [bezierPath addLineToPoint:CGPointMake(CGRectGetWidth(processBounds), halfHeight)];
    self.bufferProgressLayer.path = bezierPath.CGPath;
}

//定制UISlider
//自定义一个类继承自UISlider，然后重写这些方法，返回自定义的滑块的各个区域的大小
//- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds;  //返回左边图片大小
//- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds;  //返回右边图片大小

//返回滑道大小
- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect tractRect = CGRectMake(0, (CGRectGetHeight(bounds)-self.progressTrackHeight)/2, CGRectGetWidth(bounds), self.progressTrackHeight);
    return tractRect;
}
//返回滑块大小
- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value{
    CGRect thumbRect = CGRectMake(value*(CGRectGetWidth(self.bounds)-18), 0.5, 18, 18);
    return thumbRect;
}

#pragma mark - Propertys
- (void)setBufferProgressTintColor:(UIColor *)bufferProgressTintColor {
    _bufferProgressTintColor = bufferProgressTintColor;
    self.bufferProgressLayer.strokeColor = bufferProgressTintColor.CGColor;
    [self.bufferProgressLayer setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    if (_progress == progress) {
        return;
    }
    if (progress > 1.0) {
        progress = 1.0;
    } else if (progress < 0.0 || isnan(progress)) {
        //NaN （Not a Number）在w3c 中定义的是非数字的特殊值 ,它的对象是Number
        progress = 0.0;
    }
    _progress = progress;
    [self updateProgress];
}

- (void)setBufferProgress:(CGFloat)bufferProgress {
    [self setBufferProgress:bufferProgress animated:NO];
}

- (void)setBufferProgress:(CGFloat)bufferProgress animated:(BOOL)animated {
    if (_bufferProgress == bufferProgress) {
        return;
    }
    if (bufferProgress > 1.0) {
        bufferProgress = 1.0;
    } else if (bufferProgress < 0.0 || isnan(bufferProgress)) {
        bufferProgress = 0.0;
    }
    _bufferProgress = bufferProgress;
    [self updateBufferProgress];
}

- (void)updateProgress {
    if (self.state == UIControlStateNormal) {
        self.value = self.progress;
    }
}

- (void)updateBufferProgress {
    self.bufferProgressLayer.strokeEnd = self.bufferProgress;
}

@end
