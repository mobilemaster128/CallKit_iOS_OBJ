//
//  CallKitButton.m
//  CallKit
//
//  Created by Mac on 11/1/17.
//  Copyright © 2017 Dobrinka Tabakova. All rights reserved.
//

#import "CallKitButton.h"

#define TEXT_PADDING 8
#define ICON_PADDING 16

#define UIColorFromRGB(colorRef) \
[UIColor colorWithRed:((float)((colorRef & 0x00FF0000) >> 16))/255.0 \
                green:((float)((colorRef & 0x0000FF00) >>  8))/255.0 \
                blue:((float)((colorRef & 0x000000FF) >>  0))/255.0 \
                alpha:((colorRef & 0xFF000000) >> 24)/255.0]
#define EndButtonColor UIColorFromRGB(0xFFFF2020)
#define EndTintColor UIColorFromRGB(0xFFBB2020)
#define TintColor UIColorFromRGB(0xCF000000)

@interface CallKitButton() {
    UIView* imageContainer;
    UIImageView* imageView;
    UILabel* label;
    
    BOOL initialized;
}

@property (nonatomic, copy) IBInspectable UIImage* image;
@property (nonatomic, copy) IBInspectable NSString* title;
@property (nonatomic, assign) IBInspectable BOOL endButton;
@property (nonatomic, copy) UIColor* buttonColor;
@property (nonatomic, copy) UIColor* tintColor;
@property (nonatomic, copy) UIColor* imageColor;
@property (nonatomic, copy) UIColor* borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, copy) UIColor* titleColor;
@property (nonatomic, assign) CGFloat fontSize;

@end

@implementation CallKitButton

@synthesize title;
@synthesize image;
@synthesize endButton;
@synthesize buttonColor;
@synthesize tintColor;
@synthesize imageColor;
@synthesize borderColor;
@synthesize borderWidth;
@synthesize titleColor;
@synthesize fontSize;
@synthesize state;
@synthesize delegate;

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit {
#if !TARGET_INTERFACE_BUILDER
    image = [[UIImage alloc] init];
    title = nil;
    endButton = NO;
#else
#endif
    
    buttonColor = UIColorFromRGB(0x60204842);
    tintColor = UIColorFromRGB(0x80FFFFFF);
    imageColor = UIColorFromRGB(0xFFFFFFFF);
    borderColor = UIColorFromRGB(0xE05CBBE9);
    borderWidth = 0;
    titleColor = UIColorFromRGB(0xFFFFFFFF);
    fontSize = 16;
    
    initialized = NO;
    state = OFF;
    
    [self initControl];
}

- (void) initImage:(UIImage*)imageParam {
    image = imageParam;
}

- (void)setTitle:(NSString *)titleParam {
    title = titleParam;
    [label setText:title];
}

- (void)setImage:(UIImage *)imageParam {
    image = [imageParam imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [imageView setImage:image];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self redrawFrame];
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    [self redrawFrame];
    [self redrawButton];
}

- (void)setState:(ButtonState)newState {
    state = newState;
    [self redrawButton];
}

- (void)initControl {
    
    imageContainer = [[UIView alloc] init];
    imageView = [[UIImageView alloc] init];
    label = [[UILabel alloc] init];
    [imageContainer addSubview:imageView];
    [self addSubview:imageContainer];
    [self addSubview:label];
    
    imageContainer.layer.borderWidth = borderWidth;
    imageContainer.clipsToBounds = YES;
    
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickButton:)];
    singleTap.numberOfTapsRequired = 1;
    [imageContainer setUserInteractionEnabled:YES];
    [imageContainer addGestureRecognizer:singleTap];
    
    [imageView setContentMode:(UIViewContentModeScaleAspectFit)];
    [imageView setImage:image];
    
    [label setText:title];
    [label setFont:[label.font fontWithSize:fontSize]];
    [label setTextAlignment:NSTextAlignmentCenter];
    
    initialized = YES;
}

- (void)redrawFrame {
    
    if (initialized) {
        CGFloat fontHeight = endButton ? 0 : label.font.lineHeight + TEXT_PADDING;
        CGFloat minLength = MIN(self.bounds.size.width, self.bounds.size.height - fontHeight);
        //[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, minLength, minLength + fontHeight)];
        
        //imageContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, minLength, minLength)];
        [imageContainer setFrame:CGRectMake(0, 0, minLength, minLength)];
        imageContainer.layer.cornerRadius = imageContainer.frame.size.width / 2;
        
        //imageView = [[UIImageView alloc] initWithFrame:CGRectMake(ICON_PADDING, ICON_PADDING, minLength - ICON_PADDING * 2, minLength - ICON_PADDING * 2)];
        [imageView setFrame:CGRectMake(ICON_PADDING, ICON_PADDING, minLength - ICON_PADDING * 2, minLength - ICON_PADDING * 2)];
        
        //label = [[UILabel alloc] initWithFrame:CGRectMake(0, minLength, minLength, fontHeight)];
        [label setFrame:CGRectMake(0, minLength, minLength, fontHeight)];
    }
}

- (void)redrawButton {
    [self setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:titleColor];
    [imageView setBackgroundColor:[UIColor clearColor]];
    if (state == ON) {
        [imageContainer setBackgroundColor:endButton ? EndButtonColor : imageColor];
        [imageView setTintColor:TintColor];
        imageContainer.layer.borderColor = endButton ? EndButtonColor.CGColor : imageColor.CGColor;
    } else {
        [imageContainer setBackgroundColor:endButton ? state == TOUCH ? EndTintColor : EndButtonColor : state == TOUCH ? tintColor : buttonColor];
        [imageView setTintColor:imageColor];
        imageContainer.layer.borderColor = endButton ? EndButtonColor.CGColor : borderColor.CGColor;
    }
}

- (void) clickButton:(UITapGestureRecognizer*)tap {
    state = (state == ON) || endButton ? OFF : ON;
    if ([delegate respondsToSelector:@selector(callKitButton:changedState:)]) {
        [delegate callKitButton:self changedState:state];
    }
    [self redrawButton];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch Began: %@", [touches anyObject]);
    if ([touches anyObject].view == imageContainer) {
        if (state == OFF) {
            state = TOUCH;
            [self redrawButton];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch Began: %@", [touches anyObject]);
    if ([touches anyObject].view == imageContainer) {
        if (state == TOUCH) {
            state = OFF;
            [self redrawButton];
        }
    }
}

@end
