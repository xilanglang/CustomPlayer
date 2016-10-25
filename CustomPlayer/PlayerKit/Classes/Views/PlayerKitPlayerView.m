//
//  PlayerKitPlayerView.m
//  CustomPlayer
//
//  Created by miniu on 16/10/10.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "PlayerKitPlayerView.h"
#import "PlayerKitToolsTopView.h"
#import "PlayerKitToolsBottomView.h"
#import "PlayerKitReloadTipsView.h"
#import "PlayerKitControlProgressTipsView.h"

#import "PlayerKitTimeTools.h"

@interface PlayerKitPlayerView ()
{
    struct {
        unsigned int showingToolView:1;
        unsigned int playerIsPlaying:1;
    } _flags;
}

//UI
@property (nonatomic, strong)UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong)PlayerKitToolsTopView *toolsTopView;
@property (nonatomic, strong)PlayerKitToolsBottomView *toolsBottomView;
@property (nonatomic, strong) PlayerKitReloadTipsView *reloadTipsView;
@property (nonatomic, strong) PlayerKitControlProgressTipsView *controlProgressTipsView;

//Block
@property (nonatomic, copy)PlayerKitAnimationBlock animationCompletion;

@property (nonatomic, copy)PlayerKitDidChangeTimeBlock didChangeTimeCompletion;

@property (nonatomic, copy)PlayerKitReloadBlock reloadCompletion;

@property (nonatomic, copy)PlayerKitDidTapButtonBlock playCompletion;
@property (nonatomic, copy)PlayerKitDidTapButtonBlock pauseCompletion;

//TotalTime
@property (nonatomic, assign)CMTime totalTime;
//AnimationType
@property (nonatomic, assign)PlayerKitAnimationType animationType;

@end

@implementation PlayerKitPlayerView

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

- (void)dealloc {
    [self cancelAutoFadeOutControlBar];
}

- (void)setup {
    _flags.showingToolView = YES;
    _animationType = PlayerKitAnimationTypeNone;
    
    [self addSubview:self.indicatorView];
    [self addSubview:self.toolsTopView];
    [self addSubview:self.toolsBottomView];
    [self addSubview:self.controlProgressTipsView];
    [self addSubview:self.reloadTipsView];
    
    [self autoFadeOutControlBar];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self layoutIndicator];
    [self layoutReloadTips];
    [self layoutToolsTopViewWithType:self.animationType];
    [self layoutToolsBottomViewWithType:self.animationType];
    [self layoutControlProgressTipsView];
}

- (void)layoutIndicator {
    self.indicatorView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)layoutReloadTips {
    self.reloadTipsView.frame = self.bounds;
}

- (void)layoutToolsTopViewWithType:(PlayerKitAnimationType)animationType {
    self.toolsTopView.hidden = (animationType == PlayerKitAnimationTypeNone);
    self.toolsTopView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), 64);
}

- (void)layoutToolsBottomViewWithType:(PlayerKitAnimationType)animationType {
    self.toolsBottomView.frame = CGRectMake(0, CGRectGetHeight(self.bounds)-44, CGRectGetWidth(self.bounds), 44);
}

- (void)layoutControlProgressTipsView {
    self.controlProgressTipsView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)animationToolsView:(BOOL)showing completion:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.toolsTopView.alpha = showing;
        self.toolsBottomView.alpha = showing;
    } completion:^(BOOL finished) {
        _flags.showingToolView = showing;
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)animateHideToolsView {
    if (!_flags.showingToolView) {
        return;
    }
    [self animationToolsView:NO completion:NULL];
}
//动画显示toolsTopView和toolsBottomView
- (void)animateShowToolsView {
    if (_flags.showingToolView) {
        return;
    }
    [self cancelAutoFadeOutControlBar];
    [self animationToolsView:YES completion:NULL];
}
//动画显示toolsTopView和toolsBottomView 5秒后会自动隐藏
- (void)animateShowToolsViewAndAutoFadeOut {
    if (_flags.showingToolView) {
        return;
    }
    [self animationToolsView:YES completion:^(BOOL finished) {
        [self autoFadeOutControlBar];
    }];
}

- (void)autoFadeOutControlBar {
    if (!_flags.showingToolView || !_flags.playerIsPlaying) {
        return;
    }
    [self cancelAutoFadeOutControlBar];
    [self performSelector:@selector(animateHideToolsView) withObject:nil afterDelay:5];
}

- (void)cancelAutoFadeOutControlBar {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHideToolsView) object:nil];
}

#pragma mark - Propertys
- (PlayerKitToolsTopView *)toolsTopView {
    if (!_toolsTopView) {
        _toolsTopView = [[PlayerKitToolsTopView alloc] initWithFrame:CGRectZero];
//        _toolsTopView.titleLabel.text = self.title;
        [_toolsTopView.closeButton addTarget:self action:@selector(closeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _toolsTopView;
}

//视频控制视图TopView上返回按钮被点击
- (void)closeButtonClick:(UIButton *)sender {
    self.animationCompletion();
}

- (PlayerKitToolsBottomView *)toolsBottomView {
    if (!_toolsBottomView) {
        _toolsBottomView = [[PlayerKitToolsBottomView alloc] initWithFrame:CGRectZero];
        [_toolsBottomView.progressView addTarget:self action:@selector(sliderChangeValue:) forControlEvents:UIControlEventValueChanged];
        [_toolsBottomView.mediaControlButton addTarget:self action:@selector(mediaControlButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_toolsBottomView.animationButton addTarget:self action:@selector(animationButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [_toolsBottomView.progressView addTarget:self action:@selector(willChange:) forControlEvents:UIControlEventTouchDown];
        [_toolsBottomView.progressView addTarget:self action:@selector(changeDidEnd:) forControlEvents:UIControlEventTouchUpInside];
        [_toolsBottomView.progressView addTarget:self action:@selector(changeDidEnd:) forControlEvents:UIControlEventTouchUpOutside];
        
        [_toolsBottomView.mediaControlButton addTarget:self action:@selector(willChange:) forControlEvents:UIControlEventTouchDown];
        [_toolsBottomView.mediaControlButton addTarget:self action:@selector(changeDidEnd:) forControlEvents:UIControlEventTouchUpInside];
        [_toolsBottomView.mediaControlButton addTarget:self action:@selector(changeDidEnd:) forControlEvents:UIControlEventTouchUpOutside];
        
        [_toolsBottomView.animationButton addTarget:self action:@selector(willChange:) forControlEvents:UIControlEventTouchDown];
        [_toolsBottomView.animationButton addTarget:self action:@selector(changeDidEnd:) forControlEvents:UIControlEventTouchUpInside];
        [_toolsBottomView.animationButton addTarget:self action:@selector(changeDidEnd:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _toolsBottomView;
}

- (PlayerKitReloadTipsView *)reloadTipsView {
    if (!_reloadTipsView) {
        _reloadTipsView = [[PlayerKitReloadTipsView alloc] init];
        [_reloadTipsView.reloadButton addTarget:self action:@selector(reloadButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _reloadTipsView;
}

- (PlayerKitControlProgressTipsView *)controlProgressTipsView {
    if (!_controlProgressTipsView) {
        _controlProgressTipsView = [[PlayerKitControlProgressTipsView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
    }
    return _controlProgressTipsView;
}

- (void)reloadButtonClick:(UIButton *)sender {
    if (self.reloadCompletion != nil) {
        self.reloadCompletion();
    }
}

- (void)mediaControlButtonClick:(UIButton *)sender {
    if (sender.selected) {
        if (self.pauseCompletion != nil) {
            self.pauseCompletion(sender);
        }
    } else {
        if (self.playCompletion != nil) {
            self.playCompletion(sender);
        }
    }
}

- (void)animationButtonClick:(UIButton *)sender {
    if (self.animationCompletion != nil) {
        self.animationCompletion();
    }
}

- (void)sliderChangeValue:(UISlider *)slider {
    if (self.didChangeTimeCompletion != nil) {
        self.didChangeTimeCompletion(slider.value);
    }
}
- (void)willChange:(UISlider *)slider {
    [self cancelAutoFadeOutControlBar];
}

- (void)changeDidEnd:(UISlider *)slider {
    [self autoFadeOutControlBar];
}
- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

#pragma mark - PlayerKitPlayerViewProtocol Methods
- (void)animationCompletion:(PlayerKitAnimationBlock)completion {
    self.animationCompletion = completion;
}

- (void)playCompletion:(PlayerKitDidTapButtonBlock)completion {
    self.playCompletion = completion;
}

- (void)pauseCompletion:(PlayerKitDidTapButtonBlock)completion {
    self.pauseCompletion = completion;
}

- (void)sliderCurrentTimeValueCompletion:(PlayerKitDidChangeTimeBlock)completion {
    self.didChangeTimeCompletion = completion;
}

- (void)handleDownloadFailedReloadCompletion:(PlayerKitReloadBlock)completion {
    self.reloadCompletion = completion;
}

- (void)showIndicator {
    [self.indicatorView startAnimating];
}
- (void)hideIndicator {
    [self.indicatorView stopAnimating];
}
- (void)showDownloadFailed {
    [self.reloadTipsView show];
}

- (void)updateTotalTime:(CMTime)totalTime {
    self.totalTime = totalTime;
    //更新时间标签
    NSString *totalTimeString = [PlayerKitTimeTools converTime:totalTime];
    [self.toolsBottomView updateTotalTimeString:totalTimeString];
    self.controlProgressTipsView.totalTimeString = totalTimeString;
}
- (void)updateBufferringTime:(CMTime)bufferringTime {
    [self.toolsBottomView.progressView setBufferProgress:CMTimeGetSeconds(bufferringTime)/CMTimeGetSeconds(self.totalTime)];
}
- (void)updatePlayingTime:(CMTime)playingTime {
    [self.toolsBottomView.progressView setProgress:CMTimeGetSeconds(playingTime)/CMTimeGetSeconds(self.totalTime)];
    //更新时间标签
    NSString *playingTimeString=[PlayerKitTimeTools converTime:playingTime];
    [self.toolsBottomView updatePlayingTimeString:playingTimeString];
    self.controlProgressTipsView.playingTimeString = playingTimeString;
}

- (void)updateControlProcessing:(PlayerKitProcessingState)processingState {
    self.controlProgressTipsView.processingState = processingState;
}

- (void)updatePlayingState:(PlayerKitPlaybackState)playState {
    [self.toolsBottomView updatePlayControl:(playState == PlayerKitPlaybackStatePlaying)];
    _flags.playerIsPlaying = NO;
    
    if (playState == PlayerKitPlaybackStateFailed) {
        [self showDownloadFailed];
    } else if (playState == PlayerKitPlaybackStatePaused) {
        [self animateShowToolsView];
    } else if (playState == PlayerKitPlaybackStatePlaying) {
        _flags.playerIsPlaying = YES;
        [self autoFadeOutControlBar];
    }
}

- (void)animationAction:(PlayerKitAnimationType)animationType {
    self.animationType = animationType;//控制ToolsTopView的显示隐藏
    
    [self.toolsBottomView updateAnimated:(animationType != PlayerKitAnimationTypeNone)];
}

- (void)animatedControlElement {
    if (_flags.showingToolView) {
        [self animateHideToolsView];
    } else {
        [self animateShowToolsViewAndAutoFadeOut];
    }
}
@end
