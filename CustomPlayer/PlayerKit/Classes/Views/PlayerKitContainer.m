//
//  PlayerKitContainer.m
//  CustomPlayer
//
//  Created by miniu on 16/9/30.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "PlayerKitContainer.h"
#import "PlayerKitPlayerView.h"
#import <MediaPlayer/MediaPlayer.h>

// Default Steps
static CGFloat const PlayerVolumeStep = 0.02f;
static CGFloat const PlayerBrightnessStep = 0.02f;
static CGFloat const PlayerPlaybackSpeedStep = 0.25f;
static CGFloat const PlayerMediaProgressStep = 0.5f;

// KVO Contexts
static NSString * const ZXHPlayerObserverContext = @"ZXHPlayerObserverContext";
static NSString * const ZXHPlayerItemObserverContext = @"ZXHPlayerItemObserverContext";
static NSString * const ZXHPlayerPreloadObserverContext = @"ZXHPlayerPreloadObserverContext";
static NSString * const ZXHPlayerLayerObserverContext = @"ZXHPlayerLayerObserverContext";

// KVO Player Keys 检测播放器播放速度得到播放暂停和播放中的状态
static NSString * const ZXHPlayerContainerRateKey = @"rate";

// KVO Player Item Keys
static NSString * const ZXHPlayerContainerStatusKey = @"status";
static NSString * const ZXHPlayerContainerEmptyBufferKey = @"playbackBufferEmpty";
static NSString * const ZXHPlayerContainerPlayerKeepUpKey = @"playbackLikelyToKeepUp";
static NSString * const ZXHPlayerContainerPlayerBufferFullKey = @"playbackBufferFull";

// KVO Player Preload Keys //监听loadedTimeRanges属性 缓冲进度
static NSString * const ZXHPlayerContainerPlayerLoadedTimeRanges = @"loadedTimeRanges";

// KVO Player Layer Keys
static NSString * const ZXHPlayerContainerReadyForDisplay = @"readyForDisplay";

// Player Item Load Keys
static NSString * const ZXHPlayerContainerTracksKey = @"tracks";
static NSString * const ZXHPlayerContainerPlayableKey = @"playable";
static NSString * const ZXHPlayerContainerDurationKey = @"duration";

@interface PlayerKitContainer ()
{
    @private
    //observer
    id _playbackTimeObserver;
    
    //Gesture
    CGPoint _currentLocation;
    CGFloat _gestureTimeValue;
    
    //Flags
    struct {
        unsigned int firstReadyForDisplay:1;
        unsigned int userPaused:1;
        unsigned int userNeedFullScreenMode:1;
        unsigned int readyToPlay:1;
        unsigned int animating:1;
        unsigned int recordPlaybackState:1;
        unsigned int localFiled:1;
    } _flags;
    //Original SuperView
    UIView *_originalSuperView;
}

//AVFoundation
@property (nonatomic, strong)AVPlayer *player;
@property (nonatomic, strong)AVPlayerItem *playerItem;
@property (nonatomic, assign)CGFloat currentTimeValue;
//Media Asset, eg:local media
@property (nonatomic, copy)AVAsset *mediaAsset;

//Orientation
@property (nonatomic, assign) UIDeviceOrientation currnetOrientation;

//Animation Type
@property (nonatomic, assign, readwrite) PlayerKitAnimationType animationType;

//Base Info
@property (nonatomic, assign, readwrite) CMTime totalDuration;
@property (nonatomic, assign, readwrite) CMTime readDuration;
@property (nonatomic, assign, readwrite) CMTime bufferDuration;
@property (nonatomic, assign, readwrite) PlayerKitPlaybackState playbackState;
@property (nonatomic, assign, readwrite) PlayerKitBufferingState bufferingState;

//Gestures
@property (nonatomic, assign)PlayerKitGestureState gestureState;
//@property (nonatomic, assign)PlayerKitGestureDirection gestureDirection;

@end

@implementation PlayerKitContainer
@synthesize volume = _volume;
//初始化数据
- (void)commit {
    self.clipsToBounds = YES;
    
    _readDuration = kCMTimeZero;
    _bufferDuration = kCMTimeZero;
    _minPreloadBufferTimeToPlay = 10.0f;
    _volume = 1.0;
    
    _autoPlaybackToMinPreloadBufferTime = YES;
    _playbackLoops = NO;
    _allowControlVolumeForGesture = YES;
    _allowControlBrightnessForGesture = YES;
    _allowControlPlaybackSpeedForGesture = NO;
    _allowControlMediaProgressForGesture = YES;
    _leaveblackBorderAtStatusBar = YES;
    
    _flags.firstReadyForDisplay = NO;
    _flags.userPaused = NO;
    _flags.userNeedFullScreenMode = NO;
    _flags.readyToPlay = NO;
    _flags.animating = NO;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commit];
        _presentFrame = frame;
    }
    
    return self;
}

- (instancetype)init {
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
    self = [self initWithFrame:frame];
    if (self) {
        
    }
    
    return self;
}

- (void)dealloc {
    [self playerPause];
    
    _delegate = nil;
    
    _playerView.player = nil;
    
    [self removeObserverWithPlayer:_player];
    _player = nil;
    
    [self removeNotification];
    
    [self setPlayerItem:nil];
    
    [self setPlayerView:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self commit];
    _presentFrame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
}
#pragma mark - Public Methods
- (void)buildInterface {
    [self setup];
    
    [self setupPlayer];
    [self setupPlayerView];
    [self addNotification];
    [self loadMediaData];
}

#pragma mark - Setup Methods
- (void)setup {
    [self updateLayout];
}

- (void)setupPlayer {
    self.player = [[AVPlayer alloc] init];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    self.player.volume = self.volume;
    
    //player KVO
    [self addObserverWithPlayer:self.player];
}

- (void)setupPlayerView {
    //load the playerLayer view
    if (!_playerView) {
        //如果外部没有定制的话，直接使用内部的UI
        PlayerKitPlayerView *playerView = [[PlayerKitPlayerView alloc] initWithFrame:CGRectZero];
        [self setPlayerView:playerView];
    }
}

- (void)loadMediaData {
    if (!self.mediaAsset) {
        return;
    }
    [self showIndicator];
    
    NSArray *keys = @[ZXHPlayerContainerTracksKey,ZXHPlayerContainerPlayableKey,ZXHPlayerContainerDurationKey];
    
    __weak typeof (self.mediaAsset) weakAsset = self.mediaAsset;
    __weak typeof (self) weakSelf = self;
    //用来异步加载属性，通过keys传入要加载的key数组，在handler中做加载完成的操作。 
    [self.mediaAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //check the keys
            for (NSString *key in keys) {
                NSError *error = nil;
                AVKeyValueStatus keyStatus = [weakAsset statusOfValueForKey:key error:&error];
                if (keyStatus == AVKeyValueStatusFailed) {
                    [weakSelf callBackDelegateWithPlaybackState:PlayerKitPlaybackStateFailed];
                    NSLog(@"error (%@)", [[error userInfo] objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey]);
                    return;
                }
            }
            //check playable
            if (!weakAsset.playable) {
                [weakSelf callBackDelegateWithPlaybackState:PlayerKitPlaybackStateFailed];
                return;
            }
            //setup player
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:weakAsset];
            [weakSelf setPlayerItem:playerItem];
        });
    }];
}

- (void)reloadMediaData {
    [self updateMediaAssetWithMediaPath:self.mediaPath];
    [self loadMediaData];
}

#pragma mark - Propertys
- (void)setPlaybackState:(PlayerKitPlaybackState)playbackState {
    _playbackState = playbackState;
    if (playbackState == PlayerKitPlaybackStateFailed) {
        [self showDownloadFailed];
    }
}

- (void)setBufferingState:(PlayerKitBufferingState)bufferingState {
    _bufferingState = bufferingState;
    switch (bufferingState) {
        case PlayerKitBufferingStateBuffering:
        case PlayerKitBufferingStateDelayed: {//缓存区达不到要求
            //判断现在是否有网络，如果没有网络就需要通知缓存停止了
            if (self.bufferingState != PlayerKitBufferingStateFull && !_flags.localFiled) {
                [self showIndicator];
            }
            break;
        }
        case PlayerKitBufferingStateFull:
        case PlayerKitBufferingStateUpToGrade: {//缓冲区达到要求
            [self hideIndicator];
            break;
        }
            
        default:
            break;
    }
}

- (void)setPlaybackLoops:(BOOL)playbackLoops {
    _playbackLoops = playbackLoops;
    if (!self.player) {
        return;
    }
    
    if (!playbackLoops) {
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    } else {
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    }
}

- (CGFloat)volume {
    return self.player.volume;
}

- (void)setVolume:(CGFloat)volume {
    if (!self.player) {
        return;
    }
    
    self.player.volume = volume;
}

- (void)setVideoFillMode:(NSString *)videoFillMode {
    if (_videoFillMode == videoFillMode) {
        return;
    }
    _videoFillMode = videoFillMode;
    self.playerView.videoFillMode = videoFillMode;
}

- (void)setMediaPath:(NSString *)mediaPath {
    if (_mediaPath == mediaPath) {
        return;
    }
    if (!mediaPath || !mediaPath.length) {
        _mediaPath = nil;
        [self setMediaAsset:nil];
        return;
    }
    
    _mediaPath = [mediaPath copy];
    [self updateMediaAssetWithMediaPath:_mediaPath];
}
- (void)updateMediaAssetWithMediaPath:(NSString *)mediaPath {
    NSURL *mediaURL = [NSURL URLWithString:mediaPath];
    
    _flags.localFiled = NO;
//    NSString *scheme= [mediaURL scheme];//模式/协议（scheme）
    
    if (!mediaURL || ![mediaURL scheme]) {
        _flags.localFiled = YES;
        mediaURL = [NSURL fileURLWithPath:mediaPath];
    }
    
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:mediaURL options:nil];
    [self setMediaAsset:urlAsset];
}

- (void)setMediaAsset:(AVAsset *)mediaAsset {
    if (_mediaAsset==mediaAsset) {
        return;
    }
    //判断是否在播放，如果在播放，需要先暂停一下
    if (self.playbackState==PlayerKitPlaybackStatePlaying && _mediaAsset) {
        [self stop];
    }
    
    [self callBackDelegateWithBufferingState:PlayerKitBufferingStateBuffering];
    
    _mediaAsset = mediaAsset;
    
    //如果没有媒体资源文件，那就置空PlayerItem
    if (!_mediaAsset) {
        [self setPlayerItem:nil];
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) {
        return;
    }
    if (_playerItem) {
        //Remove KVO
        [self removeObserverWithPlayerItem:_playerItem];
        [self removeNotificationWithPlayerItem:_playerItem];
        [_playerItem cancelPendingSeeks];
        _playerItem = nil;
    }
    
    _playerItem = playerItem;
    //再次确认不是为空的
    if (playerItem) {
        //Add KVO and Notification
        [self addObserverWithPlayerItem:playerItem];
        
        [self addNotificationWithPlayerItem:playerItem];
        
        [self callBackDelegateWithDidLoadMediaTotalDuration];
    }
    
    if (!self.playbackLoops) {
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    } else {
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    }
    
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
}

- (void)setPresentFrame:(CGRect)presentFrame {
    _presentFrame = presentFrame;
    //Update Control Layout
    [self updateLayout];
}

- (void)setPlayerView:(UIView<PlayerKitPlayerViewProtocol> *)playerView {
    if (_playerView) {
        //Remove PlayerLayer KVO
        [self removeObserverWithPlayerLayer:_playerView.playerLayer];
//        [self destroyPlayerContainer];//不用KVO检测container的playerstate 是否可以
        [_playerView removeFromSuperview];
        _playerView = nil;
    }
    _playerView = playerView;
    
    if (_playerView) {
        [self addSubview:playerView];
        if (self.videoFillMode) {
            playerView.videoFillMode = self.videoFillMode;
        }
        playerView.frame=self.bounds;
        playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        playerView.player = self.player;
        
        //Add PlayerLayer KVO
        [self addObserverWithPlayerLayer:playerView.playerLayer];
        
        //Mornitor player view protocol
        [self mornitorPlayerView];
    }
}
- (CMTime)totalDuration {
    CMTime totalDuration = kCMTimeZero;
    
    if (CMTIME_IS_NUMERIC(self.playerItem.duration)) {
        totalDuration = self.playerItem.duration;
    }
    
    return totalDuration;
}

- (BOOL)isPlaying {
    return self.player.rate != 0.f;
}

- (CGRect)topToolsBarFrame {
    if ([self.playerView respondsToSelector:@selector(topToolsBarFrame)]) {
        return self.playerView.topToolsBarFrame;
    }
    return CGRectZero;
}

- (CGRect)bottomToolsBarFrame {
    if ([self.playerView respondsToSelector:@selector(topToolsBarFrame)]) {
        return self.playerView.topToolsBarFrame;
    }
    return CGRectZero;
}

#pragma mark - Animation Actions
//视频控制视图TopView上返回按钮被点击 BottomView上全屏(取消全屏)按钮被点击
- (void)controlAnimation {
    if (self.animationType != PlayerKitAnimationTypeNone) {
        _flags.userNeedFullScreenMode = NO;
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    } else {
        _flags.userNeedFullScreenMode = YES;
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
}

- (void)updateLayout {
    if (self.leaveblackBorderAtStatusBar) {
        CGRect presentFrame = self.presentFrame;
        presentFrame.origin.y = 20;
        presentFrame.size.height -= 20;
        _presentFrame = presentFrame;
    }
    self.frame = self.presentFrame;
    self.playerView.frame = self.bounds;
    //标记为需要重新布局，不立即刷新，但layoutSubviews一定会被调用,配合layoutIfNeeded立即更新
    [self.playerView setNeedsLayout];
    [self.playerView layoutIfNeeded];//立即调用layoutSubviews进行布局
}

- (void)mornitorPlayerView {
    __weak typeof (self) weakSelf = self;
    //视频控制视图TopView上返回按钮被点击 BottomView上全屏(取消全屏)按钮被点击
    if ([self.playerView respondsToSelector:@selector(animationCompletion:)]) {
        [self.playerView animationCompletion:^{
            [weakSelf controlAnimation];
        }];
    }
    
    if ([self.playerView respondsToSelector:@selector(playCompletion:)]) {
        [self.playerView playCompletion:^(UIButton *sender) {
            if (weakSelf.playbackState == PlayerKitPlaybackStateStopped) {
                [weakSelf playBeginning];
            }else {
                [weakSelf playCurrentTime];
            }
        }];
    }
    
    if ([self.playerView respondsToSelector:@selector(pauseCompletion:)]) {
        [self.playerView pauseCompletion:^(UIButton *sender) {
            [weakSelf userPause];
        }];
    }
    
    if ([self.playerView respondsToSelector:@selector(sliderCurrentTimeValueCompletion:)]) {
        [self.playerView sliderCurrentTimeValueCompletion:^(float currentTimeValue) {
            CGFloat currentMediaDuration = currentTimeValue*CMTimeGetSeconds(weakSelf.totalDuration);
            [weakSelf seekCurrentTimeValue:currentMediaDuration];
        }];
    }
    
    if ([self.playerView respondsToSelector:@selector(handleDownloadFailedReloadCompletion:)]) {
        [self.playerView handleDownloadFailedReloadCompletion:^{
            [weakSelf reloadMediaData];
        }];
    }
}

//ios6.o 之后设置状态栏方向函数被弃用
//- (void)setStatusBarOrientation:(UIInterfaceOrientation)orientation {
//    [[UIApplication sharedApplication] setStatusBarOrientation:orientation];
//}

#pragma mark - Player Control Actions
- (void)playerControl {
    if (self.mediaPath || self.mediaAsset) {
        switch (self.playbackState) {
            case PlayerKitPlaybackStateStopped: {
                [self playBeginning];
                break;
            }
            case PlayerKitPlaybackStatePaused: {
                [self playCurrentTime];
                break;
            }
            case PlayerKitPlaybackStatePlaying:
            case PlayerKitPlaybackStateFailed:
            default: {
                [self userPause];
                break;
            }
        }
    }
}

- (void)playBeginning {
    [self callBackDelegateWithStartBeginning];
    [self hideIndicator];
    self.readDuration = kCMTimeZero;
    [self.player seekToTime:kCMTimeZero];
    [self playCurrentTime];
}

- (void)playCurrentTime {
    if (self.playbackState == PlayerKitPlaybackStatePlaying) {
        return;
    }
    [self hideIndicator];
    [self playerPlay];
    [self callBackDelegateWithPlaybackState:PlayerKitPlaybackStatePlaying];
}

- (void)pause {
    if (self.playbackState == PlayerKitPlaybackStatePaused) {
        return;
    }
    [self playerPause];
    [self callBackDelegateWithPlaybackState:PlayerKitPlaybackStatePaused];
}

- (void)machinePause {
    _flags.userPaused = NO;
    [self pause];
}

- (void)userPause {
    _flags.userPaused = YES;
    [self pause];
}

- (void)playerPlay {
    if (![self isPlaying]) {
        [self.player play];
    }
}

- (void)seekCurrentTimeValue:(float)currentTimeValue {
    __weak typeof (self) weakself = self;
    [self pause];
    
    [self.player seekToTime:CMTimeMake(currentTimeValue, 1.0f) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakself playCurrentTime];
    }];
}
- (void)playerPause {
    if ([self isPlaying]) {
        [self.player pause];
    }
}

- (void)stop {
    if (self.playbackState == PlayerKitPlaybackStateStopped) {
        return;
    }
    [self playerPause];//是不是应该用[self playerStop]
    [self callBackDelegateWithDidChangeReadDuration:kCMTimeZero];
    [self callBackDelegateWithDidChangeBufferDuration:kCMTimeZero];
    [self callBackDelegateWithPlaybackState:PlayerKitPlaybackStateStopped];
}

- (void)playerStop {
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

#pragma mark - AVFoundation Handle NSNotificaion Methods
- (void)playerItemDidPlayToEndTime:(NSNotification *)notification {
    if (!self.playbackLoops) {
        [self stop];
        [self callBackDelegateWithPlaybackDidEnd];
    } else {
        [self.player seekToTime:kCMTimeZero];
    }
}

- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification {
    [self callBackDelegateWithPlaybackState:PlayerKitPlaybackStateFailed];
    NSLog(@"error (%@)", [[notification userInfo] objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey]);
}

#pragma mark - App Handle NSNotificaion Methods
- (void)applicationWillResignActive:(NSNotification *)notification {
    _flags.recordPlaybackState = self.playbackState;
    if (self.playbackState == PlayerKitPlaybackStatePlaying) {
        [self machinePause];
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.playbackState == PlayerKitPlaybackStatePlaying) {
        [self machinePause];
    }
}
#pragma mark - 手机旋转通知
- (void)deviceOrientationDidChange {
    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    UIDeviceOrientation oldOrientation = _currnetOrientation;
    if (currentOrientation == oldOrientation) {
        return;
    }
    
    switch (currentOrientation) {
        case UIDeviceOrientationPortrait: {
            [self resumeToNarmalScreenDown];
            break;
        }
        case UIDeviceOrientationLandscapeLeft: {
            //手机逆时针旋转   指手机旋转的方向不是视图旋转的方向
            [self rotationAnimationWithAnimationType:PlayerKitAnimationTypeAnticlockwise];
            break;
        }
        case UIDeviceOrientationLandscapeRight: {
            //手机顺时针旋转   指手机旋转的方向不是视图旋转的方向
            [self rotationAnimationWithAnimationType:PlayerKitAnimationTypeClockwise];
            break;
        }
        default:
            break;
    }
    
    self.currnetOrientation = currentOrientation;
}

-(void)resumeToNarmalScreenDown {
    if (_flags.animating) {
        return;
    }
    self.animationType = PlayerKitAnimationTypeNone;
    
    [self callBackDelegateWithAnimationType:self.animationType];
    
    if (!_originalSuperView) {
        _originalSuperView = [self superview];
    }
    [self removeFromSuperview];
    [_originalSuperView addSubview:self];
    
    _flags.animating = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = self.presentFrame;
        [self animationPlayerView];
    } completion:^(BOOL finished) {
        _flags.animating = NO;
    }];
}

- (void)rotationAnimationWithAnimationType:(PlayerKitAnimationType)animationType {
    if (_flags.animating) {
        return;
    }
    self.animationType = animationType;
    
    [self callBackDelegateWithAnimationType:self.animationType];
    
    if (!_originalSuperView) {
        _originalSuperView = [self superview];
    }
    [self removeFromSuperview];
    [[self getTopWindow] addSubview:self];
    
    _flags.animating = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = [UIScreen mainScreen].bounds;
        [self animationPlayerView];
    } completion:^(BOOL finished) {
        _flags.animating = NO;
    }];
}
-(UIWindow *)getTopWindow
{
    UIWindow * topWindows=[UIApplication sharedApplication].keyWindow;
    for (UIWindow *window in  [UIApplication sharedApplication].windows) {
        if (topWindows==nil) {
            topWindows =window;
        }
        if(topWindows.windowLevel<window.windowLevel){
            topWindows =window;
        }
    }
    return topWindows;
}

//- (void)deviceOrientationDidChange {
//    //这里有两个逻辑，第一个是水平翻转映射，第二个是90度旋转(分别顺时针和逆时针)
//    //搞清楚情况，在什么情况下水平反转呢？在什么情况下旋转呢？
//    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
//    UIDeviceOrientation oldOrientation = _currnetOrientation;
//    
//    self.currnetOrientation = currentOrientation;
//    
//    if (_flags.userNeedFullScreenMode) {
//        //用户自己想要全屏，所以程序不会自动控制
//        return;
//    }

//    switch (currentOrientation) {
//        case UIDeviceOrientationPortrait: {
//            if (self.animationType != PlayerKitAnimationTypeNone) {
//                [self restoreMode];
//            }
//            break;
//        }
//        case UIDeviceOrientationLandscapeLeft: {
//            if (self.animationType == PlayerKitAnimationTypeAnticlockwise) {
//                //水平反转
//                self.animationType = PlayerKitAnimationTypeClockwise;
//                [self horizontalFlipOrientation:oldOrientation];
//            } else {
//                [self animationWithAnimationType:PlayerKitAnimationTypeClockwise];
//            }
//            break;
//        }
//        case UIDeviceOrientationLandscapeRight: {
//            if (self.animationType == PlayerKitAnimationTypeClockwise) {
//                //水平反转
//                self.animationType = PlayerKitAnimationTypeAnticlockwise;
//                [self horizontalFlipOrientation:oldOrientation];
//            } else {
//                [self animationWithAnimationType:PlayerKitAnimationTypeAnticlockwise];
//            }
//            break;
//        }
//            
//        default:
//            break;
//    }
//}
#pragma mark - Delegate Helper Methods
- (void)callBackDelegateWithPlaybackState:(PlayerKitPlaybackState)playbackState {
    self.playbackState = playbackState;
    if ([self.playerView respondsToSelector:@selector(updatePlayingState:)]) {
        [self.playerView updatePlayingState:playbackState];
    }
    if ([self.delegate respondsToSelector:@selector(playerKitContainerPlaybackStateDidChange:)]) {
        [self.delegate playerKitContainerPlaybackStateDidChange:self];
    }
}

- (void)callBackDelegateWithBufferingState:(PlayerKitBufferingState)bufferingState {
    self.bufferingState = bufferingState;
    if ([self.delegate respondsToSelector:@selector(playerKitContainerBufferringStateDidChange:)]) {
        [self.delegate playerKitContainerBufferringStateDidChange:self];
    }
}

- (void)callBackDelegateWithReady {
    if ([self.delegate respondsToSelector:@selector(playerKitContainerReady:)]) {
        [self.delegate playerKitContainerReady:self];
    }
}

- (void)callBackDelegateWithStartBeginning {
    if ([self.delegate respondsToSelector:@selector(playerKitContainerPlaybackWillStartBeginning:)]) {
        [self.delegate playerKitContainerPlaybackWillStartBeginning:self];
    }
}

- (void)callBackDelegateWithPlaybackDidEnd {
    if ([self.delegate respondsToSelector:@selector(playerKitContainerPlaybackDidEnd:)]) {
        [self.delegate playerKitContainerPlaybackDidEnd:self];
    }
}

//更新当前播放器的进度条及显示当前播放时间
- (void)callBackDelegateWithDidChangeReadDuration:(CMTime)readDuration {
    self.readDuration = readDuration;
    if ([self.playerView respondsToSelector:@selector(updatePlayingTime:)]) {
        [self.playerView updatePlayingTime:readDuration];
    }
    if ([self.delegate respondsToSelector:@selector(playerKitContainer:didChangeReadDuration:)]) {
        [self.delegate playerKitContainer:self didChangeReadDuration:readDuration];
    }
}
//更新当前播放器的缓存进度条
- (void)callBackDelegateWithDidChangeBufferDuration:(CMTime)bufferDuration {
    self.bufferDuration = bufferDuration;
    if ([self.playerView respondsToSelector:@selector(updateBufferringTime:)]) {
        [self.playerView updateBufferringTime:bufferDuration];
    }
    if ([self.delegate respondsToSelector:@selector(playerKitContainer:didChangeBufferDuration:)]) {
        [self.delegate playerKitContainer:self didChangeBufferDuration:bufferDuration];
    }
}
//更新当前播放器的视频总长度
- (void)callBackDelegateWithDidLoadMediaTotalDuration {
    if ([self.playerView respondsToSelector:@selector(updateTotalTime:)]) {
        [self.playerView updateTotalTime:self.totalDuration];
    }
    if ([self.delegate respondsToSelector:@selector(playerKitContainer:didLoadMediaTotalDuration:)]) {
        [self.delegate playerKitContainer:self didLoadMediaTotalDuration:self.totalDuration];
    }
}

- (void)callBackDelegateWithAnimationType:(PlayerKitAnimationType)animationType {
    if ([self.delegate respondsToSelector:@selector(playerKitContainer:willAnimationWithType:)]) {
        [self.delegate playerKitContainer:self willAnimationWithType:animationType];
    }
}

- (void)callBackDelegateWithAnimationElement {
    if ([self.delegate respondsToSelector:@selector(playerKitContainerDidAnimationElement:)]) {
        [self.delegate playerKitContainerDidAnimationElement:self];
    }
}

#pragma mark - PlayerView Protocal Helper Methods
#pragma mark - Animation Helper Methods
//- (void)animationWithAnimationType:(PlayerKitAnimationType)animationType {
//    if (_animationType == animationType) {
//        return;
//    }
//    if (_flags.animating) {
//        return;
//    }
//    self.animationType = animationType;
//    _flags.animating = YES;
//    [self callBackDelegateWithAnimationType:self.animationType];
//    switch (animationType) {
//        case PlayerKitAnimationTypeZoom: {
//            [UIView animateWithDuration:0.3 animations:^{
//                self.transform = CGAffineTransformMakeScale(2.0, 2.0);
//                [self animationPlayerView];
//            } completion:^(BOOL finished) {
//                _flags.animating = NO;
//            }];
//            break;
//        }
//        case PlayerKitAnimationTypeClockwise:
//        case PlayerKitAnimationTypeAnticlockwise: {
//            CGRect mainBounds = [[UIScreen mainScreen] bounds];
//            CGFloat height = CGRectGetWidth(mainBounds);
//            CGFloat width = CGRectGetHeight(mainBounds);
//            CGRect frame = CGRectMake((height-width)/2, (width-height)/2, width, height);
//            UIInterfaceOrientation interfaceOrientation=UIInterfaceOrientationLandscapeRight;
//            CGFloat angle = M_PI_2;
//            if (animationType == PlayerKitAnimationTypeAnticlockwise) {
//                interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
//                angle = -M_PI_2;
//            }
//            
//            [UIView animateWithDuration:0.3 animations:^{
//                self.frame = frame;
//                [self setTransform:CGAffineTransformMakeRotation(angle)];
//                //ios6.o 之后设置状态栏方向函数被弃用
//                //[self setStatusBarOrientation:interfaceOrientation];
////                [self animationPlayerView];
//            } completion:^(BOOL finished) {
//                _flags.animating = NO;
//            }];
//            break;
//        }
//            
//        default:
//            break;
//    }
//}
//
//- (void)horizontalFlipOrientation:(UIDeviceOrientation)orientation {
//    if (_flags.animating) {
//        return;
//    }
//    UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationLandscapeRight;
//    CGFloat angle = M_PI_2;
//    if (orientation == UIDeviceOrientationLandscapeLeft) {
//        interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
//        angle = -M_PI_2;
//    }
//    CATransform3D transform = CATransform3DMakeRotation(angle, 0, 0, 1);
//    _flags.animating = YES;
//    [self callBackDelegateWithAnimationType:self.animationType];
//    [UIView animateWithDuration:0.55 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
////        [self setTransform:CGAffineTransformMakeRotation(angle)];
//        self.layer.transform = transform;
//        //ios6.o 之后设置状态栏方向函数被弃用
//        //[self setStatusBarOrientation:interfaceOrientation];
//        //                [self animationPlayerView];
//    } completion:^(BOOL finished) {
//         _flags.animating = NO;
//    }];
//}
//
//- (void)restoreMode {
//    self.animationType = PlayerKitAnimationTypeNone;
//    _flags.animating = YES;
//    [self callBackDelegateWithAnimationType:self.animationType];
//    [UIView animateWithDuration:0.3 animations:^{
//        [self setTransform:CGAffineTransformIdentity];
//        self.frame = self.presentFrame;
//        //ios6.o 之后设置状态栏方向函数被弃用
//        //[self setStatusBarOrientation:UIInterfaceOrientationPortrait];
//        [self animationPlayerView];
//    } completion:^(BOOL finished) {
//        _flags.animating = NO;
//    }];
//}

- (void)animationPlayerView {
    if ([self.playerView respondsToSelector:@selector(animationAction:)]) {
        [self.playerView animationAction:self.animationType];
    }
}

- (void)showIndicator {
    if ([self.playerView respondsToSelector:@selector(showIndicator)]) {
        [self.playerView showIndicator];
    }
}
- (void)hideIndicator {
    if ([self.playerView respondsToSelector:@selector(hideIndicator)]) {
        [self.playerView hideIndicator];
    }
}

- (void)showDownloadFailed {
    [self hideIndicator];
    if ([self.playerView respondsToSelector:@selector(showDownloadFailed)]) {
        [self.playerView showDownloadFailed];
    }
}

#pragma mark - KVO Helper Methods
- (void)addObserverWithPlayer:(AVPlayer *)player {
    [player addObserver:self forKeyPath:ZXHPlayerContainerRateKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *) ZXHPlayerObserverContext];
    
    //给AVPlayer 添加time Observer 有利于我们去检测播放进度
    __weak __typeof(self) weakSelf = self;
    _playbackTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1.0f, 1.0f) queue:NULL usingBlock:^(CMTime time) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf->_flags.readyToPlay && strongSelf.playbackState==PlayerKitPlaybackStatePlaying && strongSelf.playerItem && strongSelf.player) {
            [strongSelf callBackDelegateWithDidChangeReadDuration:time];
        }
    }];
}

- (void)removeObserverWithPlayer:(AVPlayer *)player {
    [player removeObserver:self forKeyPath:ZXHPlayerContainerRateKey context:(__bridge void *)ZXHPlayerObserverContext];
    [player removeTimeObserver:_playbackTimeObserver];
}

- (void)addObserverWithPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem addObserver:self forKeyPath:ZXHPlayerContainerEmptyBufferKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(ZXHPlayerItemObserverContext)];
    [playerItem addObserver:self forKeyPath:ZXHPlayerContainerPlayerKeepUpKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(ZXHPlayerItemObserverContext)];
    [playerItem addObserver:self forKeyPath:ZXHPlayerContainerPlayerBufferFullKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(ZXHPlayerItemObserverContext)];
    [playerItem addObserver:self forKeyPath:ZXHPlayerContainerStatusKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(ZXHPlayerItemObserverContext)];
    [playerItem addObserver:self forKeyPath:ZXHPlayerContainerPlayerLoadedTimeRanges options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(ZXHPlayerPreloadObserverContext)];
}

- (void)removeObserverWithPlayerItem:(AVPlayerItem *)playerItem {
    [playerItem removeObserver:self forKeyPath:ZXHPlayerContainerEmptyBufferKey context:(__bridge void *)ZXHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:ZXHPlayerContainerPlayerKeepUpKey context:(__bridge void *)ZXHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:ZXHPlayerContainerPlayerBufferFullKey context:(__bridge void *)ZXHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:ZXHPlayerContainerStatusKey context:(__bridge void *)ZXHPlayerItemObserverContext];
    [playerItem removeObserver:self forKeyPath:ZXHPlayerContainerPlayerLoadedTimeRanges context:(__bridge void *)ZXHPlayerPreloadObserverContext];
}

- (void)addObserverWithPlayerLayer:(AVPlayerLayer *)playeraLayer {
    [playeraLayer addObserver:self forKeyPath:ZXHPlayerContainerReadyForDisplay options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:(__bridge void *)(ZXHPlayerLayerObserverContext)];
}

- (void)removeObserverWithPlayerLayer:(AVPlayerLayer *)playeraLayer {
    [playeraLayer removeObserver:self forKeyPath:ZXHPlayerContainerReadyForDisplay context:(__bridge void *)ZXHPlayerLayerObserverContext];
}

#pragma mark - Notification Helper Methods
- (void)addNotification {
    //Application NSNotification
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)removeNotification {
    //notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)addNotificationWithPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemFailedToPlayToEndTime:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
}

- (void)removeNotificationWithPlayerItem:(AVPlayerItem *)playerItem {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
}

#pragma mark - Validation Helper Methos
- (void)validationLoadedTimeRanges:(NSArray *)timeRanges {
    if (timeRanges && [timeRanges count]) {
        CMTimeRange timerange = [[timeRanges firstObject] CMTimeRangeValue];//获取缓冲区域
        CMTime bufferDuration = CMTimeAdd(timerange.start, timerange.duration);// 计算缓冲总进度
        
        [self callBackDelegateWithDidChangeBufferDuration:bufferDuration];
        
        [self validationBufferduration:bufferDuration];
    }
}

- (void)validationBufferduration:(CMTime)bufferDuration {
    CMTime minPreloadBufferDuration = CMTimeMake(self.minPreloadBufferTimeToPlay, 1.0f);
    //如果预设的最小缓冲时间比总时间大的时候需要做特殊处理
    if (CMTIME_COMPARE_INLINE(minPreloadBufferDuration, >, self.totalDuration)) {
        minPreloadBufferDuration = CMTimeMake(CMTimeGetSeconds(self.totalDuration)/3.0, 1.0f);
    }
    CMTime milestone = CMTimeAdd(self.playerItem.currentTime, minPreloadBufferDuration);
    if (CMTIME_COMPARE_INLINE(bufferDuration, >=, milestone)) {
        //如果不是用户自己手动暂停的话，缓冲达到要求，就会自动播放
        if (self.autoPlaybackToMinPreloadBufferTime && !_flags.userPaused && ![self isPlaying]) {
            [self playCurrentTime];
        }
        //如果缓冲区达到要求
        self.bufferingState = PlayerKitBufferingStateUpToGrade;
    } else {
        //缓冲达不到要求
        self.bufferingState = PlayerKitBufferingStateDelayed;
    }
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (!_player || !_playerItem) {
        return;
    }
    if (context == (__bridge void *)ZXHPlayerObserverContext) {
        //Player KVO
        if ([keyPath isEqualToString:ZXHPlayerContainerRateKey]) {
            float rate = [change[NSKeyValueChangeNewKey] floatValue];
            if (rate) {
                _playbackState = PlayerKitPlaybackStatePlaying;
            } else {
                _playbackState = PlayerKitPlaybackStatePaused;
            }
        }
    } else if (context == (__bridge void *)ZXHPlayerItemObserverContext) {
        //PlayerItem KVO
        if ([keyPath isEqualToString:ZXHPlayerContainerEmptyBufferKey]) {
            if (self.playerItem.playbackBufferEmpty) {
                [self callBackDelegateWithBufferingState:PlayerKitBufferingStateDelayed];
            }
        } else if ([keyPath isEqualToString:ZXHPlayerContainerPlayerKeepUpKey]) {
            if (self.playerItem.playbackLikelyToKeepUp) {
                [self callBackDelegateWithBufferingState:PlayerKitBufferingStateKeepUp];
            }
        } else if ([keyPath isEqualToString:ZXHPlayerContainerPlayerBufferFullKey]) {
            if (self.playerItem.playbackBufferFull) {
                [self callBackDelegateWithBufferingState:PlayerKitBufferingStateFull];
            }
        } else if ([keyPath isEqualToString:ZXHPlayerContainerStatusKey]) {
            AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
            switch (status) {
                case AVPlayerStatusReadyToPlay: {
                    _flags.readyToPlay = YES;
                    break;
                }
                case AVPlayerStatusFailed: {
                    _flags.readyToPlay = NO;
                    [self callBackDelegateWithPlaybackState:PlayerKitPlaybackStateFailed];
                    break;
                }
                case AVPlayerStatusUnknown:
                default:
                    break;
            }
        }
    } else if (context == (__bridge void *)ZXHPlayerPreloadObserverContext) {
        if ([keyPath isEqualToString:ZXHPlayerContainerPlayerLoadedTimeRanges]) {//播放器缓冲进度
            if (_flags.readyToPlay || _flags.localFiled) {
                NSArray *timeRanges = (NSArray *)[change objectForKey:NSKeyValueChangeNewKey];
                [self validationLoadedTimeRanges:timeRanges];
            }
        }
    } else if (context == (__bridge void *)ZXHPlayerLayerObserverContext) {
        //PlayerLayer KVO
        if ([keyPath isEqualToString:ZXHPlayerContainerReadyForDisplay]) {
            if (self.playerView.playerLayer.readyForDisplay) {
                if (!_flags.firstReadyForDisplay) {
                    _flags.firstReadyForDisplay = YES;
                    [self.player seekToTime:kCMTimeZero];
                    [self.playerView.playerLayer setNeedsDisplay];
                }
                [self callBackDelegateWithReady];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Touches Methods
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    //Reset
    _currentLocation = CGPointZero;
    
    //这里得touches是一个NSSet,是个对象集合, anyObject 是指这个集合里边的任一对象
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 2) {
        //取消上一次的perform
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    CGFloat locationX = location.x;
    CGFloat locationY = location.y;
    
    CGFloat offsetX = locationX - _currentLocation.x;
    CGFloat offsetY = locationY - _currentLocation.y;
    if (CGPointEqualToPoint(_currentLocation, CGPointZero)) {
        _currentLocation = location;
        return;
    }
    _currentLocation = location;
    
    CGRect mainBounds = [UIScreen mainScreen].bounds;
    //屏幕分成三等分，第一分用于屏幕亮度，第二分用于播放速度，第三等分用于音量
    CGFloat perWidth = CGRectGetWidth(mainBounds)/3.0;
    
    BOOL horizontal = (ABS(offsetX)) > (ABS(offsetY));
    BOOL vertical = !horizontal;
    
    BOOL volumeConditions = (locationX > perWidth*2) && vertical;
    BOOL brightnessConditions = (locationX < perWidth) && vertical;
    BOOL playbackSpeedConditions = (locationX >= perWidth && locationX <= perWidth*2) && vertical;
    
    if (self.gestureState == PlayerKitGestureStateNone) {
        if (volumeConditions) {
            self.gestureState = PlayerKitGestureStateVolume;
        } else if (brightnessConditions) {
            self.gestureState = PlayerKitGestureStateBrightness;
        } else if (playbackSpeedConditions) {
            self.gestureState = PlayerKitGestureStatePlaybackSpeed;
        } else if (horizontal) {
            self.gestureState = PlayerKitGestureStateProgress;
        }
    }
    
    if ((self.gestureState == PlayerKitGestureStateVolume) && volumeConditions) {
        //音量
        [self handleGestureChangeWithPlus:(offsetY <= 0)];
    } else if ((self.gestureState == PlayerKitGestureStateBrightness) && brightnessConditions) {
        // 亮度
        [self handleGestureChangeWithPlus:(offsetY <= 0)];
    } else if ((self.gestureState == PlayerKitGestureStatePlaybackSpeed) && playbackSpeedConditions) {
        // 播放速度
        [self handleGestureChangeWithPlus:(offsetY <= 0)];
    } else if ((self.gestureState == PlayerKitGestureStateProgress) && horizontal) {
        // 进度
        [self handleGestureChangeWithPlus:(offsetX > 0)];
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    PlayerKitGestureState gestureState = self.gestureState;
    
    if (gestureState == PlayerKitGestureStateNone) {
        UITouch *touch = [touches anyObject];
        if (touch.tapCount == 1) {
            [self performSelector:@selector(handleSingleTap:) withObject:touch afterDelay:0.3];
        } else if (touch.tapCount == 2) {
            [self handleDoubleTap:touch];
        }
    } else if (gestureState == PlayerKitGestureStateVolume) {
        //隐藏声音指示器 （系统会自动隐藏）
    } else if (gestureState == PlayerKitGestureStatePlaybackSpeed) {
        //隐藏播放速度指示器
        if (self.allowControlPlaybackSpeedForGesture) {
            [self playCurrentTime];
        }
    } else if (gestureState == PlayerKitGestureStateBrightness) {
        //隐藏亮度指示器
    } else if (gestureState == PlayerKitGestureStateProgress) {
        //隐藏进度指示器，更新进度条
        // Reset
        _gestureTimeValue = 0.0;
        
        if (self.allowControlMediaProgressForGesture) {
            [self seekCurrentTimeValue:self.currentTimeValue];
        }
        if ([self.playerView respondsToSelector:@selector(updateControlProcessing:)]) {
            [self.playerView updateControlProcessing:PlayerKitProcessingStateNone];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
    
    self.gestureState = PlayerKitGestureStateNone;
}

#pragma mark - Touches handle Methods
//声音增加
- (void)volumePlus:(CGFloat)step {
    if (self.allowControlVolumeForGesture) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [MPMusicPlayerController applicationMusicPlayer].volume += step;
#pragma clang diagnostic pop
    }
}

//亮度增加
- (void)brightnessPlus:(CGFloat)step {
    if (self.allowControlBrightnessForGesture) {
        [UIScreen mainScreen].brightness += step;
    }
}

//播放速度
- (void)playbackSpeedPlus:(CGFloat)step {
    if (self.allowControlPlaybackSpeedForGesture) {
        [self machinePause];
        self.player.rate += step;
    }
}

//媒体进度
- (void)mediaProgressPlus:(CGFloat)step {
    [self machinePause];
    //当前时间累加step时间 我知道了，只获取第一次，然后在累加手势，而不是直接累加，哈哈
    CGFloat dragDownTimeValue = CMTimeGetSeconds(self.playerItem.currentTime);
    _gestureTimeValue += step;
    
    CGFloat dragedTimeValue = dragDownTimeValue + _gestureTimeValue;
    if (dragDownTimeValue > CMTimeGetSeconds(self.totalDuration)) {
        dragDownTimeValue = CMTimeGetSeconds(self.totalDuration);
    } else if (dragDownTimeValue < 0 || isnan(dragDownTimeValue)) {
        dragDownTimeValue = 0;
    }
    self.currentTimeValue = dragedTimeValue;
    if ([self.playerView respondsToSelector:@selector(updatePlayingTime:)]) {
        [self.playerView updatePlayingTime:CMTimeMake(self.currentTimeValue, 1.0f)];
    }
    if ([self.playerView respondsToSelector:@selector(updateControlProcessing:)]) {
        [self.playerView updateControlProcessing:(step>0 ? PlayerKitProcessingStateForward : PlayerKitProcessingStateBackward)];
    }
}

- (void)handleGestureChangeWithPlus:(BOOL)plus {
    switch (self.gestureState) {
        case PlayerKitGestureStateVolume: {
            [self volumePlus:(plus ? PlayerVolumeStep : -PlayerVolumeStep)];
            break;
        }
        case PlayerKitGestureStateBrightness: {
            [self brightnessPlus:(plus ? PlayerBrightnessStep : -PlayerBrightnessStep)];
            break;
        }
        case PlayerKitGestureStatePlaybackSpeed: {
            [self playbackSpeedPlus:(plus ? PlayerPlaybackSpeedStep : -PlayerPlaybackSpeedStep)];
            break;
        }
        case PlayerKitGestureStateProgress: {
            [self mediaProgressPlus:(plus ? PlayerMediaProgressStep : -PlayerMediaProgressStep)];
            break;
        }
        default:
            break;
    }
}

- (void)handleSingleTap:(UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    BOOL touchInTopBar = CGRectContainsPoint([self topToolsBarFrame], point);
    BOOL touchInBottomBar = CGRectContainsPoint([self bottomToolsBarFrame], point);
    //是否点击到工具条的区域
    if(!touchInTopBar && !touchInBottomBar) {
        if ([self.playerView respondsToSelector:@selector(animatedControlElement)]) {
            [self.playerView animatedControlElement];
        }
        [self callBackDelegateWithAnimationElement];
    }
}

- (void)handleDoubleTap:(UITouch *)touch {
    [self playerControl];
}

@end
