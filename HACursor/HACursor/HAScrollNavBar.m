//
//  HAScrollNavBar.m
//  HAScrollNavBar
//
//  Created by haha on 15/5/2.
//  Copyright (c) 2015年 haha. All rights reserved.
//

#import "HAScrollNavBar.h"
#import "UIView+Extension.h"
#import "UIColor+RGBA.h"
#import "HAItemManager.h"
#import "UIScrollView+Extension.h"

#define ItemWidth 75
#define FontMinSize 15
#define FontDetLeSize 10
#define FontDefSize 16
#define StaticItemIndex 3
#define scrollNavBarUpdate @"scrollNavBarUpdate"
#define HAScrollItemIndex @"index"
#define rootScrollUpdateAfterSort @"updateAfterSort"
#define moveToSelectedItem @"moveToSelectedItem"
#define moveToTop @"moveToTop"

@interface HAScrollNavBar()<UIScrollViewDelegate>

@property (nonatomic, weak) UIButton *firstButton;
@property (nonatomic, weak) UIButton *secButton;

@property (nonatomic, strong) NSMutableDictionary *tmpPageViewDic;

#warning --- 以字典来管理item
@property (nonatomic, strong) NSMutableDictionary *itemsDic;
@property (nonatomic, strong) NSMutableArray *tmpKeys;

@property (nonatomic, assign) CGPoint beginPoint;
@property (nonatomic, assign) CGFloat lastXpoint;
@property (nonatomic, assign) NSInteger currctIndex;
@property (nonatomic, assign) CGFloat red1;
@property (nonatomic, assign) CGFloat green1;
@property (nonatomic, assign) CGFloat blue1;
@property (nonatomic, assign) CGFloat alpha1;
@property (nonatomic, assign) CGFloat red2;
@property (nonatomic, assign) CGFloat green2;
@property (nonatomic, assign) CGFloat blue2;
@property (nonatomic, assign) CGFloat alpha2;
@end

@implementation HAScrollNavBar
- (void)setItemKeys:(NSMutableArray *)itemKeys{
    _itemKeys = itemKeys;
    self.tmpKeys = itemKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupItems];
    });
}

- (NSMutableArray *)tmpKeys{
    if (!_tmpKeys) {
        _tmpKeys = [NSMutableArray array];
    }
    return _tmpKeys;
}

- (NSInteger)getIndexWithKey:(NSString *)key{
    return [self.itemKeys indexOfObject:key];
}

- (UIButton *)getItemWithIndex:(NSInteger)index{
    return [self.itemsDic objectForKey:self.tmpKeys[index]];
}

//创建按钮
- (UIButton *)createItemWithTitle:(NSString *)title{
    UIButton *button = [[UIButton alloc]init];
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.font = [UIFont systemFontOfSize:FontDefSize];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    return button;
}

- (NSMutableDictionary *)itemsDic{
    if (!_itemsDic) {
        _itemsDic = [NSMutableDictionary dictionary];
    }
    return _itemsDic;
}

- (void)setupTmpPageViewDic{
    for (int i = 0; i < self.tmpKeys.count; i++) {
        [self.tmpPageViewDic setObject:self.pageViews[i] forKey:self.tmpKeys[i]];
    }
}

- (NSMutableDictionary *)tmpPageViewDic{
    if (!_tmpPageViewDic) {
        _tmpPageViewDic = [NSMutableDictionary dictionary];
        
    }
    return _tmpPageViewDic;
}

- (void)setOffsetX:(CGFloat)offsetX{
    _offsetX = self.contentOffset.x;
}

- (void)setRootScrollView:(UIScrollView *)rootScrollView{
    _rootScrollView = rootScrollView;
    rootScrollView.delegate = self;
    
    self.x = rootScrollView.x;
    self.y = rootScrollView.y - self.height;
}

- (void)setTitleNormalColor:(UIColor *)titleNormalColor{
    _titleNormalColor = titleNormalColor;
    [self.itemsDic enumerateKeysAndObjectsUsingBlock:^(id key, UIButton * button, BOOL *stop) {
         [button setTitleColor:titleNormalColor forState:UIControlStateNormal];
    }];

    RGBA rgba = RGBAFromUIColor(titleNormalColor);
    self.red1 = rgba.r;
    self.green1 = rgba.g;
    self.blue1 = rgba.b;
    self.alpha1 = rgba.a;
}

- (void)setTitleSelectedColor:(UIColor *)titleSelectedColor{
    _titleSelectedColor = titleSelectedColor;
    RGBA rgba = RGBAFromUIColor(titleSelectedColor);
    self.red2 = rgba.r;
    self.green2 = rgba.g;
    self.blue2 = rgba.b;
    self.alpha2 = rgba.a;
}

- (void)setIsGraduallyChangColor:(BOOL)isGraduallyChangColor{
    _isGraduallyChangColor = isGraduallyChangColor;
    if (!isGraduallyChangColor) {
        [self.itemsDic enumerateKeysAndObjectsUsingBlock:^(id key, UIButton *button, BOOL *stop) {
            [button setTitleColor:self.titleSelectedColor forState:UIControlStateSelected];
        }];
    }
}

- (void)setMinFontSize:(NSInteger)minFontSize{
    if (minFontSize > 0) {
        _minFontSize = minFontSize;
    }else{
        _minFontSize = FontMinSize;
    }
}

- (void)setMaxFontSize:(NSInteger)maxFontSize{
    if (maxFontSize > 0) {
        _maxFontSize = maxFontSize;
    }else{
        _maxFontSize = FontMinSize + FontDetLeSize;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)initNotificationCenter{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitles:) name:scrollNavBarUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveToSelectedItemAfterDelet:) name:moveToSelectedItem object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveToTopAfterDelet:) name:moveToTop object:nil];
}

- (void)removeNotificationCenter{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:scrollNavBarUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:moveToTop object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:moveToSelectedItem object:nil];
}

- (void)setup{
    self.isGraduallyChangColor = YES;
    self.isGraduallyChangFont = YES;
    self.userInteractionEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    [self initNotificationCenter];
}

- (void)setupItems{
    NSInteger itensCount = self.tmpKeys.count;
    for (NSInteger i = 0; i < itensCount; i++) {
        UIButton *button = [self createItemWithTitle:self.tmpKeys[i]];
        [self.itemsDic setObject:button forKey:self.tmpKeys[i]];
        button.tag = i;
        if (i == 0) {
            button.selected = YES;
            [button setTitleColor:self.titleSelectedColor forState:UIControlStateSelected];
            if (self.maxFontSize) {
                button.titleLabel.font = [UIFont systemFontOfSize:self.maxFontSize];
            }else{
                button.titleLabel.font = [UIFont systemFontOfSize:FontDetLeSize + FontMinSize];
            }
            _currectItem = button;
        }
    }
}

- (void)moveToTopAfterDelet:(NSNotification *)notificion{
    UIButton * button1 = [self getItemWithIndex:1];
    [self buttonClick:button1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.03 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIButton * button2 = [self getItemWithIndex:0];
        [self buttonClick:button2];
    });
}

- (void)moveToSelectedItemAfterDelet:(NSNotification *)notificion{
    UIButton * button = [self.itemsDic objectForKey:notificion.object];
    [self buttonClick:button];
}

- (void)updatePageView:(NSNotification *)notifition{
    if (notifition.object) {
        UIView *deletPageView = [self.tmpPageViewDic objectForKey:notifition.object];
        deletPageView.hidden = YES;
        //[self.pageViewDic removeObjectForKey:notifition.object];
    }
    int i = 0;
    self.rootScrollView.contentSize = CGSizeMake(self.tmpKeys.count * self.rootScrollView.width, 0);
    for (NSString *key in self.tmpKeys) {
        NSLog(@"key ---> %@  count ---> %ld",key,self.tmpKeys.count);
        UIView *pageView = [self.tmpPageViewDic objectForKey:key];
        CGFloat x = i * self.rootScrollView.width;
        CGFloat y = 0;
        CGFloat w = self.rootScrollView.width;
        CGFloat h = self.rootScrollView.height;
        pageView.frame = CGRectMake(x, y, w, h);
        //NSLog(@"%@",pageView);
        i++;
    }
}

- (void)updateTitles:(NSNotification *)notifition{
    [self updatePageView:notifition];
    [self layoutButtons];
}

//对item进行布局处理
- (void)layoutButtons{
    self.contentSize = CGSizeMake(self.tmpKeys.count * ItemWidth, 0);
    CGFloat buttonW = ItemWidth;
    NSInteger itemsCount = self.tmpKeys.count;
    if (itemsCount * ItemWidth < self.width) {
        CGFloat width = self.isShowSortButton ? (self.width - self.height) : self.width;
        buttonW = width / itemsCount;
    }
    CGFloat buttonH = self.height;
    CGFloat buttonY = self.isItemHiddenAfterDelet ? self.height : 0;
    
    for (NSInteger i = 0; i < itemsCount; i++) {
        if (i != itemsCount) {
            NSString *key = self.tmpKeys[i];
            UIButton *button = [self.itemsDic objectForKey:key];
            button.tag = i;
            CGFloat buttonX = i * buttonW;
            button.frame = CGRectMake(buttonX, buttonY, buttonW, buttonH);
            self.itemW = buttonW;
        }
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self layoutButtons];
}

- (void)buttonClick:(UIButton *)button{
    _oldItem = _currectItem;
    _currectItem.selected = NO;
    button.selected = YES;
    _currectItem = button;
    
    CGFloat offX = button.tag * self.rootScrollView.width;
    NSLog(@"off ---> %f",offX);
    [self buttonMoveAnimationWithIndex:button.tag];
    [self.rootScrollView setContentOffset:CGPointMake(offX, 0) animated:YES];
}

- (void)setSelectItemWithIndex:(NSInteger)index{
    _oldItem = _currectItem;
    _currectItem.selected = NO;
    UIButton *button = [self.itemsDic objectForKey:self.tmpKeys[index]];
    button.selected = YES;
    _currectItem = button;
    [self buttonMoveAnimationWithIndex:index];
}

- (void)buttonMoveAnimationWithIndex:(NSInteger)index{
    UIButton *selectButton = [self.itemsDic objectForKey:self.tmpKeys[index]];
    if (self.tmpKeys.count * self.itemW > self.width) {
        if (index < StaticItemIndex) {
            //x < 2 :前两个
            [self setContentOffset:CGPointMake(0, 0) animated:YES];
        }else if(index > self.tmpKeys.count - StaticItemIndex - 1) {
            // x >= 8 - 3 - 1;
            [self setContentOffset:CGPointMake(self.contentSize.width - self.width, 0) animated:YES];
        }else{
            [self setContentOffset:CGPointMake(selectButton.center.x - self.center.x, 0) animated:YES];
        }
    }else{
        [self setContentOffset:CGPointMake(0, 0) animated:YES];
    }
}

- (void)changeButtonFontWithOffset:(CGFloat)offset andWidth:(CGFloat)width{
    //self.firstButton.titleLabel.font = [UIFont systemFontOfSize:FontDefSize];
    //self.secButton.titleLabel.font = [UIFont systemFontOfSize:FontDefSize];
    
    [self.firstButton setTitleColor:self.titleNormalColor forState:UIControlStateNormal];
    [self.secButton setTitleColor:self.titleNormalColor forState:UIControlStateNormal];
    
    CGFloat p = fmod(offset, width) /width;
    NSInteger index = offset / width;
    self.currctIndex = index;
    if (self.isGraduallyChangFont) {
        self.firstButton = [self.itemsDic objectForKey:self.tmpKeys[index]];
        if(index + 1 < self.tmpKeys.count){
            self.secButton = [self.itemsDic objectForKey:self.tmpKeys[index + 1]];
        }else{
            self.secButton = nil;
        }

        CGFloat fontSize1;
        CGFloat fontSize2;
        if (self.maxFontSize) {
            fontSize1 = (1- p) * (self.maxFontSize - self.minFontSize) + self.minFontSize;
            fontSize2 = p * (self.maxFontSize - self.minFontSize) + self.minFontSize;
        }else{
            fontSize1 = (1- p) * FontDetLeSize + FontMinSize;
            fontSize2 = p * FontDetLeSize + FontMinSize;
        }
        self.firstButton.titleLabel.font = [UIFont systemFontOfSize:fontSize1];
        self.secButton.titleLabel.font = [UIFont systemFontOfSize:fontSize2];
    }
    
    if (self.isGraduallyChangColor) {
        CGFloat redTemp1 = ((self.red2 - self.red1) * (1-p)) + self.red1;
        CGFloat greenTemp1 = ((self.green2 - self.green1) * (1 - p)) + self.green1;
        CGFloat blueTemp1 = ((self.blue2 - self.blue1) * (1 - p)) + self.blue1;
        
        CGFloat redTemp2 = ((self.red2 - self.red1) * p) + self.red1;
        CGFloat greenTemp2 = ((self.green2 - self.green1) * p) + self.green1;
        CGFloat blueTemp2 = ((self.blue2 - self.blue1) * p) + self.blue1;
        
        [self.firstButton setTitleColor:[UIColor colorWithRed:redTemp1 green:greenTemp1 blue:blueTemp1 alpha:1] forState:UIControlStateNormal];
        [self.secButton setTitleColor:[UIColor colorWithRed:redTemp2 green:greenTemp2 blue:blueTemp2 alpha:1] forState:UIControlStateNormal];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self changeButtonFontWithOffset:scrollView.contentOffset.x andWidth:self.rootScrollView.width];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSInteger num = targetContentOffset->x / _rootScrollView.frame.size.width;
    [self setSelectItemWithIndex:num];
//    [[NSNotificationCenter defaultCenter] postNotificationName:HAScrollItemIndex object:[NSNumber numberWithInteger:num]];
}

- (void)hiddenAllItems{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupTmpPageViewDic];
    });
    for (int i = 0; i < self.tmpKeys.count; i++) {
        UIButton *button = [self getItemWithIndex:i];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                button.y = 2 * self.height;
            } completion:nil];
        });
    }
}

- (void)showAllItems{
    for (int i = 0; i < self.tmpKeys.count; i++) {
        UIButton *button = [self getItemWithIndex:i];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                button.y = 0;
            } completion:nil];
        });
    }
}

- (void)dealloc{
    [self removeNotificationCenter];
}
@end
