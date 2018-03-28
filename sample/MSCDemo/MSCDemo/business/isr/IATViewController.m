//
//  IATViewController.h
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-28.
//
//

#import "IATViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Definition.h"
#import "PopupView.h"
#import "ISRDataHelper.h"
#import "IATConfigViewController.h"
#import "IATConfig.h"


#define NAME        @"userwords"
#define USERWORDS   @"{\"userword\":[{\"name\":\"我的常用词\",\"words\":[\"佳晨实业\",\"蜀南庭苑\",\"高兰路\",\"复联二\"]},{\"name\":\"我的好友\",\"words\":[\"李馨琪\",\"鹿晓雷\",\"张集栋\",\"周家莉\",\"叶震珂\",\"熊泽萌\"]}]}"



@implementation IATViewController

- (void)listSubviewsOfView:(UIView *)view {
    NSArray *subviews = [view subviews];
    if ([subviews count] == 0) return;
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel*)subview;
            if ([label.text containsString:@"语音识别"]) {
                label.hidden = YES;
                break;
            }
        }
        [self listSubviewsOfView:subview];
    }
}

#pragma mark - View lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _textView.layer.borderWidth = 0.5f;
    _textView.layer.borderColor = [[UIColor whiteColor] CGColor];
    [_textView.layer setCornerRadius:7.0f];
    
    CGFloat posY = self.textView.frame.origin.y+self.textView.frame.size.height/6;
    _popUpView = [[PopupView alloc] initWithFrame:CGRectMake(100, posY, 0, 0) withParentView:self.view];

    self.uploader = [[IFlyDataUploader alloc] init];
    
    [self setExclusiveTouchForButtons:self.view];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s",__func__);
    
    [super viewWillAppear:animated];
    
    [self initRecognizer];
    
    [_startRecBtn setEnabled:YES];
    [_audioStreamBtn setEnabled:YES];
    [_upWordListBtn setEnabled:YES];
    [_upContactBtn setEnabled:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.view = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO) {
        
        [_iFlySpeechRecognizer cancel];
        [_iFlySpeechRecognizer setDelegate:nil];
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        
        [_pcmRecorder stop];
        _pcmRecorder.delegate = nil;
    }
    else
    {
        [_iflyRecognizerView cancel];
        [_iflyRecognizerView setDelegate:nil];
        [_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    }
    
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Button Handling

/**
 start speech recognition
 **/
- (IBAction)startBtnHandler:(id)sender {
    
    NSLog(@"%s[IN]",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO) {
      
        [_textView setText:@""];
        [_textView resignFirstResponder];
        self.isCanceled = NO;
        self.isStreamRec = NO;
        
        if(_iFlySpeechRecognizer == nil)
        {
            [self initRecognizer];
        }
        
        [_iFlySpeechRecognizer cancel];
        
        //Set microphone as audio source
        [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //Set result type
        [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //Set the audio name of saved recording file while is generated in the local storage path of SDK,by default in library/cache.
        [_iFlySpeechRecognizer setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        [_iFlySpeechRecognizer setDelegate:self];
        
        BOOL ret = [_iFlySpeechRecognizer startListening];
        
        if (ret) {
            [_audioStreamBtn setEnabled:NO];
            [_upWordListBtn setEnabled:NO];
            [_upContactBtn setEnabled:NO];
            
        }else{
            [_popUpView showText: NSLocalizedString(@"M_ISR_Fail", nil)];//Last session may be not over, recognition not supports concurrent multiplexing.
        }
    }else {
        
        if(_iflyRecognizerView == nil)
        {
            [self initRecognizer ];
        }

        [_textView setText:@""];
        [_textView resignFirstResponder];
        
        //Set microphone as audio source
        [_iflyRecognizerView setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];

        //Set result type
        [_iflyRecognizerView setParameter:@"plain" forKey:[IFlySpeechConstant RESULT_TYPE]];
        
        //Set the audio name of saved recording file while is generated in the local storage path of SDK,by default in library/cache.
        [_iflyRecognizerView setParameter:@"asr.pcm" forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
        
        BOOL ret = [_iflyRecognizerView start];
        if (ret) {
            [_startRecBtn setEnabled:NO];
            [_audioStreamBtn setEnabled:NO];
            [_upWordListBtn setEnabled:NO];
            [_upContactBtn setEnabled:NO];
        }
    }

}

/**
 stop recording
 **/
- (IBAction)stopBtnHandler:(id)sender {
    
    NSLog(@"%s",__func__);
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }
    
    [_iFlySpeechRecognizer stopListening];
    [_textView resignFirstResponder];
}

/**
 cancel speech recognition
 **/
- (IBAction)cancelBtnHandler:(id)sender {
    
    NSLog(@"%s",__func__);
    
    if(self.isStreamRec && !self.isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }
    
    self.isCanceled = YES;

    [_iFlySpeechRecognizer cancel];
    
    [_popUpView removeFromSuperview];
    [_textView resignFirstResponder];
    
}




/**
 upload contacts
 **/
- (IBAction)upContactBtnHandler:(id)sender {
    //Ensure that the recognition session is over
    [_iFlySpeechRecognizer stopListening];
    
    [_startRecBtn setEnabled:NO];
    [_audioStreamBtn setEnabled:NO];
    _upContactBtn.enabled = NO;
    _upWordListBtn.enabled = NO;
    
    [self showPopup];
    
    //acquire contact list
    IFlyContact *iFlyContact = [[IFlyContact alloc] init];
    NSString *contact = [iFlyContact contact];
    
    _textView.text = contact;
    
    [_uploader setParameter:@"uup" forKey:[IFlySpeechConstant SUBJECT]];
    [_uploader setParameter:@"contact" forKey:[IFlySpeechConstant DATA_TYPE]];
    [_uploader uploadDataWithCompletionHandler:
     ^(NSString * grammerID, IFlySpeechError *error)
    {
         [self onUploadFinished:error];
    } name:@"contact" data: _textView.text];
}


/**
 upload customized words
 **/
- (IBAction)upWordBtnHandler:(id)sender {
    
    [_iFlySpeechRecognizer stopListening];
    
    [_startRecBtn setEnabled:NO];
    [_audioStreamBtn setEnabled:NO];
    _upContactBtn.enabled = NO;
    _upWordListBtn.enabled = NO;
    
    [_uploader setParameter:@"uup" forKey:[IFlySpeechConstant SUBJECT]];
    [_uploader setParameter:@"userword" forKey:[IFlySpeechConstant DATA_TYPE]];
    
    [self showPopup];
    
    IFlyUserWords *iFlyUserWords = [[IFlyUserWords alloc] initWithJson:USERWORDS ];
    
    [_uploader uploadDataWithCompletionHandler:
     ^(NSString * grammerID, IFlySpeechError *error)
    {
        if (error.errorCode == 0) {
            _textView.text = @"佳晨实业\n蜀南庭苑\n高兰路\n复联二\n李馨琪\n鹿晓雷\n张集栋\n周家莉\n叶震珂\n熊泽萌\n";
        }
        [self onUploadFinished:error];
    } name:NAME data:[iFlyUserWords toString]];
   
}

/**
 start audio stream recognition
 **/
- (IBAction)audioStreamBtnHandler:(id)sender {
    
    NSLog(@"%s[IN]",__func__);
    
    [_textView setText:@""];
    [_textView resignFirstResponder];
    
    self.isStreamRec = YES;
    self.isBeginOfSpeech = NO;
    
    if ([IATConfig sharedInstance].haveView == YES) {
        [_popUpView showText: NSLocalizedString(@"M_ISR_Stream_Fail", nil)];
        return;
    }
    
    if(_iFlySpeechRecognizer == nil)
    {
        [self initRecognizer];
    }
    
    [_startRecBtn setEnabled:NO];
    [_audioStreamBtn setEnabled:NO];
    [_upWordListBtn setEnabled:NO];
    [_upContactBtn setEnabled:NO];
    
    [_iFlySpeechRecognizer setDelegate:self];
    [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
    [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_STREAM forKey:@"audio_source"];    //Set audio stream as audio source,which requires the developer import audio data into the recognition control by self through "writeAudio:".
    BOOL ret  = [_iFlySpeechRecognizer startListening];
    
    
    if (ret) {
        self.isCanceled = NO;
        //set the category of AVAudioSession
        [IFlyAudioSession initRecordingAudioSession];
        
        _pcmRecorder.delegate = self;
        
        //start recording
        BOOL ret = [_pcmRecorder start];
        
        [_popUpView showText: NSLocalizedString(@"T_RecNow", nil)];

        NSLog(@"%s[OUT],Success,Recorder ret=%d",__func__,ret);
    }
    else
    {
        [_startRecBtn setEnabled:YES];
        [_audioStreamBtn setEnabled:YES];
        [_upWordListBtn setEnabled:YES];
        [_upContactBtn setEnabled:YES];
        [_popUpView showText: NSLocalizedString(@"M_ISR_Fail", nil)];
        NSLog(@"%s[OUT],Failed",__func__);
    }
}

- (IBAction)onSetting:(id)sender {

    if ([[self.navigationController topViewController] isKindOfClass:[IATViewController class]]){
        [self performSegueWithIdentifier:@"ISRSegue" sender:self];
    }
    
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
    NSLog(@"onBeginOfSpeech");
    
    if (self.isStreamRec == NO)
    {
        self.isBeginOfSpeech = YES;
        [_popUpView showText: NSLocalizedString(@"T_RecNow", nil)];
    }
}

/**
 End Of Speech
 **/
- (void) onEndOfSpeech
{
    NSLog(@"onEndOfSpeech");
    
    [_pcmRecorder stop];
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
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO ) {
        
        NSString *text ;
        
        if (self.isCanceled) {
            text = NSLocalizedString(@"T_ISR_Cancel", nil);
            
        } else if (error.errorCode == 0 ) {
            if (_result.length == 0) {
                text = NSLocalizedString(@"T_ISR_NoRlt", nil);
            }else {
                text = NSLocalizedString(@"T_ISR_Succ", nil);
                //empty results
                _result = nil;
            }
        }else {
            text = [NSString stringWithFormat:@"Error：%d %@", error.errorCode,error.errorDesc];
            NSLog(@"%@",text);
        }
        
        [_popUpView showText: text];
 
    }else {
        [_popUpView showText: NSLocalizedString(@"T_ISR_Succ", nil)];
        NSLog(@"errorCode:%d",[error errorCode]);
    }
    
    [_startRecBtn setEnabled:YES];
    [_audioStreamBtn setEnabled:YES];
    [_upWordListBtn setEnabled:YES];
    [_upContactBtn setEnabled:YES];
    
}

/**
 result callback of recognition without view
 results：recognition results
 isLast：whether or not this is the last result
 **/
- (void) onResults:(NSArray *) results isLast:(BOOL)isLast
{
    NSMutableString *resultString = [[NSMutableString alloc] init];
    NSDictionary *dic = results[0];
    
    for (NSString *key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    
    _result =[NSString stringWithFormat:@"%@%@", _textView.text,resultString];
    NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
    _textView.text = [NSString stringWithFormat:@"%@%@", _textView.text,resultFromJson];
    
    if (isLast){
        NSLog(@"ISR Results(json)：%@",  self.result);
    }
    NSLog(@"_result=%@",_result);
    NSLog(@"resultFromJson=%@",resultFromJson);
    NSLog(@"isLast=%d,_textView.text=%@",isLast,_textView.text);
}



/**
 result callback of recognition with view
 resultArray：recognition results
 isLast：whether or not this is the last result
 **/
- (void)onResult:(NSArray *)resultArray isLast:(BOOL)isLast
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSDictionary *dic = [resultArray objectAtIndex:0];
    
    for (NSString *key in dic) {
        [result appendFormat:@"%@",key];
    }
    _textView.text = [NSString stringWithFormat:@"%@%@",_textView.text,result];
}



/**
 callback of canceling recognition
 **/
- (void) onCancel
{
    NSLog(@"Recognition is cancelled");
}

-(void) showPopup
{
    [_popUpView showText: NSLocalizedString(@"T_ISR_Uping", nil)];
}

#pragma mark - IFlyDataUploaderDelegate

/**
 result callback of uploading contacts or customized words
 **/
- (void) onUploadFinished:(IFlySpeechError *)error
{
    NSLog(@"%d",[error errorCode]);
    
    if ([error errorCode] == 0) {
        [_popUpView showText: NSLocalizedString(@"T_ISR_UpSucc", nil)];
    }
    else {
        [_popUpView showText: [NSString stringWithFormat:@"%@:%d", NSLocalizedString(@"T_ISR_UpFail", nil), error.errorCode]];
        
    }
    
    [_startRecBtn setEnabled:YES];
    [_audioStreamBtn setEnabled:YES];
    _upWordListBtn.enabled = YES;
    _upContactBtn.enabled = YES;
}


#pragma mark - Initialization

/**
 initialize recognition conctol and set recognition params
 **/
-(void)initRecognizer
{
    NSLog(@"%s",__func__);
    
    if ([IATConfig sharedInstance].haveView == NO) {
        
        //recognition singleton without view
        if (_iFlySpeechRecognizer == nil) {
            _iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
		}
            
        [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
//
//        //set recognition domain
        [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        
        _iFlySpeechRecognizer.delegate = self;
        
        if (_iFlySpeechRecognizer != nil) {
            IATConfig *instance = [IATConfig sharedInstance];
            
            //set timeout of recording
            [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            //set VAD timeout of end of speech(EOS)
            [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            //set VAD timeout of beginning of speech(BOS)
            [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            //set network timeout
            [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
            
            //set sample rate, 16K as a recommended option
            [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
            
            //set language
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            //set accent
            [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            
            //set whether or not to show punctuation in recognition results
            [_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
            
        }
        
        //Initialize recorder
        if (_pcmRecorder == nil)
        {
            _pcmRecorder = [IFlyPcmRecorder sharedInstance];
        }

        _pcmRecorder.delegate = self;

        [_pcmRecorder setSample:[IATConfig sharedInstance].sampleRate];

        [_pcmRecorder setSaveAudioPath:nil];    //not save the audio file
        
    }else  {

        //recognition singleton with view
        if (_iflyRecognizerView == nil) {
            
            _iflyRecognizerView= [[IFlyRecognizerView alloc] initWithCenter:self.view.center];
		}
//        [self clearMemo];
        [self listSubviewsOfView:_iflyRecognizerView];
        [_iflyRecognizerView setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
            
        //set recognition domain
        [_iflyRecognizerView setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];

        
        _iflyRecognizerView.delegate = self;
        
        if (_iflyRecognizerView != nil) {
            IATConfig *instance = [IATConfig sharedInstance];
            //set timeout of recording
            [_iflyRecognizerView setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
            //set VAD timeout of end of speech(EOS)
            [_iflyRecognizerView setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
            //set VAD timeout of beginning of speech(BOS)
            [_iflyRecognizerView setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
            //set network timeout
            [_iflyRecognizerView setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
            
            //set sample rate, 16K as a recommended option
            [_iflyRecognizerView setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
			
            //set language
            [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            //set accent
            [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
            //set whether or not to show punctuation in recognition results
            [_iflyRecognizerView setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
            
        }
    }
}




-(void)setExclusiveTouchForButtons:(UIView *)myView
{
    for (UIView * button in [myView subviews]) {
        if([button isKindOfClass:[UIButton class]])
        {
            [((UIButton *)button) setExclusiveTouch:YES];
        }
        else if ([button isKindOfClass:[UIView class]])
        {
            [self setExclusiveTouchForButtons:button];
        }
    }
}


#pragma mark - IFlyPcmRecorderDelegate

- (void) onIFlyRecorderBuffer: (const void *)buffer bufferSize:(int)size
{
    NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
    
    int ret = [self.iFlySpeechRecognizer writeAudio:audioBuffer];
    if (!ret)
    {
        [self.iFlySpeechRecognizer stopListening];
        
        [_startRecBtn setEnabled:YES];
        [_audioStreamBtn setEnabled:YES];
        [_upWordListBtn setEnabled:YES];
        [_upContactBtn setEnabled:YES];

    }
}

- (void) onIFlyRecorderError:(IFlyPcmRecorder*)recoder theError:(int) error
{
    
}

//range from 0 to 30
- (void) onIFlyRecorderVolumeChanged:(int) power
{
//    NSLog(@"%s,power=%d",__func__,power);
    
    if (self.isCanceled) {
        [_popUpView removeFromSuperview];
        return;
    }
    
    NSString * vol = [NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"T_RecVol", nil),power];
    [_popUpView showText: vol];
}

@end
