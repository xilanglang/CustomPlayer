//
//  PlayerKitVideoLayerView.m
//  CustomPlayer
//
//  Created by miniu on 16/9/30.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "PlayerKitVideoLayerView.h"

@implementation PlayerKitVideoLayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)commit {
    self.playerLayer.backgroundColor=[[UIColor blackColor] CGColor];
    self.videoFillMode = AVLayerVideoGravityResizeAspect;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commit];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commit];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer]  setPlayer:player];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (AVPlayerLayer *)playerLayer{
    return (AVPlayerLayer *)self.layer;
}

- (void)setVideoFillMode:(NSString *)videoFillMode {
    [self playerLayer].videoGravity = videoFillMode;
}

- (NSString *)videoFillMode{
    return [self playerLayer].videoGravity;
}
@end
