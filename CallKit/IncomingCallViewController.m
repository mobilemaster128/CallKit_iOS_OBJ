//
//  IncomingCallViewController.m
//  CallKit
//
//  Created by Dobrinka Tabakova on 9/26/16.
//  Copyright © 2016 Dobrinka Tabakova. All rights reserved.
//

#import "IncomingCallViewController.h"
#import "CallViewController.h"
#include "CallManager.h"


static NSString *const kTitle = @"Incoming Call";

@interface IncomingCallViewController ()

@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet UIButton *simulateCallButton;

@end


@implementation IncomingCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = kTitle;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[CallManager sharedInstance] isCalling]) {
        [_simulateCallButton setTitle:@"Show Call Screen" forState:UIControlStateNormal];
    } else {
        [_simulateCallButton setTitle:@"Simulate Call" forState:UIControlStateNormal];
    }
}

#pragma mark - Actions

- (IBAction)phoneNumberValueChanged:(UITextField*)sender {
    NSString *phoneNumber = [sender.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.simulateCallButton.enabled = (phoneNumber.length);
}

- (IBAction)clickSimulateBtn:(id)sender {
    [self performSegueWithIdentifier:@"gotoCall" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"gotoCall"]) {
        if (![[CallManager sharedInstance] isCalling]) {
            CallViewController* callViewController = [segue destinationViewController];
            callViewController.phoneNumber = self.phoneNumberTextField.text;
            callViewController.isIncoming = YES;
            callViewController.uuid = [NSUUID new];
        }
    }
}

@end

