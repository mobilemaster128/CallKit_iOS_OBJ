//
//  AudioSession.h
//  CallKit
//
//  Created by Mac on 11/6/17.
//  Copyright © 2017 Dobrinka Tabakova. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioSession : NSObject

+ (void)configureAudio;
+ (void)startAudio;
+ (void)stopAudio;

@end
