//
//  XTAdView.m
//  XTAdView
//
//  Created by Tongtong Xu on 15/2/12.
//  Copyright (c) 2015年 xxx Innovation Co. Ltd. All rights reserved.
//

#import "XTAdView.h"

@interface XTAdView ()<UIScrollViewDelegate>
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@end

@implementation XTAdView

- (void)awakeFromNib
{
    [super awakeFromNib];
}


@end
