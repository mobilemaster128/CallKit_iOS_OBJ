//
//  CallManager.m
//  CallKit
//
//  Created by Dobrinka Tabakova on 11/13/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import "CallManager.h"
#import <CallKit/CallKit.h>
#import <CallKit/CXError.h>
#import <UIKit/UIKit.h>

#define APP_NAME @"VoIPCall"

@interface CallContact() {
    
}
@end

@implementation CallContact

@synthesize uuid;
@synthesize phoneNumber;
@synthesize displayName;

- (id) initWithUUID:(NSUUID*)uuid {
    self = [super init];
    if (self) {
        self.uuid = uuid;
    }
    return self;
}

@end

@interface CallManager () <CXProviderDelegate>

@property (nonatomic, strong) CXProvider *provider;
@property (nonatomic, strong) CXCallController *callController;

@property (nonatomic, strong) CallContact *currentCall;

@end


@implementation CallManager

+ (CallManager*)sharedInstance {
    static CallManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CallManager alloc] init];
        [sharedInstance provider];
    });
    return sharedInstance;
}

- (void)reportIncomingCallForUUID:(NSUUID*)uuid phoneNumber:(NSString*)phoneNumber {
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:phoneNumber];
    __weak CallManager *weakSelf = self;
    update.supportsDTMF = YES;
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        if (!error) {
            weakSelf.currentCall = [[CallContact alloc] initWithUUID:uuid];
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(callDidFail)]) {
                [self.delegate callDidFail];
            }
        }
    }];
}

- (void)startCallWithPhoneNumber:(NSString*)phoneNumber {
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:phoneNumber];
    _currentCall = [[CallContact alloc] initWithUUID:[NSUUID new]];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:_currentCall.uuid handle:handle];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:startCallAction];
    [self requestTransaction:transaction];
}

- (void)mute:(BOOL)mute {
    CXSetMutedCallAction *action = [[CXSetMutedCallAction alloc] initWithCallUUID:_currentCall.uuid muted:mute];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:action];
    [self requestTransaction:transaction];
}

- (void)playDTMF:(NSString*)digits {
    CXPlayDTMFCallAction *action = [[CXPlayDTMFCallAction alloc] initWithCallUUID:_currentCall.uuid digits:digits type:CXPlayDTMFCallActionTypeSoftPause];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:action];
    [self requestTransaction:transaction];
}

- (void)endCall {
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:_currentCall.uuid];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:endCallAction];
    [self requestTransaction:transaction];
}

- (void)holdCall:(BOOL)hold {
    CXSetHeldCallAction *holdCallAction = [[CXSetHeldCallAction alloc] initWithCallUUID:_currentCall.uuid onHold:hold];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:holdCallAction];
    [self requestTransaction:transaction];
}

- (void)requestTransaction:(CXTransaction*)transaction {
    [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            if (self.delegate && [self.delegate respondsToSelector:@selector(callDidFail)]) {
                [self.delegate callDidFail];
            }
        }
    }];
}

#pragma mark - Getters

static const NSInteger DefaultMaximumCallsPerCallGroup = 1;
static const NSInteger DefaultMaximumCallGroups = 1;
static const BOOL DefaultSupportVideo = NO;
static NSString* const DefaultRingtoneSound = @"Ringtone.aif";
static NSString* const DefaultIconMask = @"mask_icon";

- (CXProvider*)provider {
    if (!_provider) {
        CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:APP_NAME];
        configuration.supportsVideo = DefaultSupportVideo;
        configuration.maximumCallsPerCallGroup = DefaultMaximumCallsPerCallGroup;
        configuration.maximumCallGroups = DefaultMaximumCallGroups;
        configuration.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypePhoneNumber)]; //[NSSet setWithObjects:@(CXHandleTypePhoneNumber), @(CXHandleTypeEmailAddress), @(CXHandleTypeGeneric)];
        
        UIImage* iconMaskImage = [UIImage imageNamed:DefaultIconMask];
        if (iconMaskImage) {
            configuration.iconTemplateImageData = UIImagePNGRepresentation(iconMaskImage);
        }
        
        configuration.ringtoneSound = DefaultRingtoneSound;
        
        _provider = [[CXProvider alloc] initWithConfiguration:configuration];
        [_provider setDelegate:self queue:nil];
    }
    return _provider;
}

- (CXCallController*)callController {
    if (!_callController) {
        _callController = [[CXCallController alloc] init];
    }
    return _callController;
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider {
}

/// Called when the provider has been fully created and is ready to send actions and receive updates
- (void)providerDidBegin:(CXProvider *)provider {
}

// If provider:executeTransaction:error: returned NO, each perform*CallAction method is called sequentially for each action in the transaction
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    //todo: configure audio session
    //todo: start network call
    [self.provider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:nil];
    [self.provider reportOutgoingCallWithUUID:action.callUUID connectedAtDate:nil];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidAnswer)]) {
        [self.delegate callDidAnswer];
    }
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    //todo: configure audio session
    //todo: answer network call
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidAnswer)]) {
        [self.delegate callDidAnswer];
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    //todo: stop audio
    //todo: end network call
    self.currentCall = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidEnd)]) {
        [self.delegate callDidEnd];
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
    if (action.isOnHold) {
        //todo: stop audio
    } else {
        //todo: start audio
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidHold:)]) {
        [self.delegate callDidHold:action.isOnHold];
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    NSLog(@"Mute: %d", action.muted);
    
    // here is your mute code
    
    [action fulfill];
}


- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
    NSLog(@"Play DTMF: %@", action.digits);
    
    // here is your DTMF code
    
    [action fulfill];
}

/// Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    // React to the action timeout if necessary, such as showing an error UI.
}

/// Called when the provider's audio session activation state changes.
- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    //todo: start audio
    // Start call audio media, now that the audio session has been activated after having its priority boosted.
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    /*
     Restart any non-call related audio now that the app's audio session has been
     de-activated after having its priority restored to normal.
     */
}

@end

