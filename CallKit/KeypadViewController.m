//
//  KeypadViewController.m
//  CallKit
//
//  Created by Mac on 11/2/17.
//  Copyright © 2017 Dobrinka Tabakova. All rights reserved.
//

#import "KeypadViewController.h"
#import "DTMFButton.h"
#import "CallManager.h"
#import "CallKitButton.h"

@interface KeypadViewController () <DTMFDelegate, CallKitButtonDelegate>

@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonOne;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonTwo;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonThree;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonFour;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonFive;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonSix;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonSeven;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonEight;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonNine;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonZero;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonSharp;
@property (weak, nonatomic) IBOutlet DTMFButton *buttonAsterisk;
@property (weak, nonatomic) IBOutlet CallKitButton *endButton;

@property (nonatomic, weak) CallManager *callManager;

@end

@implementation KeypadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"callback"]]];
    _callManager = [CallManager sharedInstance];
    
    _buttonOne.delegate = self;
    _buttonTwo.delegate = self;
    _buttonThree.delegate = self;
    _buttonFour.delegate = self;
    _buttonFive.delegate = self;
    _buttonSix.delegate = self;
    _buttonSeven.delegate = self;
    _buttonEight.delegate = self;
    _buttonNine.delegate = self;
    _buttonZero.delegate = self;
    _buttonAsterisk.delegate = self;
    _buttonSharp.delegate = self;
    _endButton.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - DTMFDelegate
- (void)didBeginDTMF:(id)sender digit:(NSString *)digit {
    _numberLabel.text = [_numberLabel.text stringByAppendingString:digit];
}

- (void)didEndDTMF:(id)sender digit:(NSString *)digit {
    [_callManager playDTMF:digit];
}

#pragma mark - CallKitButtonDelegate

- (void)callKitButton:(id)sender changedState:(ButtonState)state {
    if (sender == _endButton) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [_callManager endCall];
    }
}
@end
