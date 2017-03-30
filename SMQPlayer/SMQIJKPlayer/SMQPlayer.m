//
//  SMQPlayer.m
//  呜呜呜呜
//
//  Created by 孙明卿 on 2017/3/4.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import "SMQPlayer.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <AVFoundation/AVFoundation.h>
#import "MMMaterialDesignSpinner.h"
#import "Masonry.h"
#import "SMQPlayerItem.h"
static const CGFloat ZFPlayerAnimationTimeInterval             = 5.0f;
static const CGFloat ZFPlayerControlBarAutoFadeOutTimeInterval = 0.35f;
// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};
@interface SMQPlayer()<UIGestureRecognizerDelegate>//
@property (nonatomic,strong)id<IJKMediaPlayback> player;
/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat                sumTime;
/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection           panDirection;
/** 是否在调节音量*/
@property (nonatomic, assign) BOOL                   isVolume;
/** 滑杆 */
@property (nonatomic, strong) UISlider               *volumeViewSlider;
#pragma mark  ========  控制按钮
/** 标题 */
@property (nonatomic, strong) UILabel                 *titleLabel;
/** 开始播放按钮 */
@property (nonatomic, strong) UIButton                *startBtn;

/** 缓冲进度条 */
@property (nonatomic, strong) UIProgressView          *progressView;
/** 滑杆 */
@property (nonatomic, strong) UISlider   *videoSlider;
/** 全屏按钮 */
@property (nonatomic, strong) UIButton                *fullScreenBtn;
/** 系统菊花 */
@property (nonatomic, strong) MMMaterialDesignSpinner *activity;
/** 返回按钮*/
@property (nonatomic, strong) UIButton                *backBtn;
/** 重播按钮 */
@property (nonatomic, strong) UIButton                *repeatBtn;
/** bottomView*/
@property (nonatomic, strong) UIImageView             *bottomImageView;
/** topView */
@property (nonatomic, strong) UIImageView             *topImageView;
/** 加载失败按钮 */
@property (nonatomic, strong) UIButton                *failBtn;
/** 快进快退View*/
@property (nonatomic, strong) UIView                  *fastView;
/** 快进快退进度progress*/
@property (nonatomic, strong) UIProgressView          *fastProgressView;
/** 快进快退时间*/
@property (nonatomic, strong) UILabel                 *fastTimeLabel;
/** 快进快退ImageView*/
@property (nonatomic, strong) UIImageView             *fastImageView;
/** 当前选中的分辨率btn按钮 */
@property (nonatomic, weak  ) UIButton                *resoultionCurrentBtn;
/** 占位图 */
@property (nonatomic, strong) UIImageView             *placeholderImageView;

@property (nonatomic,strong)NSTimer *timer;

//正在显示中
@property (nonatomic,assign)BOOL showing;
//设置属性
@property (nonatomic,strong)IJKFFOptions *options;
#pragma mark   ======
@end
@implementation SMQPlayer

- (IJKFFOptions *)options {
    if (!_options) {
#ifdef DEBUG
        [IJKFFMoviePlayerController setLogReport:YES];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
        [IJKFFMoviePlayerController setLogReport:NO];
        [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
        [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
        _options = [IJKFFOptions optionsByDefault];
        //开启硬件解码
        [_options setOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_frame" ofCategory:kIJKFFOptionCategoryCodec];
        [_options setOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_loop_filter" ofCategory:kIJKFFOptionCategoryCodec];
        [_options setOptionIntValue:0 forKey:@"videotoolbox" ofCategory:kIJKFFOptionCategoryPlayer];
        [_options setOptionIntValue:60 forKey:@"max-fps" ofCategory:kIJKFFOptionCategoryPlayer];
        [_options setPlayerOptionIntValue:256 forKey:@"vol"];
        [_options setOptionIntValue:1 forKey:@"packet-buffering" ofCategory:kIJKFFOptionCategoryPlayer];
        [_options setPlayerOptionIntValue:0 forKey:@"max_cached_duration"];
        [_options setPlayerOptionIntValue:5      forKey:@"framedrop"];
        _options.showHudView = YES;
    }
    return _options;
}
- (instancetype)initWithItem:(SMQPlayerItem *)playerItem {
    if (self = [super init]) {
        //self.url = [NSURL URLWithString:@"http://www.dingdongedu.com/files/default/2017/02-28/wu_1ba1tn0h719kas9pueist7ig90.flv"];
        
        _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:playerItem.url withOptions:self.options];
        //获取播放view
        UIView *playerView = [self.player view];
        playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:playerView];
        [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsZero);
        }];
        [_player setScalingMode:IJKMPMovieScalingModeAspectFill];
        _player.playbackVolume = 1.0;
        //设置通知来监听视频的状态改变
        [self installMovieNotificationObservers];
        [_player prepareToPlay];
        //设置UI
        [self setPlayerUI];
        //设置单击双击时间
        [self addActionObservers];
        [self.activity startAnimating];
   
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self playerHideControlView];
}
- (void)setPlayerUI {
    //
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.topImageView];
    [self addSubview:self.bottomImageView];
    [self.bottomImageView addSubview:self.startBtn];
    [self.bottomImageView addSubview:self.currentTimeLabel];
    [self.bottomImageView addSubview:self.progressView];
    [self.bottomImageView addSubview:self.videoSlider];
    [self.bottomImageView addSubview:self.fullScreenBtn];
    [self.bottomImageView addSubview:self.totalTimeLabel];
    [self.topImageView addSubview:self.backBtn];
    [self addSubview:self.activity];
    [self addSubview:self.repeatBtn];
    [self addSubview:self.failBtn];
    
    [self addSubview:self.fastView];
    [self.fastView addSubview:self.fastImageView];
    [self.fastView addSubview:self.fastTimeLabel];
    [self.fastView addSubview:self.fastProgressView];
    
    [self.topImageView addSubview:self.titleLabel];
    // 添加子控件的约束
    [self makeSubViewsConstraints];
    [self playerResetControlView];
}
- (void)addActionObservers {
    //单机
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    tapGes.delegate = self;
    tapGes.numberOfTapsRequired = 1;
    tapGes.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tapGes];
    
    //双击
//    UITapGestureRecognizer *doubleGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
//    doubleGes.delegate = self;
//    doubleGes.numberOfTouchesRequired = 1;
//    doubleGes.numberOfTapsRequired = 2;
//    [self addGestureRecognizer:doubleGes];
//    //
//    [tapGes setDelaysTouchesBegan:YES];
   // [doubleGes setDelaysTouchesBegan:YES];
    //双击失败响应单击事件
//    [tapGes requireGestureRecognizerToFail:doubleGes];
    
}
- (void)makeSubViewsConstraints {
    [self.placeholderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.topImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.mas_top).offset(0);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(8);
        make.top.equalTo(self).offset(18);
        make.width.mas_equalTo(30);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.backBtn.mas_trailing).offset(5);
        make.centerY.equalTo(self.backBtn.mas_centerY);
        make.trailing.equalTo(self).offset(-10);
    }];
    
    [self.bottomImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        make.height.mas_equalTo(50);
    }];
    
    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomImageView.mas_leading).offset(5);
        make.bottom.equalTo(self.bottomImageView.mas_bottom).offset(-5);
        make.width.height.mas_equalTo(33);
    }];
    
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.startBtn.mas_trailing).offset(-4);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(33);
        make.trailing.equalTo(self.bottomImageView.mas_trailing).offset(-5);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.fullScreenBtn.mas_leading).offset(4);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.currentTimeLabel.mas_centerY).offset(-1);
        make.height.mas_equalTo(30);
    }];
    
    [self.repeatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self.activity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.with.height.mas_equalTo(45);
    }];
    
    [self.failBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(33);
    }];
    
    [self.fastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(125);
        make.height.mas_equalTo(80);
        make.center.equalTo(self);
    }];
    
    [self.fastImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_offset(32);
        make.height.mas_offset(32);
        make.top.mas_equalTo(5);
        make.centerX.mas_equalTo(self.fastView.mas_centerX);
    }];
    
    [self.fastTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.with.trailing.mas_equalTo(0);
        make.top.mas_equalTo(self.fastImageView.mas_bottom).offset(2);
    }];
    
    [self.fastProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(12);
        make.trailing.mas_equalTo(-12);
        make.top.mas_equalTo(self.fastTimeLabel.mas_bottom).offset(10);
    }];
 
}
#pragma mark - getter

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _titleLabel;
}

- (UIButton *)backBtn
{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"player_back_ico"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UIImageView *)topImageView
{
    if (!_topImageView) {
        _topImageView                        = [[UIImageView alloc] init];
        _topImageView.userInteractionEnabled = YES;
        _topImageView.image                  = [UIImage imageNamed:@"edit_shadows_top"];
    }
    return _topImageView;
}

- (UIImageView *)bottomImageView
{
    if (!_bottomImageView) {
        _bottomImageView                        = [[UIImageView alloc] init];
        _bottomImageView.userInteractionEnabled = YES;
        _bottomImageView.image                  = [UIImage imageNamed:@"ZFPlayer_bottom_shadow"];
    }
    return _bottomImageView;
}

- (UIButton *)startBtn
{
    if (!_startBtn) {
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startBtn setImage:[UIImage imageNamed:@"ZFPlayer_play"] forState:UIControlStateSelected];
        [_startBtn setImage:[UIImage imageNamed:@"ZFPlayer_pause"] forState:UIControlStateNormal];
        [_startBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

- (UILabel *)currentTimeLabel
{
    if (!_currentTimeLabel) {
        _currentTimeLabel               = [[UILabel alloc] init];
        _currentTimeLabel.textColor     = [UIColor whiteColor];
        _currentTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView                   = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _progressView.trackTintColor    = [UIColor clearColor];
    }
    return _progressView;
}

- (UISlider *)videoSlider
{
    if (!_videoSlider) {
        _videoSlider                       = [[UISlider alloc] init];
        [_videoSlider setThumbImage:[UIImage imageNamed:@"ZFPlayer_slider"] forState:UIControlStateNormal];
        _videoSlider.maximumValue          = 1;
        _videoSlider.minimumTrackTintColor = [UIColor whiteColor];
        _videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        // slider开始滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        // slider滑动中事件
        [_videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        // slider结束滑动事件
        [_videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
        [_videoSlider addGestureRecognizer:sliderTap];
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panRecognizer:)];
        panRecognizer.delegate = self;
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelaysTouchesBegan:YES];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        [_videoSlider addGestureRecognizer:panRecognizer];
    }
    return _videoSlider;
}

- (UILabel *)totalTimeLabel
{
    if (!_totalTimeLabel) {
        _totalTimeLabel               = [[UILabel alloc] init];
        _totalTimeLabel.textColor     = [UIColor whiteColor];
        _totalTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UIButton *)fullScreenBtn
{
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"ZFPlayer_fullscreen"] forState:UIControlStateNormal];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"ZFPlayer_shrinkscreen"] forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenBtn;
}

- (MMMaterialDesignSpinner *)activity
{
    if (!_activity) {
        _activity = [[MMMaterialDesignSpinner alloc] init];
        _activity.lineWidth = 1;
        _activity.duration  = 1;
        _activity.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    }
    return _activity;
}

- (UIButton *)repeatBtn
{
    if (!_repeatBtn) {
        _repeatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_repeatBtn setImage:[UIImage imageNamed:@"player_play_c"] forState:UIControlStateNormal];
        [_repeatBtn addTarget:self action:@selector(repeatBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _repeatBtn;
}

- (UIButton *)failBtn
{
    if (!_failBtn) {
        _failBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_failBtn setTitle:@"加载失败,点击重试" forState:UIControlStateNormal];
        [_failBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _failBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
        _failBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        [_failBtn addTarget:self action:@selector(failBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _failBtn;
}

- (UIView *)fastView
{
    if (!_fastView) {
        _fastView                     = [[UIView alloc] init];
        _fastView.backgroundColor     = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
        _fastView.layer.cornerRadius  = 4;
        _fastView.layer.masksToBounds = YES;
    }
    return _fastView;
}

- (UIImageView *)fastImageView
{
    if (!_fastImageView) {
        _fastImageView = [[UIImageView alloc] init];
    }
    return _fastImageView;
}

- (UILabel *)fastTimeLabel
{
    if (!_fastTimeLabel) {
        _fastTimeLabel               = [[UILabel alloc] init];
        _fastTimeLabel.textColor     = [UIColor whiteColor];
        _fastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _fastTimeLabel.font          = [UIFont systemFontOfSize:14.0];
    }
    return _fastTimeLabel;
}

- (UIProgressView *)fastProgressView
{
    if (!_fastProgressView) {
        _fastProgressView                   = [[UIProgressView alloc] init];
        _fastProgressView.progressTintColor = [UIColor whiteColor];
        _fastProgressView.trackTintColor    = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    }
    return _fastProgressView;
}

- (UIImageView *)placeholderImageView
{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.image = [UIImage imageNamed:@"ZFPlayer_loading_bgView"];
        _placeholderImageView.userInteractionEnabled = YES;
    }
    return _placeholderImageView;
}

#pragma mark  ========  installMovieNotificationObservers
- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    /**
     *  监听设备旋转通知
     */
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDeviceOrientationChange)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil
         ];
    //程序进入后台和前台
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];

    
}
- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
}
#pragma mark  =========  通知的方法
- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    
    if (self.player.playbackState==IJKMPMoviePlaybackStatePlaying) {
        self.placeholderImageView.alpha = 0.0;
        //视频开始播放的时候开启计时器
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(update) userInfo:nil repeats:YES];
            [self performSelector:@selector(playerShowControlView) withObject:nil afterDelay:0];
        }else {
            [self.timer setFireDate:[NSDate distantPast]];
        }
    }
    
    switch (self.player.playbackState) {
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
           
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            
            break;
            
        case IJKMPMoviePlaybackStatePaused://暂停
            [self.timer setFireDate:[NSDate distantFuture]];
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

- (void)update {
    self.currentTimeLabel.text = [MQAPPTool timeFormatterFromSeconds:self.player.currentPlaybackTime];
    CGFloat current = self.player.currentPlaybackTime;
    CGFloat total = self.player.duration;
    CGFloat able = self.player.playableDuration;
    [self.videoSlider setValue:current/total animated:YES];
    [self.progressView setProgress:able/total animated:YES];
  
}
/**
 视频播放结束

 @param notification note
 */
- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            self.backgroundColor  = RGBA(0, 0, 0, .6);
            self.repeatBtn.hidden = NO;
            // 初始化显示controlView为YES
            [self playerShowControlView];
            //当前时间改成总时间
            self.currentTimeLabel.text = self.totalTimeLabel.text;
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            self.failBtn.hidden = NO;
            break;
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
    [self.timer setFireDate:[NSDate distantFuture]];
}
/**
 是否正在缓冲

 @param notification note

 */
- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    //重置打点
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        self.totalTimeLabel.text = [MQAPPTool timeFormatterFromSeconds:self.player.duration];
        [self.activity setAnimating:NO];
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
       [self.activity setAnimating:YES];
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
   
    [self playerResetControlView];
    // 添加平移手势，用来控制音量、亮度、快进快退
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    panRecognizer.delegate = self;
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelaysTouchesBegan:YES];
    [panRecognizer setDelaysTouchesEnded:YES];
    [panRecognizer setCancelsTouchesInView:YES];
    [self addGestureRecognizer:panRecognizer];
    //视频准备好播放了
    if (self.mqdelegate && [self.mqdelegate respondsToSelector:@selector(smqPlayer:didStartPlay:)]) {
        [self.mqdelegate smqPlayer:self didStartPlay:self.item];
    }
}

#pragma mark  =================================   按钮或者屏幕的触摸事件
/**
 *   轻拍方法
 *
 *   gesture
 */

- (void)singleTapAction:(UIGestureRecognizer *)gesture {
    
//    if ([gesture isKindOfClass:[NSNumber class]] && ![(id)gesture boolValue]) {
//        [self _fullScreenAction];
//        return;
//    }
    if (gesture.state == UIGestureRecognizerStateRecognized) {
       // if (self.isBottomVideo && !self.isFullScreen) { [self _fullScreenAction]; }
    
      if (!self.repeatBtn.hidden) { return; }
            [self playerShowControlView];
    }
}
/**
 *  显示控制层
 */
- (void)playerShowControlView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerHideControlView) object:nil];
    if (self.showing) {
        [self playerHideControlView];
        return;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        self.topImageView.alpha    = 1;
        self.bottomImageView.alpha = 1;
        self.showing = YES;
    } completion:^(BOOL finished) {
        if (self.player.playbackState == IJKMPMoviePlaybackStatePlaying) {
            [self performSelector:@selector(playerHideControlView) withObject:nil afterDelay:ZFPlayerAnimationTimeInterval];
        }
    }];
    
}
/**
 *  隐藏控制层
 */
- (void)playerHideControlView
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [UIView animateWithDuration:ZFPlayerControlBarAutoFadeOutTimeInterval animations:^{
        self.topImageView.alpha       = !self.repeatBtn.hidden;
        self.bottomImageView.alpha    = 0;
    }completion:^(BOOL finished) {
        self.showing = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerHideControlView) object:nil];
    }];
}
- (void)doubleTapAction:(UIGestureRecognizer *)gesture {
    
}
#pragma mark  ====================  公共方法
/** 重置ControlView */
- (void)playerResetControlView
{
    [self.activity stopAnimating];
    self.videoSlider.value           = 0;
    self.progressView.progress       = 0;
    self.currentTimeLabel.text       = @"00:00";
    self.totalTimeLabel.text         = @"00:00";
    self.fastView.hidden             = YES;
    self.repeatBtn.hidden            = YES;
    self.failBtn.hidden              = YES;
    self.backgroundColor             = [UIColor clearColor];
    self.failBtn.hidden              = YES;
    self.placeholderImageView.alpha  = 1;
}
#pragma mark  ======= slider 滑块的响应方法
- (void)progressSliderTouchBegan:(UISlider *)sender
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerHideControlView) object:nil];
    //暂停计时器
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (void)progressSliderValueChanged:(UISlider *)sender
{
    self.currentTimeLabel.text = [MQAPPTool timeFormatterFromSeconds:sender.value * self.player.playableDuration];
    
}

- (void)progressSliderTouchEnded:(UISlider *)sender
{
    self.player.currentPlaybackTime = self.videoSlider.value * self.player.playableDuration;
    [self performSelector:@selector(playerHideControlView) withObject:nil afterDelay:ZFPlayerAnimationTimeInterval];
    //打开计时器
    [self.timer setFireDate:[NSDate distantPast]];

}
- (void)tapSliderAction:(UIGestureRecognizer *)gesture {}

- (void)panRecognizer:(UIGestureRecognizer *)gesture {}
/**
 slider滑块的bounds
 */
- (CGRect)thumbRect
{
    return [self.videoSlider thumbRectForBounds:self.videoSlider.bounds
                                      trackRect:[self.videoSlider trackRectForBounds:self.videoSlider.bounds]
                                          value:self.videoSlider.value];
}
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGRect rect = [self thumbRect];
    CGPoint point = [touch locationInView:self.videoSlider];
    if ([touch.view isKindOfClass:[UISlider class]]) { // 如果在滑块上点击就不响应pan手势
        if (point.x <= rect.origin.x + rect.size.width && point.x >= rect.origin.x) { return NO; }
    }
    return YES;
}

#pragma mark  =======  控制层按钮的响应方法
- (void)fullScreenBtnClick:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if (self.mqdelegate && [self.mqdelegate respondsToSelector:@selector(smqPlayer:fullScreenBtn:)]) {
        [self.mqdelegate smqPlayer:self fullScreenBtn:sender];
    }
}

- (void)backBtnClick:(UIButton *)sender {
    //点击了返回注销播放器
    [self shutdownPlayer];
    
    if (self.mqdelegate && [self.mqdelegate respondsToSelector:@selector(smqPlayer:backBtn:)]) {
        [self.mqdelegate smqPlayer:self backBtn:sender];
    }
}

- (void)playBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerHideControlView) object:nil];
        [self.player pause];
    }else {
        [self playerHideControlView];
        [self.player play];
    }
   
}
- (void)repeatBtnClick:(UIButton *)sender {
    
}

- (void)failBtnClick:(UIButton *)sender {
    
}

//用来控制声音快进等
- (void)panDirection:(UIPanGestureRecognizer *)pan {
    //根据当前的位置判断调整的是音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    //我们要响应水平移动和垂直移动‘
    //根据上次和本次移动的位置算出移动的速率
    CGPoint veloctyPoint = [pan velocityInView:self];
    //判断是水平移动还是垂直移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan://开始移动
        {
         //判断移动方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) {//水平移动
                //取消隐藏
                self.panDirection = PanDirectionHorizontalMoved;
                //给sumtime赋初值
                NSTimeInterval Time = self.player.currentPlaybackTime;
                self.sumTime = Time;
            }else if(x < y) {//垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                //开始滑动的时候状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else {
                    self.isVolume = NO;
                }
            }
        }
            break;
        case UIGestureRecognizerStateChanged:{//正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:
                    [self horizontalMoved:veloctyPoint.x];
                    break;
                    case PanDirectionVerticalMoved:
                    [self verticalMoved:veloctyPoint.y];
                    break;
            }
        }
            break;
        case UIGestureRecognizerStateEnded:{
            // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    self.player.currentPlaybackTime = self.sumTime;
                    //打开计时器
                    [self.timer setFireDate:[NSDate distantPast]];
                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    self.fastView.hidden  = YES;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
    }

        default:
            break;
    }
}
/**
 *  pan垂直移动的方法
 *
 *  @param value void
 */
- (void)verticalMoved:(CGFloat)value
{
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
}

/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value
{
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    
    // 需要限定sumTime的范围
    CGFloat totalMovieDuration = self.player.duration;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    BOOL style = false;
    if (value > 0) { style = YES; }
    if (value < 0) { style = NO; }
    if (value == 0) { return; }
    [self zf_playerDraggedTime:self.sumTime totalTime:totalMovieDuration isForward:style hasPreview:NO];
    
}

/**
 *  根据时长求出字符串
 *
 *  @param time 时长
 *
 *  @return 时长字符串
 */
- (NSString *)durationStringWithTime:(int)time
{
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}
/**
 *  获取系统音量
 */
- (void)configureVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}
/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 耳机拔掉
            // 拔掉耳机继续播放
            [self.player play];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}
- (void)zf_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview
{
    // 快进快退时候停止菊花和计时器
    [self.activity stopAnimating];
    [self.timer setFireDate:[NSDate distantFuture]];
    // 拖拽的时长
    NSInteger proMin = draggedTime / 60;//当前秒
    NSInteger proSec = draggedTime % 60;//当前分钟
    
    //duration 总时长
    NSInteger durMin = totalTime / 60;//总秒
    NSInteger durSec = totalTime % 60;//总分钟
    
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    NSString *totalTimeStr   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    CGFloat  draggedValue    = (CGFloat)draggedTime/(CGFloat)totalTime;
    NSString *timeStr        = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totalTimeStr];
    
    if (forawrd) {
        self.fastImageView.image = [UIImage imageNamed:@"ZFPlayer_fast_forward"];
    } else {
        self.fastImageView.image = [UIImage imageNamed:@"ZFPlayer_fast_backward"];
    }
    self.fastView.hidden           = preview;
    self.fastTimeLabel.text        = timeStr;
    self.fastProgressView.progress = draggedValue;
    self.currentTimeLabel.text = currentTimeStr;
    self.videoSlider.value = draggedValue;
}
#pragma mark  =====  屏幕旋转的通知
/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationPortraitUpsideDown) { return; }
    if (UIDeviceOrientationLandscapeRight == orientation || UIDeviceOrientationLandscapeLeft == orientation) {
         self.fullScreenBtn.selected = YES;
    } else {
        //
        if (self.mqdelegate && [self.mqdelegate respondsToSelector:@selector(smqOrentatiionChangePlayer:)]) {
            [self.mqdelegate smqOrentatiionChangePlayer:self];
        }
        self.fullScreenBtn.selected = NO;
    }
    if (self.repeatBtn.hidden) {
        [self playerShowControlView];
    }
    
}

- (void)appDidEnterBackground {
    
}
- (void)appDidEnterPlayground {
    
}
- (void)reSetPlayerWithItem:(SMQPlayerItem *)playerItem {
    [self shutdownPlayer];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:playerItem.url withOptions:self.options];
    //获取播放view
    UIView *playerView = [self.player view];
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:playerView belowSubview:self.placeholderImageView];
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFill];
    _player.playbackVolume = 1.0;
    //设置通知来监听视频的状态改变
    [self installMovieNotificationObservers];
    [_player prepareToPlay];
}
//注销播放器
- (void)shutdownPlayer {
    [self.timer invalidate];
    self.timer = nil;
    [self.player shutdown];
    [[self.player view] removeFromSuperview];
    self.player = nil;
    //初始化视图
    [self playerResetControlView];
    //注销通知
    [self removeMovieNotificationObservers];
}

@end
