//
//  PlayerKitControlProgressTipsView.h
//  CustomPlayer
//
//  Created by miniu on 16/10/20.
//  Copyright © 2016年 mini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerKitPlayerViewProtocol.h"

@interface PlayerKitControlProgressTipsView : UIView

@property (nonatomic, assign)PlayerKitProcessingState processingState;
@property (nonatomic, copy)NSString *totalTimeString;
@property (nonatomic, copy)NSString *playingTimeString;

- (void)show;
- (void)dismiss;

@end
