//
//  PlayerKitReloadTipsView.m
//  CustomPlayer
//
//  Created by miniu on 16/10/20.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "PlayerKitReloadTipsView.h"

@implementation PlayerKitReloadTipsView

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
    self.backgroundColor = [UIColor blackColor];
    
    [self addSubview:self.reloadButton];
    [self addSubview:self.tipsLabel];
    
    [self dismiss];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tipsLabel.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.reloadButton.center = CGPointMake(self.tipsLabel.center.x, CGRectGetMaxY(self.tipsLabel.frame)+20);
}

- (void)show {
    self.hidden = NO;
}

- (void)dismiss {
    self.hidden = YES;
}

#pragma mark - Propertys
- (UIButton *)reloadButton {
    if (!_reloadButton) {
        _reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reloadButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_reloadButton setTitle:@"重试" forState:UIControlStateNormal];
        [_reloadButton setTitleColor:[UIColor colorWithRed:0.072 green:0.579 blue:1.000 alpha:1.000] forState:UIControlStateNormal];
        [_reloadButton addTarget:self action:@selector(reloadButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_reloadButton sizeToFit];
    }
    return _reloadButton;
}

- (void)reloadButtonClick {
    [self dismiss];
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipsLabel.textColor = [UIColor colorWithWhite:0.789 alpha:1.000];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.font = [UIFont systemFontOfSize:15];
        _tipsLabel.text = @"网络出错";
        [_tipsLabel sizeToFit];
    }
    return _tipsLabel;
}
@end
