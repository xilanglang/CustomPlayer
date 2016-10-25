//
//  PlayerKitToolsBottomView.m
//  CustomPlayer
//
//  Created by miniu on 16/10/13.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "PlayerKitToolsBottomView.h"
#import "PlayerKitTimeTools.h"

@interface PlayerKitToolsBottomView ()

@property (nonatomic, copy)NSString *totalTimeString;
@property (nonatomic, copy)NSString *playingTimeString;

@end

@implementation PlayerKitToolsBottomView

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
    self.backgroundColor = [UIColor colorWithWhite:0.500 alpha:0.8];
    
    [self addSubview:self.mediaControlButton];
    
    [self addSubview:self.progressView];
    [self addSubview:self.processingTimeLabel];
    
    [self addSubview:self.animationButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateButtons];
    [self updateProgressView];
    [self updateProcessingTimeLabel];
}

- (void)updateButtons {
    CGFloat sepator = 5;
    CGFloat animationButtonWidth = CGRectGetHeight(self.bounds);
    CGFloat animationButtonHeight = animationButtonWidth;
    
    CGRect mediaControlButtonFrame = CGRectMake(sepator, 0, animationButtonWidth, animationButtonHeight);
    self.mediaControlButton.frame = mediaControlButtonFrame;
    
    CGRect animationButtonFrame = CGRectMake(CGRectGetWidth(self.bounds)-animationButtonWidth-sepator, 0, animationButtonWidth, animationButtonHeight);
    self.animationButton.frame = animationButtonFrame;
}

- (void)updateProgressView {
    CGFloat sepator = 5;
    CGFloat paddingX = CGRectGetMaxX(self.mediaControlButton.frame) + sepator;
    
    CGRect progressViewFrame = CGRectMake(paddingX, 4, CGRectGetMinX(self.animationButton.frame)-sepator-paddingX, 18);
    self.progressView.frame = progressViewFrame;
}

- (void)updateProcessingTimeLabel {
    CGFloat progressIndicatorProtruding = 4;
    [self.processingTimeLabel sizeToFit];
    
    CGRect processingTimeLabelFrame = self.processingTimeLabel.frame;
    processingTimeLabelFrame.origin.x = CGRectGetMinX(self.progressView.frame);
//    processingTimeLabelFrame.origin.y = (CGRectGetHeight(self.bounds)+CGRectGetMaxY(self.progressView.frame)-CGRectGetHeight(processingTimeLabelFrame)-progressIndicatorProtruding)/2.0;
    processingTimeLabelFrame.origin.y = CGRectGetMaxY(self.progressView.frame)+progressIndicatorProtruding;
    self.processingTimeLabel.frame = processingTimeLabelFrame;
}

- (void)updatePlayControl:(BOOL)play {
    self.mediaControlButton.selected = play;
    
//    [self testLabel:self.totalTimeString label:self.processingTimeLabel];
}
//- (void)testLabel:(NSString *)str label:(UILabel *)label{
//    static int i=0;
//    i++;
//    str = [NSString stringWithFormat:@"%d",i];
//    UILabel *labe= label;
//    labe.text = [NSString stringWithFormat:@"label1 %d",i];
//    NSLog(@"%@",self.processingTimeLabel.text);
//    self.processingTimeLabel.text=[NSString stringWithFormat:@"%@",str];
//    NSLog(@"label2 %@",self.processingTimeLabel.text);
//}

- (void)updateAnimated:(BOOL)animated {
    self.animationButton.selected = animated;
}

- (void)updateTotalTimeString:(NSString *)totalTimeString {
    self.totalTimeString = totalTimeString;
    [self updateProcessingTimeLabelStyle];
    [self updateProcessingTimeLabel];
}

- (void)updatePlayingTimeString:(NSString *)playingTimeString {
    self.playingTimeString = playingTimeString;
    [self updateProcessingTimeLabelStyle];
    [self updateProcessingTimeLabel];
}

- (void)updateProcessingTimeLabelStyle {
    NSString *playingTimeString = self.playingTimeString;
    
    if (!playingTimeString) {
        playingTimeString = @"00:00:00";
    }
    if (!self.totalTimeString) {
        self.totalTimeString = @"00:00:00";
    }
    NSString *totalTimeString = [NSString stringWithFormat:@"/%@", self.totalTimeString];
    NSString *processingTimeString = [NSString stringWithFormat:@"%@%@", playingTimeString, totalTimeString];
    
    self.processingTimeLabel.attributedText = [PlayerKitTimeTools processingTimeAttributedString:processingTimeString playingTimeString:playingTimeString totalTimeString:totalTimeString];
}

#pragma mark - Propertys
- (UIButton *)mediaControlButton {
    if (!_mediaControlButton) {
        _mediaControlButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mediaControlButton setImage:[UIImage imageNamed:@"player-kit-play"] forState:UIControlStateNormal];
        [_mediaControlButton setImage:[UIImage imageNamed:@"player-kit-pause"] forState:UIControlStateSelected];
    }
    return _mediaControlButton;
}

- (PlayerKitProgressView *)progressView {
    if (!_progressView) {
        _progressView = [PlayerKitProgressView initilzerProgressViewWithFrame:CGRectMake(0, 10, CGRectGetWidth(self.bounds), 20)];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _progressView;
}

- (UILabel *)processingTimeLabel {
    if (!_processingTimeLabel) {
        _processingTimeLabel = [UILabel new];
        _processingTimeLabel.backgroundColor = [UIColor clearColor];
        _processingTimeLabel.font = [UIFont systemFontOfSize:10.0f];
        _processingTimeLabel.textAlignment = NSTextAlignmentRight;
        _processingTimeLabel.text = @"00:01:11/00:01:46";
    }
    return _processingTimeLabel;
}

- (UIButton *)animationButton {
    if (!_animationButton) {
        _animationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_animationButton setImage:[UIImage imageNamed:@"player-kit-animation-none"] forState:UIControlStateNormal];
        [_animationButton setImage:[UIImage imageNamed:@"player-kit-animation-animated"] forState:UIControlStateSelected];
    }
    return _animationButton;
}
@end
