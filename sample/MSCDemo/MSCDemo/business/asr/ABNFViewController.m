//
//  ABNFViewController.m
//  MSCDemo
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import "ABNFViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Definition.h"
#import "PopupView.h"
#import "ISRDataHelper.h"
#import "IATConfig.h"


#define GRAMMAR_TYPE_BNF     @"bnf"
#define GRAMMAR_TYPE_ABNF    @"abnf"


@implementation ABNFViewController

static NSString * _cloudGrammerid =nil;//grammerID for cloud grammar recognition


#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.isCanceled = NO;
    self.curResult = [[NSMutableString alloc]init];
    self.grammarType = GRAMMAR_TYPE_ABNF;
    
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY, 0, 0) withParentView:self.view];
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    _textView.layer.borderWidth = 0.5f;
    [_textView.layer setCornerRadius:7.0f];
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initRecognizer];
    _cloudGrammerid =nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_iFlySpeechRecognizer cancel];
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button handler

- (IBAction)starRecBtnHandler:(id)sender {
    
    self.textView.text = @"";
    
    //please upload grammar first before starting recognition
    if (![self isCommitted]) {
        
        [_popUpView showText: NSLocalizedString(@"M_ASR_UpGram", nil)];
        [self.view addSubview:_popUpView];
        
        return;
    }
    
    //Set the audio name of saved recording file while is generated in the local storage path of SDK,by default in library/cache.
    [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    //start grammar recognition
    BOOL ret = [_iFlySpeechRecognizer startListening];
    
    if (ret) {
        [_startRecBtn setEnabled:NO];
        [_uploadBtn setEnabled:NO];
        
        self.isCanceled = NO;
        [self.curResult setString:@""];
    }
    else{
        
        [_popUpView showText: NSLocalizedString(@"M_ISR_Fail", nil)];//Last session may be not over, recognition not supports concurrent multiplexing.
        [self.view addSubview:_popUpView];
    }

}


- (IBAction)stopBtnHandler:(id)sender {
    
    NSLog(@"%s",__func__);
    
    [_iFlySpeechRecognizer stopListening];
    [_textView resignFirstResponder];
}


- (IBAction)cancelBtnHandler:(id)sender {
    
    NSLog(@"%s",__func__);
    
    self.isCanceled = YES;
    [_iFlySpeechRecognizer cancel];
    [_textView resignFirstResponder];
}


- (IBAction)uploadBtnHandler:(id)sender {
    
    [_iFlySpeechRecognizer stopListening];
    [_uploadBtn setEnabled:NO];
    [_startRecBtn setEnabled:NO];
    [self showPopup];

    [self buildGrammer];    //build grammar
}

- (IBAction)onSetting:(id)sender {
    
    if ([[self.navigationController topViewController] isKindOfClass:[ABNFViewController class]]){
        [self performSegueWithIdentifier:@"ASRSegue" sender:self];
    }
    
}

/**
 Read file
 *****/
-(NSString *)readFile:(NSString *)filePath
{
    NSData *reader = [NSData dataWithContentsOfFile:filePath];
    return [[NSString alloc] initWithData:reader encoding:NSUTF8StringEncoding];
}



/**
 Build grammar
 ****/
-(void) buildGrammer
{
    NSString *grammarContent = nil;
    NSString *appPath = [[NSBundle mainBundle] resourcePath];
    
    //set text encoding mode
    [_iFlySpeechRecognizer setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    //set recognition domain
    [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    
    //read the cloud grammar file
    NSString *bnfFilePath = [[NSString alloc] initWithFormat:@"%@/bnf/grammar_sample.abnf",appPath];
    grammarContent = [self readFile:bnfFilePath];
    
    //upload grammar
    [_iFlySpeechRecognizer buildGrammarCompletionHandler:^(NSString * grammerID, IFlySpeechError *error){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (![error errorCode]) {
                
                NSLog(@"errorCode=%d",[error errorCode]);
               
                [_popUpView showText: NSLocalizedString(@"T_ISR_UpSucc", nil)];
                
                _textView.text = grammarContent;
            }
            else {
                [_popUpView showText: [NSString stringWithFormat:@"%@:%d", NSLocalizedString(@"T_ISR_UpFail", nil), error.errorCode]];
            }
            
            _cloudGrammerid = grammerID;
            
            //set grammarid 
            [_iFlySpeechRecognizer setParameter:_cloudGrammerid forKey:[IFlySpeechConstant CLOUD_GRAMMAR]];
            _uploadBtn.enabled = YES;
            _startRecBtn.enabled = YES;
        });
        
    }grammarType:self.grammarType grammarContent:grammarContent];
}


#pragma mark - IFlySpeechRecognizerDelegate

/**
 * volume callback,range from 0 to 30.
 **/
- (void) onVolumeChanged: (int)volume
{
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
 recognition session completion, which will be invoked no matter whether it exits error.
 error.errorCode =
 0     success
 other fail
 **/
- (void) onError:(IFlySpeechError *) error
{
    NSLog(@"error=%d",[error errorCode]);
    
    NSString *text ;
    
    if (self.isCanceled) {
        text = NSLocalizedString(@"T_ISR_Cancel", nil);
    }
    else if (error.errorCode ==0 ) {
        
        if (self.curResult.length==0 || [self.curResult hasPrefix:@"nomatch"]) {
            
            text = NSLocalizedString(@"T_ASR_NoMat", nil);
        }
        else
        {
            text = NSLocalizedString(@"T_ISR_Succ", nil);
            _textView.text = _curResult;
        }
    }
    else
    {
        text = [NSString stringWithFormat:@"Error：%d %@", error.errorCode,error.errorDesc];
        NSLog(@"%@",text);
    }
    
    [_popUpView showText: text];
    
    [_uploadBtn setEnabled:YES];
    [_startRecBtn setEnabled:YES];
}


/**
 result callback of recognition without view
 results：recognition results
 isLast：whether or not this is the last result
 **/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSMutableString * resultString = [[NSMutableString alloc]init];
    NSDictionary *dic = results[0];
    
    for (NSString *key in dic) {
        
        [result appendFormat:@"%@",key];
        
        NSString * resultFromJson =  [ISRDataHelper stringFromABNFJson:result];
        [resultString appendString:resultFromJson];
        
    }
    if (isLast) {
        
        NSLog(@"result is:%@",self.curResult);
    }
    
    [self.curResult appendString:resultString];

}

/**
 callback of canceling recognition
 **/
- (void) onCancel
{
    NSLog(@"Recognition is cancelled");
}


-(void)onKeyBoardDown:(id) sender
{
    [_textView resignFirstResponder];
}



-(void) showPopup
{
    [_popUpView showText: NSLocalizedString(@"T_ISR_Uping", nil)];

}

-(BOOL) isCommitted
{
    if (_cloudGrammerid == nil || _cloudGrammerid.length == 0) {
        return NO;
    }
    
    return YES;
}


#pragma mark - Initialization

/**
 initialize recognition conctol and set recognition params
 **/
-(void)initRecognizer
{

    //recognition singleton without view
    if (_iFlySpeechRecognizer == nil) {
        _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
    }
    _iFlySpeechRecognizer.delegate = self;
    
    if (_iFlySpeechRecognizer != nil) {
        IATConfig *instance = [IATConfig sharedInstance];
        
        //set recognition domain
        [_iFlySpeechRecognizer setParameter:@"asr" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        //Set result type
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //Please refer to IATViewController.m for detail explanations.
        [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        
        [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
    }
}



@end
