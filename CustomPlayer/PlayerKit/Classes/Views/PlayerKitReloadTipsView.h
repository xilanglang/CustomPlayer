//
//  PlayerKitReloadTipsView.h
//  CustomPlayer
//
//  Created by miniu on 16/10/20.
//  Copyright © 2016年 mini. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerKitReloadTipsView : UIView

@property (nonatomic, strong)UIButton *reloadButton;
@property (nonatomic, strong)UILabel *tipsLabel;

- (void)show;
- (void)dismiss;

@end
