//
//  BTPhotoGallery.m
//  Venti
//
//  Created by Kevin Xue on 13-6-4.
//  Copyright (c) 2013年 Beijing Zhixun Innovation Co. Ltd. All rights reserved.
//

#import "BTPhotoGallery.h"
#import "UIImageView+ImageCache.h"
#import <QuartzCore/QuartzCore.h>
#import "NSTimer+BTAddition.h"
#import "UIView+Hierarchy.h"

#define BTPhotoTagOffset 1000

@interface BTPhotoGallery () <UIScrollViewDelegate>

@property (nonatomic, retain) UIScrollView *sv;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIButton *backgroundBtn;
@property (nonatomic, retain) UIImageView *imageCover;

@property (nonatomic, retain) NSArray *images; // 可以是 UIImage 或者图片的地址 NSURL/NSString
@property (nonatomic, retain) NSArray *titles;

@property (nonatomic, retain) NSTimer *scrollTimer;

@end

@implementation BTPhotoGallery

#pragma mark - Life Cycle

- (void)prepare {
    self.backgroundColor = [UIColor clearColor];
    _sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    _sv.delegate = self;
    _sv.backgroundColor = [UIColor clearColor];
    _sv.bounces = NO;
    _sv.scrollsToTop = NO;
    _sv.pagingEnabled = YES;
    _sv.showsHorizontalScrollIndicator = NO;
    _sv.showsVerticalScrollIndicator = NO;
    [self addSubview:_sv];
    
    // page control
    if (self.pageControl == nil) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.hidesForSinglePage = YES;
        CGFloat pageControlHeight = 20;
        self.pageControl.frame = CGRectMake(0,
                                            self.bounds.size.height - pageControlHeight - self.pageControlBottomGap,
                                            self.bounds.size.width,
                                            pageControlHeight);
        [self addSubview:_pageControl];
    }
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.frame = CGRectMake(30, 22, self.bounds.size.width - 30*2, 34);
    _titleLabel.font = [UIFont gothamBookWithSize:29 forChinese:YES];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.minimumFontSize = 11;
    _titleLabel.shadowOffset = CGSizeMake(0, 1);
    _titleLabel.shadowColor = [UIColor blackColor];
    [self addSubview:_titleLabel];
    
    _backgroundBtn = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    _backgroundBtn.backgroundColor = [UIColor clearColor];
    [_backgroundBtn addTarget:self action:@selector(clickPhoto) forControlEvents:UIControlEventTouchUpInside];
    _backgroundBtn.hidden = YES;


    self.imageCover = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo_gallery_cover"]] autorelease];
    
    self.pageControlBottomGap = 10;
    
    self.autoScroll = YES;
    self.loopScroll = YES;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self prepare];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self prepare];
    }
    return self;
}



- (void)dealloc {
    [_imageCover release];
    [_images release];
    [_titles release];
    [_sv release];
    [_clickPhotoBlock release];
    [_scrollTimer invalidate];
    [_scrollTimer release];
    [_pageControl release];
    [_titleLabel release];
    [_backgroundBtn release];
    [super dealloc];
}

#pragma mark - Public

- (void)setScrollViewWidth:(CGFloat)scrollViewWidth {
    self.sv.frame = CGRectMake(0, 0, scrollViewWidth, CGRectGetHeight(self.sv.bounds));
}

- (void)setScrollViewWidthAndHeight:(CGFloat)scrollViewWidth {
    self.sv.frame = CGRectMake(0, 0, scrollViewWidth, scrollViewWidth*0.53);
}

- (void)hideImageCoverDecoration {
    self.imageCover.hidden = YES;
}

- (void)showImages:(NSArray *)images withTitles:(NSArray *)titles {
    if ([self.images isEqualToArray:images])
        return;
    
    self.images = images;
    self.titles = titles;
    [self.sv removeSubviews];
    
    if (self.images.count == 0)
        return;
    
    // 添加照片
    CGFloat width = self.sv.bounds.size.width;
    CGFloat height = self.sv.bounds.size.height;
        
    for (NSInteger index = 0; index < images.count; index ++) {
        UIImageView *imageView = [self createImageView];
        imageView.frame = CGRectMake(index * width, 0, width, height);
        imageView.tag = index + BTPhotoTagOffset;
        [self.sv addSubview:imageView];
    }

    self.sv.contentSize = CGSizeMake(width * images.count, height);
    self.sv.contentOffset = CGPointZero;
    
    if (self.photoCornerRadius)
        self.sv.layer.cornerRadius = self.photoCornerRadius;
    
    // 准备好第一张照片
    [self renderImage:0];

    // 按下事件
    _backgroundBtn.frame = CGRectMake(0, 0, _sv.contentSize.width, _sv.contentSize.height);
    [_sv addSubview:_backgroundBtn];
    
    // 更改page control
    self.pageControl.numberOfPages = images.count;
    self.pageControl.currentPage = 0;
    
    self.titleLabel.text = [titles objectOrNilAtIndex:0];

    self.imageCover.frame = CGRectMake(self.sv.frame.origin.x,
                                       self.sv.frame.origin.y + self.sv.frame.size.height - self.imageCover.bounds.size.height,
                                       self.sv.frame.size.width,
                                       self.imageCover.bounds.size.height);
    [self addSubview:self.imageCover];
    
    // 自动滚动
    [self setupLoopScroll];
    [self beginAutoScroll];
}

- (UIImageView *)createImageView {
    UIImageView *imageView = [[[UIImageView alloc] init] autorelease];
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleToFill;
    [imageView setupProgressBar];
    imageView.backgroundColor = [UIColor colorWithRed:231.0/255.0
                                                green:221.0/255.0
                                                 blue:198.0/255.0
                                                alpha:1.0];
    if (self.photoCornerRadius)
        imageView.layer.cornerRadius = self.photoCornerRadius;
    
    return imageView;
}

#pragma mark - Scroll

- (void)beginAutoScroll {
    if (self.autoScroll == NO)
        return;
    
    [self endAutoScroll];
    self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(scrollToNextPhoto) userInfo:nil repeats:YES];
}

- (void)endAutoScroll {
    if (self.autoScroll == NO)
        return;
    
    [self.scrollTimer invalidate];
    self.scrollTimer = nil;
}

- (void)scrollToNextPhoto {
    if (!self.pageControl)
        return;
    
    NSInteger page = roundf(self.sv.contentOffset.x / self.sv.bounds.size.width);
    NSInteger nextPage = page + 1;
    [self.sv setContentOffset:CGPointMake(self.sv.bounds.size.width * nextPage, 0) animated:YES];
    self.pageControl.currentPage = [self loopScrollDataIndex:nextPage];
    [self renderImage:nextPage];
}

- (void)setupLoopScroll {
    if (self.loopScroll == NO)
        return;
    
    if (self.images.count <= 1) {
        self.loopScroll = NO;
        self.autoScroll = NO;
        return;
    }
    
    CGFloat width = self.sv.bounds.size.width;
    CGFloat height = self.sv.bounds.size.height;
    
    UIImageView *imageView = [self createImageView];
    imageView.frame = CGRectMake(-1 * width, 0, width, height);
    imageView.tag = -1 + BTPhotoTagOffset;
    [self.sv addSubview:imageView];
    [self renderImage:-1];
    
    imageView = [self createImageView];
    imageView.frame = CGRectMake(self.images.count * width, 0, width, height);
    imageView.tag = self.images.count + BTPhotoTagOffset;
    [self.sv addSubview:imageView];
    
    self.sv.contentInset = UIEdgeInsetsMake(0, width, 0, width);
    self.sv.contentOffset = CGPointZero;
}

- (void)resetLoopScroll {
    if (self.loopScroll == NO)
        return;
    
    CGFloat leftBound = 0;
    CGFloat rightBound = self.sv.contentSize.width - self.sv.frame.size.width;
    
    if (self.sv.contentOffset.x <= -self.sv.bounds.size.width)
        self.sv.contentOffset = CGPointMake(rightBound, 0);
    else if (self.sv.contentOffset.x >= self.sv.contentSize.width)
        self.sv.contentOffset = CGPointMake(leftBound, 0);
}

- (NSInteger)loopScrollDataIndex:(NSInteger)index {
    if (self.loopScroll == NO)
        return (index >= self.images.count) ? self.images.count : index;
    
    if (index == -1)
        index = self.images.count - 1;
    else if (index == self.images.count)
        index = 0;
    
    return index;
}

#pragma mark - Scroll View

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self endAutoScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO)
        [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger page = roundf(scrollView.contentOffset.x / scrollView.bounds.size.width);
    self.pageControl.currentPage = page;
    [self renderImage:page];
    
    [self beginAutoScroll];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self resetLoopScroll];
    
    if (0 <= scrollView.contentOffset.x
        && scrollView.contentOffset.x <= scrollView.contentSize.width-scrollView.frame.size.width) {
        
        NSInteger offsetX = roundf(scrollView.contentOffset.x);
        NSInteger width = roundf(scrollView.bounds.size.width);
        NSInteger width_2 = width / 2;
        NSInteger page = offsetX / width;
        page = [self loopScrollDataIndex:page];
        
        offsetX = offsetX % width;
        if (offsetX <= width_2) {
            self.titleLabel.alpha = (width_2-offsetX)/(CGFloat)width_2;
            NSString *title = [self.titles objectOrNilAtIndex:page];
            if (title) {
                self.titleLabel.text = title;
                self.titleLabel.hidden = NO;
            } else {
                self.titleLabel.hidden = YES;
            }
        } else {
            self.titleLabel.alpha = (offsetX-width_2)/(CGFloat)width_2;
            NSString *title = [self.titles objectOrNilAtIndex:page+1];
            if (title) {
                self.titleLabel.text = title;
                self.titleLabel.hidden = NO;
            } else {
                self.titleLabel.hidden = YES;
            }
        }
    }
}

#pragma mark - Page Control

- (IBAction)pageControlDidChange:(UIPageControl *)pageControl {
    [self.sv setContentOffset:CGPointMake(self.sv.bounds.size.width * self.pageControl.currentPage, 0) animated:YES];
    [self renderImage:self.pageControl.currentPage];
}

#pragma mark -

- (void)clickPhoto {
    NSInteger page = self.sv.contentOffset.x / self.sv.bounds.size.width;
    if (self.clickPhotoBlock) {
        self.clickPhotoBlock(page);
    }
}

- (void)setClickPhotoBlock:(ActionBlockIndex)clickPhotoBlock {
    [_clickPhotoBlock release];
    _clickPhotoBlock = [clickPhotoBlock copy];
    _backgroundBtn.hidden = clickPhotoBlock == nil;
}

- (void)renderImage:(NSInteger)index {
    id image = [self.images objectOrNilAtIndex:[self loopScrollDataIndex:index]];
    UIImageView *imageView = (id)[self.sv viewWithTag:index + BTPhotoTagOffset];
    
    if ([image isKindOfClass:[UIImage class]])
        imageView.image = image;
    else if ([image isKindOfClass:[NSString class]])
        [imageView setImageWithUrlFromImageCache:VURL_MEDIA(image) withPlaceHolder:nil];
    else if ([image isKindOfClass:[NSURL class]])
        [imageView setImageWithUrlFromImageCache:image withPlaceHolder:nil];
}

@end
