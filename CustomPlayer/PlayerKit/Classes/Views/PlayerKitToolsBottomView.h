//
//  PlayerKitToolsBottomView.h
//  CustomPlayer
//
//  Created by miniu on 16/10/13.
//  Copyright © 2016年 mini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerKitProgressView.h"

@interface PlayerKitToolsBottomView : UIView

@property (nonatomic, strong)UIButton *mediaControlButton;

@property (nonatomic, strong)PlayerKitProgressView *progressView;
@property (nonatomic, strong)UILabel *processingTimeLabel;

@property (nonatomic, strong)UIButton *animationButton;

//
- (void)updatePlayControl:(BOOL)play;
- (void)updateAnimated:(BOOL)animated;

- (void)updateTotalTimeString:(NSString *)totalTimeString;
- (void)updatePlayingTimeString:(NSString *)playingTimeString;

@end
