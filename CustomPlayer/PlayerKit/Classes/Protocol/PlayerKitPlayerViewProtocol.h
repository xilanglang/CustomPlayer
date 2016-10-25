//
//  PlayerKitPlayerViewProtocol.h
//  CustomPlayer
//
//  Created by miniu on 16/9/30.
//  Copyright © 2016年 mini. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


/**
 Video view animation type

 - PlayerKitAnimationTypeNone:          None
 - PlayerKitAnimationTypeAnticlockwise: 90 degrees counterclockwise 逆时针
 - PlayerKitAnimationTypeClockwise:     90 degrees clockwise 顺时针方向的
 - PlayerKitAnimationTypeZoom:          Zoom 变焦
 */
typedef NS_ENUM(NSInteger, PlayerKitAnimationType) {
    PlayerKitAnimationTypeNone = 0,
    PlayerKitAnimationTypeAnticlockwise,
    PlayerKitAnimationTypeClockwise,
    PlayerKitAnimationTypeZoom
};

/**
 Playback State

 - PlayerKitPlaybackStateStopped: Player Stop
 - PlayerKitPlaybackStatePlaying: Player Playing
 - PlayerKitPlaybackStatePaused:  Player Pause
 - PlayerKitPlaybackStateFailed:  Player Failed
 */
typedef NS_ENUM(NSInteger, PlayerKitPlaybackState) {
    PlayerKitPlaybackStateStopped = 0,
    PlayerKitPlaybackStatePlaying,
    PlayerKitPlaybackStatePaused,
    PlayerKitPlaybackStateFailed
};

/**
 Buffering State

 - PlayerKitBufferingStateBuffering: Buffering
 - PlayerKitBufferingStateKeepUp:    Buffering keepup
 - PlayerKitBufferingStateDelayed:   Delayed buffering //缓存区达不到要求
 - PlayerKitBufferingStateFull:      Buffer full
 - PlayerKitBufferingStateUpToGrade: Up to grade //缓冲区达到要求
 */
typedef NS_ENUM(NSInteger, PlayerKitBufferingState) {
    PlayerKitBufferingStateBuffering = 0,
    PlayerKitBufferingStateKeepUp,
    PlayerKitBufferingStateDelayed,
    PlayerKitBufferingStateFull,
    PlayerKitBufferingStateUpToGrade
};

/**
 Gesture State

 - PlayerKitGestureStateNone:          None
 - PlayerKitGestureStateVolume:        Volume
 - PlayerKitGestureStateBrightness:    Brightness
 - PlayerKitGestureStatePlaybackSpeed: Playback Speed
 - PlayerKitGestureStateProgress:      Media Progress
 */
typedef NS_ENUM(NSInteger, PlayerKitGestureState) {
    PlayerKitGestureStateNone = 0,
    PlayerKitGestureStateVolume,
    PlayerKitGestureStateBrightness,
    PlayerKitGestureStatePlaybackSpeed,
    PlayerKitGestureStateProgress
};

/**
 Gesture Direction

 - PlayerKitGestureDirectionNone:       None
 - PlayerKitGestureDirectionHorizontal: Horizontal
 - PlayerKitGestureDirectionVertical:   Vertical
 */
typedef NS_ENUM(NSInteger, PlayerKitGestureDirection) {
    PlayerKitGestureDirectionNone = 0,
    PlayerKitGestureDirectionHorizontal,
    PlayerKitGestureDirectionVertical
};

/**
 Processing State

 - PlayerKitProcessingStateNone:     None
 - PlayerKitProcessingStateBackward: Backward
 - PlayerKitProcessingStateForward:  Forward
 */
typedef NS_ENUM(NSInteger, PlayerKitProcessingState) {
    PlayerKitProcessingStateNone = 0,
    PlayerKitProcessingStateBackward,
    PlayerKitProcessingStateForward
};

typedef void(^PlayerKitAnimationBlock)(void);
typedef void(^PlayerKitDidTapButtonBlock)(UIButton *sender);
typedef void(^PlayerKitDidChangeTimeBlock)(float currentTimeValue);
typedef void(^PlayerKitReloadBlock)(void);
typedef void(^PlayerKitGestureChangeBlock)(PlayerKitGestureState gestureState, BOOL plus);
typedef void(^PlayerKitGestureDidEndBlock)(PlayerKitGestureState gestureState);

@class PlayerKitContainer;

//这里分两种方法：
//第一种是外部更新UI
//第二种是内部用户行为通知外部
@protocol PlayerKitPlayerViewProtocol <NSObject>

@required
@property (nonatomic, strong)AVPlayer *player;
@property (nonatomic, readonly)AVPlayerLayer *playerLayer;

@property (nonatomic, copy)NSString *videoFillMode;

@optional
//@property (nonatomic, weak)PlayerKitContainer *playerContainer;
@property (nonatomic, assign)CGRect topToolsBarFrame;
@property (nonatomic, assign)CGRect bottomToolsBarFrame;
@property (nonatomic, copy)NSString *title;
/**
 Video view animation handle

 @param completion Back AnimationType Block
 */
- (void)animationCompletion:(PlayerKitAnimationBlock)completion;
/**
 Play begin handle

 @param completion Tap Button Block
 */
- (void)playCompletion:(PlayerKitDidTapButtonBlock)completion;
/**
 Pause playback handle

 @param completion Tap Button Block
 */
- (void)pauseCompletion:(PlayerKitDidTapButtonBlock)completion;
/**
 Slider change value handle

 @param completion Tap Button Block
 */
- (void)sliderCurrentTimeValueCompletion:(PlayerKitDidChangeTimeBlock)completion;
/**
 When show failed at the time, relaod handle

 @param completion Slider Change Value Block
 */
- (void)handleDownloadFailedReloadCompletion:(PlayerKitReloadBlock)completion;

#pragma mark - ++++++++++++++++至于为什么不使用KVO呢？方便自定义的人，希望你们喜欢这么简洁的做法++++++++++++++
/**
 Show Indicator
 */
- (void)showIndicator;
/**
 Hide Indicator
 */
- (void)hideIndicator;
/**
 Show Failed
 */
- (void)showDownloadFailed;

/**
 Update media total duration

 @param totalTime Media Total Duration
 */
- (void)updateTotalTime:(CMTime)totalTime;
/**
 Update media buffering duration

 @param bufferringTime Buffering Duration
 */
- (void)updateBufferringTime:(CMTime)bufferringTime;
/**
 Update Playing duration 更新当前播放器的进度条

 @param playingTime Playing Duration
 */
- (void)updatePlayingTime:(CMTime)playingTime;
/**
 UpdateControlProcessing

 @param processingState Processing State
 */
- (void)updateControlProcessing:(PlayerKitProcessingState)processingState;
/**
 Update playing State

 @param playState playState
 */
- (void)updatePlayingState:(PlayerKitPlaybackState)playState;
/**
 *  When video view animation called
 */
- (void)animationAction:(PlayerKitAnimationType)animationType;

- (void)animatedControlElement;//单机屏幕显示隐藏 toolsTopView和toolsBottomView


@end
