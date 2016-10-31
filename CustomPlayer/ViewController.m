//
//  ViewController.m
//  CustomPlayer
//
//  Created by miniu on 16/9/30.
//  Copyright © 2016年 mini. All rights reserved.
//

#import "ViewController.h"
#import "PlayerKit.h"

@interface ViewController ()

@property (nonatomic, strong) PlayerKitContainer *playerContainer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.playerContainer];
}

- (PlayerKitContainer *)playerContainer {
    if (!_playerContainer) {
        //视频文件的url路径
//        NSString *url=[[NSBundle mainBundle] pathForResource:@"1.MOV" ofType:Nil];
        //http://flv2.bn.netease.com/videolib3/1610/19/iAkVl7224/SD/iAkVl7224-mobile.mp4
        //http://childapp.pailixiu.com/Jack/sample_iPod.m4v
        NSString *url = @"http://flv2.bn.netease.com/videolib3/1610/19/iAkVl7224/SD/iAkVl7224-mobile.mp4";
        _playerContainer = [[PlayerKitContainer alloc] init];
//        _playerContainer.delegate = self;
        _playerContainer.playbackLoops = NO;
//        _playerContainer.allowControlPlaybackSpeedForGesture = YES;
        _playerContainer.leaveblackBorderAtStatusBar=NO;
        _playerContainer.mediaPath = url;
        _playerContainer.presentFrame=CGRectMake(0, 80, CGRectGetWidth(self.view.bounds), 300);
        [_playerContainer buildInterface];
    }
    return _playerContainer;
}
//屏幕翻转
- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    //记录当前是横屏还是竖屏  yes:竖屏  no:横屏
    BOOL isPortrait = size.width < size.height;
    CGFloat duration = [coordinator transitionDuration];
    
    [UIView animateWithDuration:duration animations:^{
        //设置topView的frame
        [self.playerContainer rotateToLandscape:isPortrait size:size];
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
