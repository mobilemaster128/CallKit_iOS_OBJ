//
//  AudioSession.m
//  CallKit
//
//  Created by Mac on 11/6/17.
//  Copyright © 2017 Dobrinka Tabakova. All rights reserved.
//

#import "AudioSession.h"

#import <AVFoundation/AVFoundation.h>

@implementation AudioSession

+ (void)configureAudio {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    @try {
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [session setMode:AVAudioSessionModeVoiceChat error:nil];
    }
    @catch(NSException *exception) {
        NSLog(@"Error: %@", exception);
    }
}

+ (void)startAudio {
    
}

+ (void)stopAudio {
    
}

@end
