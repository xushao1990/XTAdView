//
//  BTPhotoGallery.h
//  Venti
//
//  Created by Kevin Xue on 13-6-4.
//  Copyright (c) 2013年 Beijing Zhixun Innovation Co. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BTPhotoGallery : UIView
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;
@property (nonatomic, assign) CGFloat pageControlBottomGap;
@property (nonatomic, assign) NSInteger photoCornerRadius;
// 只有在loopScroll打开时，才可以打开autoScroll
@property (nonatomic, assign) BOOL autoScroll;
@property (nonatomic, assign) BOOL loopScroll;
@property (nonatomic, copy) ActionBlockIndex clickPhotoBlock;
- (void)hideImageCoverDecoration;
- (void)showImages:(NSArray *)images withTitles:(NSArray *)titles;

//Set scrollview width if needed
- (void)setScrollViewWidth:(CGFloat)scrollViewWidth;
- (void)setScrollViewWidthAndHeight:(CGFloat)scrollViewWidth;
@end

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)seconds
repeats:(BOOL)repeats
action:(TimerBlock)action {
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:@selector(timerFired)]];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                  invocation:invocation
                                                     repeats:repeats];
    [invocation setTarget:timer];
    [invocation setSelector:@selector(timerFired)];
    
    objc_setAssociatedObject(timer, @"action", action, OBJC_ASSOCIATION_COPY);
    
    return timer;
}

- (void)timerFired {
    TimerBlock action = (TimerBlock)objc_getAssociatedObject(self, @"action");
    BOOL stop = NO;
    action(&stop);
    if (stop)
        [self invalidate];
}