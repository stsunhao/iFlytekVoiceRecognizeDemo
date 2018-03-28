//
//  UnderstandViewController.m
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import "UnderstandViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "IFlyMSC/IFlyMSC.h"
#import "Definition.h"
#import "IATConfig.h"
#import "PopupView.h"
@implementation UnderstandViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY, 0, 0) withParentView:self.view];
    
    _iFlySpeechUnderstander = [IFlySpeechUnderstander sharedInstance];
    _iFlySpeechUnderstander.delegate = self;
    
    _defaultText = @"北京到上海的火车";
    _textView.text = [NSString stringWithFormat:@"你可以输入:\n%@ \n明天下午3点提醒我4点开会\n牛顿第一定律\n1+101+524/(2+38)*85",self.defaultText];
    
    
    UIBarButtonItem *spaceBtnItem= [[ UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem * hideBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"隐藏" style:UIBarButtonItemStylePlain target:self action:@selector(onKeyBoardDown:)];
    [hideBtnItem setTintColor:[UIColor whiteColor]];
    UIToolbar * toolbar = [[ UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    NSArray * array = [NSArray arrayWithObjects:spaceBtnItem,hideBtnItem, nil];
    [toolbar setItems:array];
    _textView.inputAccessoryView = toolbar;
    
    _textView.layer.borderWidth = 0.5f;
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_textView.layer setCornerRadius:7.0f];
    

    
}

- (void)viewWillAppear:(BOOL)animated
{
    [_onlineRecBtn setEnabled:YES];
    [_cancelBtn setEnabled:YES];
    [_stopBtn setEnabled:YES];
    [_textUnderBtn setEnabled:YES];
    
    self.isSpeechUnderstander = NO;
    self.isTextUnderstander = NO;
    
    [super viewWillAppear:animated];
    [self initRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_iFlySpeechUnderstander cancel];
    [_iFlySpeechUnderstander setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button Handling

/**
 start text understanding
 **/
- (IBAction)textUnderBtnHandler:(id)sender {
    
    if (self.isSpeechUnderstander){
        return;
    }
    
    NSLog(@"%s",__func__);
    
    if(self.iFlyUnderStand == nil)
    {
        self.iFlyUnderStand = [[IFlyTextUnderstander alloc] init];
    }

    NSString * text;
    
    if ([_textView.text isEqualToString:@""]){
        text  = _defaultText;
    }else {
        text =_textView.text;
    }
    
    self.isTextUnderstander = YES;

    [self.iFlyUnderStand understandText:text withCompletionHandler:^(NSString* restult, IFlySpeechError* error)
     {
         NSLog(@"result is : %@",restult);
         _textView.text = restult;
         if (error!=nil && error.errorCode!=0) {
             
             NSString* errorText = [NSString stringWithFormat:@"Error：%d %@",error.errorCode,error.errorDesc];
             
             [self.popUpView setText: errorText];
             [self.view addSubview:self.popUpView];
         }
         
         self.isTextUnderstander = NO;
         
     }];
}


/**
 start speech understanding
 **/
- (IBAction)onlinRecBtnHandler:(id)sender {
    
    if (self.isTextUnderstander){
        return;
    }
    
    NSLog(@"%s",__func__);
    
    [_textView setText:@""];
    [_textView resignFirstResponder];
    
    [_iFlySpeechUnderstander setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
    
    bool ret = [_iFlySpeechUnderstander startListening];
    
    if (ret) {
        
        self.isSpeechUnderstander = YES;
        
        [_onlineRecBtn setEnabled:NO];
        [_cancelBtn setEnabled:YES];
        [_stopBtn setEnabled:YES];
        
        [_textUnderBtn setEnabled:NO];
        
        self.isCanceled = NO;
        
        
    }
    else
    {
        [_popUpView showText: NSLocalizedString(@"M_ISR_Fail", nil)];//Last session may be not over, recognition not supports concurrent multiplexing.
    }
}



/**
 stop recoreding
 **/
- (IBAction)stopBtnHandler:(id)sender {
    
    [_iFlySpeechUnderstander stopListening];

    [_textView resignFirstResponder];
}


/**
 cancel speech understanding
 **/
- (IBAction)cancelBtnHandler:(id)sender {
    self.isCanceled = YES;

    
    [_iFlySpeechUnderstander cancel];
    
    [_popUpView removeFromSuperview];
    [_textView resignFirstResponder];
}


/**
 clear text
 **/
- (IBAction)clearBtnHandler:(id)sender {
    
    
    _textView.text = @"";
}


- (IBAction)onSetting:(id)sender {
    
    if ([[self.navigationController topViewController] isKindOfClass:[UnderstandViewController class]]){
        [self performSegueWithIdentifier:@"NLPSegue" sender:self];
    }
    
}


/**
 hide keyboard
 **/
-(void)onKeyBoardDown:(id) sender
{
    [_textView resignFirstResponder];
}

#pragma mark - IFlySpeechRecognizerDelegate
/**
 volume callback,range from 0 to 30.
 **/
- (void) onVolumeChanged: (int)volume
{
    if (self.isCanceled) {
        [_popUpView removeFromSuperview];
        return;
    }
    
    NSString * vol = [NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"T_RecVol", nil),volume];
    [_popUpView showText: vol];
}


/**
 Beginning Of Speech
 **/
- (void) onBeginOfSpeech
{
    [_popUpView showText: NSLocalizedString(@"T_RecNow", nil)];
}

/**
 End Of Speech
 **/
- (void) onEndOfSpeech
{
    [_popUpView showText: NSLocalizedString(@"T_RecStop", nil)];
}


/**
 NLP completion, which will be invoked no matter whether it exits error.
 error.errorCode =
 0     success
 other fail
 **/
- (void) onError:(IFlySpeechError *) error
{
    NSLog(@"%s",__func__);
    
    NSString *text ;
    if (self.isCanceled) {
        text = NSLocalizedString(@"T_NLP_Cancel", nil);
    }
    else if (error.errorCode ==0 ) {
        if (_result.length==0) {
            text = NSLocalizedString(@"T_ISR_NoRlt", nil);
        }
        else
        {
            text = NSLocalizedString(@"T_ISR_Succ", nil);
        }
    }
    else
    {
        text = [NSString stringWithFormat:@"Error：%d %@",error.errorCode,error.errorDesc];
        NSLog(@"%@",text);
    }
    
    [_popUpView showText: text];
    
    self.isSpeechUnderstander = NO;
    
    [_textUnderBtn setEnabled:YES];
    [_onlineRecBtn setEnabled:YES];
}


/**
 result callback of recognition without view
 results：recognition results
 isLast：whether or not this is the last result
 **/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = results [0];
    
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
    }
    
    NSLog(@"ISR Results(json)：%@",result);
    
    _result = result;
    _textView.text = [NSString stringWithFormat:@"%@%@", _textView.text,result];
    [_textView scrollRangeToVisible:NSMakeRange([_textView.text length], 0)];
}




/**
 callback of canceling recognition
 **/
- (void) onCancel
{
    NSLog(@"NLP is cancelled");
}


/**
 initialize speech understanding conctol and set speech understanding params
 ****/
-(void)initRecognizer
{
    //speech understanding singleton
    if (_iFlySpeechUnderstander == nil) {
        _iFlySpeechUnderstander = [IFlySpeechUnderstander sharedInstance];
    }
    
    _iFlySpeechUnderstander.delegate = self;
    
    if (_iFlySpeechUnderstander != nil) {
        IATConfig *instance = [IATConfig sharedInstance];
        
        //Please refer to IATViewController.m for detail explanations.
        [_iFlySpeechUnderstander setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        [_iFlySpeechUnderstander setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        [_iFlySpeechUnderstander setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        [_iFlySpeechUnderstander setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        
        [_iFlySpeechUnderstander setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        [_iFlySpeechUnderstander setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        
        [_iFlySpeechUnderstander setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
    }
}

@end
