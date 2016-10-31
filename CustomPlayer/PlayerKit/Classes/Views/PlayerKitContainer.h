//
//  PlayerKitContainer.h
//  CustomPlayer
//
//  Created by miniu on 16/9/30.
//  Copyright © 2016年 mini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PlayerKitPlayerViewProtocol.h"

@class PlayerKitContainer;

@protocol PlayerKitContainerDelegate <NSObject>

@optional
- (void)playerKitContainerDidDismiss:(PlayerKitContainer *)playerContainer;//还未实现

#pragma mark - Playback State
/**
 To start playing

 @param playerContainer The media player
 */
- (void)playerKitContainerPlaybackWillStartBeginning:(PlayerKitContainer *)playerContainer;

/**
 Stop playing

 @param playerContainer The media player
 */
- (void)playerKitContainerPlaybackDidEnd:(PlayerKitContainer *)playerContainer;

/**
 Play the state changes

 @param playerContainer The media player
 */
- (void)playerKitContainerPlaybackStateDidChange:(PlayerKitContainer *)playerContainer;

/**
 The buffer state changes

 @param playerContainer The media player
 */
- (void)playerKitContainerBufferringStateDidChange:(PlayerKitContainer *)playerContainer;

#pragma mark - PlayerLayer
/**
 PlayerLayer ready

 @param playerContainer The media player
 */
- (void)playerKitContainerReady:(PlayerKitContainer *)playerContainer;

#pragma mark - Duration
/**
 Playback time change

 @param playerContainer The media player
 @param readDuration    Playing time
 */
- (void)playerKitContainer:(PlayerKitContainer *)playerContainer didChangeReadDuration:(CMTime)readDuration;

/**
 Buffering time change

 @param playerContainer The media player
 @param bufferDuration  Buffering time
 */
- (void)playerKitContainer:(PlayerKitContainer *)playerContainer didChangeBufferDuration:(CMTime)bufferDuration;

/**
 Did down load media header info

 @param playerContainer The media player
 @param totalDuration   Media total duration
 */
- (void)playerKitContainer:(PlayerKitContainer *)playerContainer didLoadMediaTotalDuration:(CMTime)totalDuration;

#pragma mark - Animation
- (void)playerKitContainer:(PlayerKitContainer *)playerContainer willAnimationWithType:(PlayerKitAnimationType)animationType;
//显示隐藏 toolsTopView和toolsBottomView
- (void)playerKitContainerDidAnimationElement:(PlayerKitContainer *)playerContaioner;

@end

@interface PlayerKitContainer : UIView

#pragma mark - Base Info
//Media total time
@property (nonatomic, assign, readonly)CMTime totalDuration;
//Media playing time
@property (nonatomic, assign, readonly)CMTime readDuration;
//Media buffering time
@property (nonatomic, assign, readonly)CMTime bufferDuration;
//Media playback state
@property (nonatomic, assign, readonly)PlayerKitPlaybackState playbackState;
//Media buffering state
@property (nonatomic, assign, readonly) PlayerKitBufferingState bufferingState;
//Media view animation type
@property (nonatomic, assign, readonly) PlayerKitAnimationType animationType;
#pragma mark - Multiple Stup Media Asset Property
//Media path, eg:filePath urlPath
@property (nonatomic, copy)NSString *mediaPath;

#pragma mark - Some Setup
//Delegate
@property (nonatomic, weak)id<PlayerKitContainerDelegate> delegate;
//Comply with the <PlayerKitPlayerViewProtocol>View
@property (nonatomic, strong)UIView <PlayerKitPlayerViewProtocol>*playerView;
//Loops Playback at end, default is NO
@property (nonatomic, assign)BOOL playbackLoops;
//Automatically after the minimum target buffer time, default is YES
@property (nonatomic, assign)BOOL autoPlaybackToMinPreloadBufferTime;
//Allow control volume for gesture, default is YES
@property (nonatomic, assign)BOOL allowControlVolumeForGesture;
//Allow control brightness for gesture, default is YES
@property (nonatomic, assign)BOOL allowControlBrightnessForGesture;
//Allow control playback speed for gesture, default is NO 播放速度
@property (nonatomic, assign)BOOL allowControlPlaybackSpeedForGesture;
//Allow control media progress for gesture, default is YES 媒体视频播放进度
@property (nonatomic, assign)BOOL allowControlMediaProgressForGesture;
//Allow Portrait media player leave a black border at status bar, default is YES
@property (nonatomic, assign)BOOL leaveblackBorderAtStatusBar;//默认播放器离状态栏20像素
/*
Minimum buffer time for play,default is 10.0f, When the buffer time is greater than the 
total media time, automatically set to half of the total time
 */
@property (nonatomic, assign)CGFloat minPreloadBufferTimeToPlay;
/*
 Video fill mode,default is nil, because the video fill mode depending PlayerView, If you
 set this, PlayerView video fill mode become invalid
 */
@property (nonatomic, copy)NSString *videoFillMode;
/*
 Video present frame,if not use initWithFiame:methods default is CGReckMake(0, 0, 
 CGRectGetWidth([[UIScreen mainScreen] bounds]), CGRectGetHeight([[UIScreen mainScreen] bounds])/3);
 */
@property (nonatomic, assign)CGRect presentFrame;
//Media Volume, default is 1.0
@property (nonatomic, assign)CGFloat volume;

- (void)buildInterface;

- (void)rotateToLandscape:(BOOL)isPortrait size:(CGSize)size;//屏幕旋转

@end
