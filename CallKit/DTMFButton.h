//
//  DTMFButton.h
//  CallKit
//
//  Created by Mac on 11/2/17.
//  Copyright © 2017 Dobrinka Tabakova. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DTMFDelegate <NSObject>

//@optional
- (void)didBeginDTMF:(id)sender digit:(NSString*)digit;
- (void)didEndDTMF:(id)sender digit:(NSString*)digit;

@end

IB_DESIGNABLE
@interface DTMFButton : UIView

@property (nonatomic, copy) IBInspectable NSString* digit;
@property (nonatomic, weak) id<DTMFDelegate> delegate;

@end
