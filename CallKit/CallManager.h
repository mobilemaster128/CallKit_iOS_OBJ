//
//  CallManager.h
//  CallKit
//
//  Created by Dobrinka Tabakova on 11/13/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CallContact : NSObject

@property (nonatomic, copy) NSUUID* uuid;
@property (nonatomic, copy) NSString* phoneNumber;
@property (nonatomic, copy) NSString* displayName;
@property (nonatomic, copy) NSString* handle;
@property (nonatomic, assign) BOOL isOutgoing;

@end


@protocol CallManagerDelegate <NSObject>

- (void)callDidAnswer;
- (void)callDidEnd;
- (void)callDidHold:(BOOL)isOnHold;
- (void)callDidFail;

@end

@interface CallManager : NSObject

+ (CallManager*)sharedInstance;
- (void)reportIncomingCallForUUID:(NSUUID*)uuid phoneNumber:(NSString*)phoneNumber;
- (void)startCallWithPhoneNumber:(NSString*)phoneNumber;
- (BOOL)isCalling;
- (void)mute:(BOOL)mute;
- (void)playDTMF:(NSString*)digits;
- (void)endCall;
- (void)holdCall:(BOOL)hold;

@property (nonatomic, weak) id<CallManagerDelegate> delegate;

@end
