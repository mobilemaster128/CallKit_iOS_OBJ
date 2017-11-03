//
//  DTMFButton.m
//  CallKit
//
//  Created by Mac on 11/2/17.
//  Copyright © 2017 Dobrinka Tabakova. All rights reserved.
//

#import "DTMFButton.h"
#import "TGSineWaveToneGenerator.h"

#define UIColorFromRGB(colorRef) \
                    [UIColor colorWithRed:((float)((colorRef & 0x00FF0000) >> 16))/255.0 \
                    green:((float)((colorRef & 0x0000FF00) >>  8))/255.0 \
                    blue:((float)((colorRef & 0x000000FF) >>  0))/255.0 \
                    alpha:((colorRef & 0xFF000000) >> 24)/255.0]

#define SUB_PADDING 8

#define MAX_TIME 1.5

@interface DTMFButton() {
    
    UIView* container;
    UILabel* digitLabel;
    UILabel* subLabel;
    
    BOOL initialized;
}

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, copy) UIColor* borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, copy) UIColor* textColor;
@property (nonatomic, assign) CGFloat digitSize;
@property (nonatomic, assign) CGFloat subSize;
@property (nonatomic, copy) UIColor* tintColor;
@property (nonatomic, copy) UIColor* buttonColor;
@property (nonatomic, copy) TGSineWaveToneGenerator *generator;

@end

@implementation DTMFButton

@synthesize digit;
@synthesize isPlaying;
@synthesize borderColor;
@synthesize borderWidth;
@synthesize textColor;
@synthesize digitSize;
@synthesize subSize;
@synthesize tintColor;
@synthesize buttonColor;
@synthesize delegate;
@synthesize generator;

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
    digit = @"2";
#else
#endif
    
    isPlaying = NO;
    borderColor = UIColorFromRGB(0xB02B6D64);
    borderWidth = 1;
    textColor = UIColorFromRGB(0xFFFFFFFF);
    tintColor = UIColorFromRGB(0x80FFFFFF);
    buttonColor = UIColorFromRGB(0x60204842);
    digitSize = 36;
    subSize = 14;
    
    generator = [[TGSineWaveToneGenerator alloc] initWithChannels:2];
    
    initialized = NO;
    
    [self initControl];
}

- (void) setDigit:(NSString *)digitParam {
    digit = [digitParam substringToIndex:1];
    
    [self generateDTMF:digit];
    
    [self setNeedsLayout];
}

- (void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self redrawFrame];
}

- (void) initControl {
    //[self generateDTMF:digit];
    
    container = [[UIView alloc] init];
    digitLabel = [[UILabel alloc] init];
    subLabel = [[UILabel alloc] init];
    [container addSubview:digitLabel];
    [container addSubview:subLabel];
    [self addSubview:container];
    
    self.backgroundColor = [UIColor clearColor];
    
    container.clipsToBounds = YES;
    container.backgroundColor = [UIColor clearColor];
    container.layer.borderWidth = borderWidth;
    container.layer.borderColor = borderColor.CGColor;
    
    [container setUserInteractionEnabled:YES];
    
    digitLabel.textAlignment = NSTextAlignmentCenter;
    digitLabel.backgroundColor = [UIColor clearColor];
    [digitLabel setFont:[digitLabel.font fontWithSize:digitSize]];
    
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.backgroundColor = [UIColor clearColor];
    subLabel.font = [digitLabel.font fontWithSize:subSize];
    
    initialized = YES;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    [self redrawFrame];
    [self redrawButton];
}

- (void) redrawFrame {
    if (initialized) {
        digitLabel.text = digit;
        NSDictionary* const subStrings = @{@"1" : @"",
                                           @"2" : @"ABC",
                                           @"3" : @"DEF",
                                           @"4" : @"GHI",
                                           @"5" : @"JKL",
                                           @"6" : @"MNO",
                                           @"7" : @"PQRS",
                                           @"8" : @"TUV",
                                           @"9" : @"WXYZ",
                                           @"0" : @"+",
                                           @"*" : @"",
                                           @"#" : @""};
        subLabel.text = [subStrings objectForKey:digit];
        
        CGFloat digitHeight = digitLabel.font.lineHeight;
        CGFloat subHeight = [digit isEqualToString:@"*"] || [digit isEqualToString:@"#"] ? 0 : subLabel.font.lineHeight;
        CGFloat totalHeight = digitHeight + subHeight;// + SUB_PADDING;
        
        CGFloat length = MIN(self.bounds.size.width, self.bounds.size.height);
        
        container.frame = CGRectMake(0, 0, length, length);
        container.layer.cornerRadius = length / 2;
        
        [digitLabel setFrame:CGRectMake(0, (length - totalHeight) / 2, length, digitHeight)];
        [subLabel setFrame:CGRectMake(0, (length + subHeight + SUB_PADDING) / 2, length, subHeight)];
    }
}

- (void) redrawButton {
    self.backgroundColor = [UIColor clearColor];
    digitLabel.textColor = textColor;
    subLabel.textColor = textColor;
    
    if (isPlaying) {
        container.backgroundColor = tintColor;
    } else {
        container.backgroundColor = buttonColor;
    }
}

- (void) generateDTMF:(NSString*)digit {
    unichar c = [digit characterAtIndex:0];
    
    // DTMF keypad frequencies
    double freqA[] = {1209, 1336, 1477};
    double freqB[] = {697, 770, 852};
    if (c == '0') {
        generator->_channels[0].frequency = 1336;
        generator->_channels[1].frequency = 941;
    } else if ('0' < c && c <= '9') {
        c = c -'1';
        generator->_channels[0].frequency = freqA[c % 3];
        generator->_channels[1].frequency = freqB[c / 3];
    } else if (c == '#') {
        generator->_channels[0].frequency = 1477;
        generator->_channels[1].frequency = 941;
    } else {// Not sure
        generator->_channels[0].frequency = 1209;
        generator->_channels[1].frequency = 941;
    }
}

- (void) startPlayDTMF:(NSString*)digit {
    [self changeState:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [generator play];
    });
    [self performSelector:@selector(endPlayDTMF) withObject:nil afterDelay:MAX_TIME];
}

- (void) endPlayDTMF {
    if (isPlaying) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [generator stop];
        });
        [self changeState:NO];
        if ([delegate respondsToSelector:@selector(didEndDTMF:digit:)]) {
            [delegate didEndDTMF:self digit:digit];
        }
    }
}

- (void) changeState:(BOOL)state {
    isPlaying = state;
    [self redrawButton];
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([touches anyObject].view == container) {
        if ([delegate respondsToSelector:@selector(didBeginDTMF:digit:)]) {
            [delegate didBeginDTMF:self digit:digit];
        }
        [self startPlayDTMF:digit];
    }
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([touches anyObject].view == container) {
        [self performSelector:@selector(endPlayDTMF) withObject:nil afterDelay:0.1];
    }
}

@end
