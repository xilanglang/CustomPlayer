//
//  PlayerKitToolsTopView.m
//  CustomPlayer
//
//  Created by miniu on 16/10/11.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "PlayerKitToolsTopView.h"

@implementation PlayerKitToolsTopView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
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
    self.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.88];
    
    [self addSubview:self.closeButton];
    [self addSubview:self.titleLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat size = 44;
    CGRect closeButtonFrame = self.closeButton.frame;
    closeButtonFrame.size = CGSizeMake(size, size);
    closeButtonFrame.origin.y = 20;
    self.closeButton.frame = closeButtonFrame;
    
    CGRect titleLabelFrame = CGRectMake(CGRectGetMaxX(closeButtonFrame)+10, 20, CGRectGetMidX(self.bounds), size);
    self.titleLabel.frame = titleLabelFrame;
}

#pragma mark - Propertys
- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:@"player-kit-close"] forState:UIControlStateNormal];
    }
    return _closeButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
//        _titleLabel.text = @"测试标题";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

@end
