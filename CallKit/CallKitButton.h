//
//  CallKitButton.h
//  CallKit
//
//  Created by Mac on 11/1/17.
//  Copyright © 2017 Dobrinka Tabakova. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(int, ButtonState) {
    OFF,
    TOUCH,
    ON
};

@protocol CallKitButtonDelegate <NSObject>

//@optional
- (void)callKitButton:(id)sender changedState:(ButtonState)state;

@end

IB_DESIGNABLE
@interface CallKitButton : UIView

@property (nonatomic, assign) ButtonState state;
@property (nonatomic, weak) id<CallKitButtonDelegate> delegate;

- (void)setImage:(UIImage *)imageParam;

@end

