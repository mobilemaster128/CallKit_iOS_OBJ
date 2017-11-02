//
//  CallViewController.m
//  CallKit
//
//  Created by Dobrinka Tabakova on 9/26/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import "CallViewController.h"
#import "CallManager.h"
#import "CallKitButton.h"
#import "KeypadViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface CallViewController () <CallManagerDelegate, CallKitButtonDelegate, AVAudioPlayerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *callerLabel;
@property (weak, nonatomic) IBOutlet UIButton *holdButton;

@property (weak, nonatomic) IBOutlet CallKitButton *muteButton;
@property (weak, nonatomic) IBOutlet CallKitButton *speakerButton;
@property (weak, nonatomic) IBOutlet CallKitButton *keypadButton;
@property (weak, nonatomic) IBOutlet CallKitButton *showAppButton;
@property (weak, nonatomic) IBOutlet CallKitButton *endButton;

@property (nonatomic, strong) NSDateComponentsFormatter *timeFormatter;
@property (nonatomic, strong) NSTimer *callDurationTimer;

@property (nonatomic, assign) NSTimeInterval callDuration;
@property (nonatomic, assign) BOOL isOnHold;

@property (strong, nonatomic) AVAudioPlayer *player;

@end

@implementation CallViewController {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.callerLabel.text = self.phoneNumber;
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"callback"]]];
    
    [self.endButton setDelegate:self];
    [self.muteButton setDelegate:self];
    [self.keypadButton setDelegate:self];
    [self.showAppButton setDelegate:self];
    [self.speakerButton setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.phoneNumber) {
        [CallManager sharedInstance].delegate = self;
        if (self.isIncoming) {
            //[self performSelector:@selector(performCall) withObject:nil afterDelay:2.f];
            [self performSelector:@selector(performCall:) withObject:[NSNumber numberWithDouble:3.0]];
        } else {
            [[CallManager sharedInstance] startCallWithPhoneNumber:self.phoneNumber];
        }
    }
}

#pragma mark - Getters

- (NSDateComponentsFormatter*)timeFormatter {
    if (!_timeFormatter) {
        _timeFormatter = [[NSDateComponentsFormatter alloc] init];
        _timeFormatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
        _timeFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        _timeFormatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    }
    return _timeFormatter;
}

#pragma mark - Actions

- (IBAction)holdButtonTapped:(UIButton*)sender {
    self.isOnHold = !self.isOnHold;
    [self.holdButton setTitle:(self.isOnHold ? @"RESUME" : @"HOLD") forState:UIControlStateNormal];
    [[CallManager sharedInstance] holdCall:self.isOnHold];
}

#pragma mark - CallManagerDelegate

- (void)callDidAnswer {
    self.timeLabel.hidden = NO;
    self.holdButton.hidden = NO;
    self.endButton.hidden = NO;
    self.infoLabel.text = @"Active";
    [self startTimer];
    
    NSString *soundFilePath = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] pathForResource:@"Ringtone" ofType:@"aif"]];
    [self playSound:soundFilePath Loop:YES];
}

- (void)callDidEnd {
    [self.callDurationTimer invalidate];
    self.callDurationTimer = nil;
    self.holdButton.hidden = YES;
    self.endButton.hidden = YES;
    self.infoLabel.text = @"Ended";
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:1.f];
}

- (void)callDidHold:(BOOL)isOnHold {
    if (isOnHold) {
        [self.callDurationTimer invalidate];
        self.callDurationTimer = nil;
        [self.holdButton setTitle:@"RESUME" forState:UIControlStateNormal];
        self.infoLabel.text = @"On Hold";
    } else {
        [self startTimer];
        [self.holdButton setTitle:@"HOLD" forState:UIControlStateNormal];
        self.infoLabel.text = @"Active";
    }
}

- (void)callDidFail {
    [self.callDurationTimer invalidate];
    self.callDurationTimer = nil;
    self.infoLabel.text = @"Failed";
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:1.f];
}

#pragma mark - Utilities

- (void)performCall:(NSNumber*)delay {
    __weak CallViewController* weakSelf = self;
    dispatch_time_t delay_time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delay doubleValue] * NSEC_PER_SEC));
    UIBackgroundTaskIdentifier identifier = [UIApplication.sharedApplication beginBackgroundTaskWithExpirationHandler:nil];
    dispatch_after(delay_time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [UIApplication.sharedApplication endBackgroundTask:identifier];
        [[CallManager sharedInstance] reportIncomingCallForUUID:weakSelf.uuid phoneNumber:weakSelf.phoneNumber];
    });
}

- (IBAction)unwindForKeypad:(UIStoryboardSegue *)unwindSegue {
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startTimer {
    __weak CallViewController *weakSelf = self;
    self.callDurationTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        weakSelf.timeLabel.text = [weakSelf.timeFormatter stringFromTimeInterval:weakSelf.callDuration++];
    }];
}

- (void)playSound:(NSString*)filePath Loop:(BOOL)loop {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSURL* soundURL = [NSURL fileURLWithPath:filePath];
        
        NSError *error = nil;
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
        
        if (error) {
            NSLog(@"Error creating the audio player: %@", error);
        } else {
            if (loop == YES) {
                _player.numberOfLoops = -1;
            }
            _player.volume = [[AVAudioSession sharedInstance] outputVolume];
            //player.delegate = self;
            [_player prepareToPlay];
            [_player play];
        }
    } else {
        NSLog(@"No sound will be played. The file doesn't exist.");
    }
}

#pragma mark - CallKitButtonDelegate

- (void)callKitButton:(id)sender changedState:(ButtonState)state {
    if (sender == _endButton) {
        [[CallManager sharedInstance] endCall];
    } else if (sender == _keypadButton) {
        [self performSegueWithIdentifier:@"gotoKeyPad" sender:self];
        [_keypadButton setState:OFF];
    } else if (sender == _speakerButton) {
        // here is your speaker code
        NSLog(@"Speaker: %@", _speakerButton.state == ON ? @"ON" : @"OFF");
        
    } else if (sender == _showAppButton) {
        // here is your app code
        NSLog(@"Shop App");
        _showAppButton.state = OFF;        
    } else if (sender == _muteButton) {
        [[CallManager sharedInstance] mute:_muteButton.state == ON ? YES : NO];
    }
}

@end