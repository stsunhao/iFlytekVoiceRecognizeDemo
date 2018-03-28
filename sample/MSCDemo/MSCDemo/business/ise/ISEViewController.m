//
//  ISEViewController.m
//  MSCDemo_UI
//
//  Created by 张剑 on 15/1/15.
//
//

#import "ISEViewController.h"
#import "ISESettingViewController.h"
#import "PopupView.h"
#import "ISEParams.h"
#import "IFlyMSC/IFlyMSC.h"

#import "ISEResult.h"
#import "ISEResultXmlParser.h"
#import "Definition.h"



#define _DEMO_UI_MARGIN                  5
#define _DEMO_UI_BUTTON_HEIGHT           49
#define _DEMO_UI_TOOLBAR_HEIGHT          44
#define _DEMO_UI_STATUSBAR_HEIGHT        20



#pragma mark - const values


NSString* const KCTextCNSyllable=@"text_cn_syllable";
NSString* const KCTextCNWord=@"text_cn_word";
NSString* const KCTextCNSentence=@"text_cn_sentence";
NSString* const KCTextENWord=@"text_en_word";
NSString* const KCTextENSentence=@"text_en_sentence";



#pragma mark -

@interface ISEViewController () <IFlySpeechEvaluatorDelegate ,ISESettingDelegate ,ISEResultXmlParserDelegate,IFlyPcmRecorderDelegate>

@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, assign) CGFloat textViewHeight;
@property (nonatomic, strong) IBOutlet UITextView *resultView;
@property (nonatomic, strong) NSString* resultText;
@property (nonatomic, assign) CGFloat resultViewHeight;

@property (nonatomic, strong) IBOutlet UIButton *startBtn;
@property (nonatomic, strong) IBOutlet UIButton *stopBtn;
@property (nonatomic, strong) IBOutlet UIButton *parseBtn;
@property (nonatomic, strong) IBOutlet UIButton *cancelBtn;

@property (nonatomic, strong) PopupView *popupView;
@property (nonatomic, strong) ISESettingViewController *settingViewCtrl;
@property (nonatomic, strong) IFlySpeechEvaluator *iFlySpeechEvaluator;

@property (nonatomic, assign) BOOL isSessionResultAppear;
@property (nonatomic, assign) BOOL isSessionEnd;

@property (nonatomic, assign) BOOL isValidInput;
@property (nonatomic, assign) BOOL isDidset;

@property (nonatomic,strong) IFlyPcmRecorder *pcmRecorder;//PCM Recorder to be used to demonstrate Audio Stream Evaluation.
@property (nonatomic,assign) BOOL isBeginOfSpeech;//Whether or not SDK has invoke the delegate methods of beginOfSpeech.

@end

@implementation ISEViewController

static NSString *LocalizedEvaString(NSString *key, NSString *comment) {
    return NSLocalizedStringFromTable(key, @"eva/eva", comment);
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


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [super viewWillAppear:animated];
    self.iFlySpeechEvaluator.delegate = self;
    
    self.isSessionResultAppear=YES;
    self.isSessionEnd=YES;
    self.startBtn.enabled=YES;
}

- (void)viewWillDisappear:(BOOL)animated{

//     unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [self.iFlySpeechEvaluator cancel];
    self.iFlySpeechEvaluator.delegate = nil;
    self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
    self.resultText=@"";
    
    [_pcmRecorder stop];
    _pcmRecorder.delegate = nil;
    
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    // adjust the UI for iOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if (IOS7_OR_LATER) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif

    //keyboard
    UIBarButtonItem *spaceBtnItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                  target:nil
                                                                                  action:nil];
    UIBarButtonItem *hideBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(onKeyBoardDown:)];
    [hideBtnItem setTintColor:[UIColor whiteColor]];
    UIToolbar *keyboardToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, _DEMO_UI_TOOLBAR_HEIGHT)];
    keyboardToolbar.barStyle = UIBarStyleBlackTranslucent;
    NSArray *array = [NSArray arrayWithObjects:spaceBtnItem, hideBtnItem, nil];
    [keyboardToolbar setItems:array];
    self.textView.inputAccessoryView = keyboardToolbar;
    
    self.textView.layer.cornerRadius = 8;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor =[[UIColor whiteColor] CGColor];

    self.resultView.layer.cornerRadius = 8;
    self.resultView.layer.borderWidth = 1;
    self.resultView.layer.borderColor =[[UIColor whiteColor] CGColor];
    [self.resultView setEditable:NO];
    
    self.popupView = [[PopupView alloc]initWithFrame:CGRectMake(100, 300, 0, 0)];
    self.popupView.ParentView = self.view;


	if (!self.iFlySpeechEvaluator) {
		self.iFlySpeechEvaluator = [IFlySpeechEvaluator sharedInstance];
	}
	self.iFlySpeechEvaluator.delegate = self;
	//empty params
	[self.iFlySpeechEvaluator setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    _isSessionResultAppear=YES;
    _isSessionEnd=YES;
    _isValidInput=YES;
    self.iseParams=[ISEParams fromUserDefaults];
    [self reloadCategoryText];
    
    //Initialize recorder
    if (_pcmRecorder == nil)
    {
        _pcmRecorder = [IFlyPcmRecorder sharedInstance];
    }
    
    _pcmRecorder.delegate = self;
    
    [_pcmRecorder setSample:@"16000"];
    
    [_pcmRecorder setSaveAudioPath:nil];    //not save the audio file
    
    [self setExclusiveTouchForButtons:self.view];
}

-(void)reloadCategoryText{
    
    [self.iFlySpeechEvaluator setParameter:self.iseParams.bos forKey:[IFlySpeechConstant VAD_BOS]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.eos forKey:[IFlySpeechConstant VAD_EOS]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.category forKey:[IFlySpeechConstant ISE_CATEGORY]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.language forKey:[IFlySpeechConstant LANGUAGE]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.rstLevel forKey:[IFlySpeechConstant ISE_RESULT_LEVEL]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.timeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
    [self.iFlySpeechEvaluator setParameter:self.iseParams.audioSource forKey:[IFlySpeechConstant AUDIO_SOURCE]];
    
    if ([self.iseParams.language isEqualToString:KCLanguageZHCN]) {
        if ([self.iseParams.category isEqualToString:KCCategorySyllable]) {
            self.textView.text = LocalizedEvaString(KCTextCNSyllable, nil);
        }
        else if ([self.iseParams.category isEqualToString:KCCategoryWord]) {
            self.textView.text = LocalizedEvaString(KCTextCNWord, nil);
        }
        else {
            self.textView.text = LocalizedEvaString(KCTextCNSentence, nil);
        }
    }
    else {
        if ([self.iseParams.category isEqualToString:KCCategoryWord]) {
            self.textView.text = LocalizedEvaString(KCTextENWord, nil);
        }
        else {
            self.textView.text = LocalizedEvaString(KCTextENSentence, nil);
        }
        self.isValidInput=YES;

    }
}

-(void)resetBtnSatus:(IFlySpeechError *)errorCode{
    
    if(errorCode && errorCode.errorCode!=0){
        self.isSessionResultAppear=NO;
        self.isSessionEnd=YES;
        self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
        self.resultText=@"";
    }else{
        if(self.isSessionResultAppear == NO){
            self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
            self.resultText=@"";
        }
        self.isSessionResultAppear=YES;
        self.isSessionEnd=YES;
    }
    self.startBtn.enabled=YES;
}

#pragma mark - keyboard

-(void)onKeyBoardDown:(id) sender{
    [self.textView resignFirstResponder];
}


-(void)setViewSize:(BOOL)show Notification:(NSNotification*) notification{

    if (!self.isDidset){
        self.textViewHeight = self.textView.frame.size.height;
        self.resultViewHeight = self.resultView.frame.size.height;
        self.isDidset = YES;
    }

    NSDictionary *userInfo = [notification userInfo];
    int keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    CGRect textRect = self.textView.frame;
    CGRect resultRect = self.resultView.frame;
    if (show) {
        textRect.size.height = self.view.frame.size.height - keyboardHeight - _DEMO_UI_MARGIN*4;
        resultRect.size.height = 0;
    }
    else{
        textRect.size.height = self.textViewHeight;
        resultRect.size.height = self.resultViewHeight;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3]; // if you want to slide up the view

        self.textView.frame = textRect;
        self.resultView.frame=resultRect;
        
        [UIView commitAnimations];
    });

}

-(void)keyboardWillShow:(NSNotification *)notification {
        [self setViewSize:YES Notification:notification];
}

-(void)keyboardWillHide :(NSNotification *)notification{
        [self setViewSize:NO Notification:notification];
}



#pragma mark - Button handler

/*!
 *  Setting
 */
- (IBAction)onSetting:(id)sender {
	if (!self.settingViewCtrl) {
		self.settingViewCtrl = [[ISESettingViewController alloc] initWithStyle:UITableViewStylePlain];
		self.settingViewCtrl.delegate = self;
	}
    
    if (![[self.navigationController topViewController] isKindOfClass:[ISESettingViewController class]]){
        [self.navigationController pushViewController:self.settingViewCtrl animated:YES];
    }
	
}

/*!
 *  start recorder
 */
- (IBAction)onBtnStart:(id)sender {
    
    NSLog(@"%s[IN]",__func__);
    
	[self.iFlySpeechEvaluator setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
	[self.iFlySpeechEvaluator setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
	[self.iFlySpeechEvaluator setParameter:@"xml" forKey:[IFlySpeechConstant ISE_RESULT_TYPE]];

    [self.iFlySpeechEvaluator setParameter:@"eva.pcm" forKey:[IFlySpeechConstant ISE_AUDIO_PATH]];
    
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    NSLog(@"text encoding:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]]);
    NSLog(@"language:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]]);
    
    BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]] isEqualToString:@"utf-8"];
    BOOL isZhCN=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]] isEqualToString:KCLanguageZHCN];
    
    BOOL needAddTextBom=isUTF8&&isZhCN;
    NSMutableData *buffer = nil;
    if(needAddTextBom){
        if(self.textView.text && [self.textView.text length]>0){
            Byte bomHeader[] = { 0xEF, 0xBB, 0xBF };
            buffer = [NSMutableData dataWithBytes:bomHeader length:sizeof(bomHeader)];
            [buffer appendData:[self.textView.text dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@" \ncn buffer length: %lu",(unsigned long)[buffer length]);
        }
    }else{
        buffer= [NSMutableData dataWithData:[self.textView.text dataUsingEncoding:encoding]];
        NSLog(@" \nen buffer length: %lu",(unsigned long)[buffer length]);
    }
    self.resultView.text = NSLocalizedString(@"M_ISE_Noti2", nil);
    self.resultText=@"";
	
   BOOL ret = [self.iFlySpeechEvaluator startListening:buffer params:nil];
    if(ret){
        self.isSessionResultAppear=NO;
        self.isSessionEnd=NO;
        self.startBtn.enabled=NO;
        
        //Set audio stream as audio source,which requires the developer import audio data into the recognition control by self through "writeAudio:".
        if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
            
            _isBeginOfSpeech = NO;
            //set the category of AVAudioSession
            [IFlyAudioSession initRecordingAudioSession];
            
            _pcmRecorder.delegate = self;
            
            //start recording
            BOOL ret = [_pcmRecorder start];
            
            NSLog(@"%s[OUT],Success,Recorder ret=%d",__func__,ret);
        }
    }
}

/*!
 *  stop recording
 */
- (IBAction)onBtnStop:(id)sender {
    
    if(!self.isSessionResultAppear &&  !self.isSessionEnd){
        self.resultView.text = NSLocalizedString(@"M_ISE_Noti3", nil);
        self.resultText=@"";
    }
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM] && !_isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }
    
	[self.iFlySpeechEvaluator stopListening];
    [self.resultView resignFirstResponder];
    [self.textView resignFirstResponder];
    self.startBtn.enabled=YES;
}

/*!
 *  cancel speech evaluation
 */
- (IBAction)onBtnCancel:(id)sender {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM] && !_isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }

	[self.iFlySpeechEvaluator cancel];
	[self.resultView resignFirstResponder];
    [self.textView resignFirstResponder];
	[self.popupView removeFromSuperview];
    self.resultView.text = NSLocalizedString(@"M_ISE_Noti1", nil);
    self.resultText=@"";
    self.startBtn.enabled=YES;
}


/*!
 *  parse results
 */
- (IBAction)onBtnParse:(id)sender {
    
    ISEResultXmlParser* parser=[[ISEResultXmlParser alloc] init];
    parser.delegate=self;
    [parser parserXml:self.resultText];
    
}


#pragma mark - ISESettingDelegate

/*!
 *  callback of ISE setting
 */
- (void)onParamsChanged:(ISEParams *)params {
    self.iseParams=params;
    [self performSelectorOnMainThread:@selector(reloadCategoryText) withObject:nil waitUntilDone:NO];
}

#pragma mark - IFlySpeechEvaluatorDelegate

/*!
 *  volume callback,range from 0 to 30.
 */
- (void)onVolumeChanged:(int)volume buffer:(NSData *)buffer {
//    NSLog(@"volume:%d",volume);
    [self.popupView setText:[NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"T_RecVol", nil),volume]];
    [self.view addSubview:self.popupView];
}

/*!
 *  Beginning Of Speech
 */
- (void)onBeginOfSpeech {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
        _isBeginOfSpeech =YES;
    }
    
}

/*!
 *  End Of Speech
 */
- (void)onEndOfSpeech {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
        [_pcmRecorder stop];
    }
    
}

/*!
 *  callback of canceling evaluation
 */
- (void)onCancel {
    
}

/*!
 *  evaluation session completion, which will be invoked no matter whether it exits error.
 *  error.errorCode =
 *  0     success
 *  other fail 
 */
- (void)onError:(IFlySpeechError *)errorCode {
    if(errorCode && errorCode.errorCode!=0){
        [self.popupView setText:[NSString stringWithFormat:@"Error：%d %@",[errorCode errorCode],[errorCode errorDesc]]];
        [self.view addSubview:self.popupView];
        
    }
    
    [self performSelectorOnMainThread:@selector(resetBtnSatus:) withObject:errorCode waitUntilDone:NO];

}

/*!
 *  result callback of speech evaluation
 *  results：evaluation results
 *  isLast：whether or not this is the last result
 */
- (void)onResults:(NSData *)results isLast:(BOOL)isLast{
	if (results) {
		NSString *showText = @"";
        
        const char* chResult=[results bytes];
        
        BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant RESULT_ENCODING]]isEqualToString:@"utf-8"];
        NSString* strResults=nil;
        if(isUTF8){
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:NSUTF8StringEncoding];
        }else{
            NSLog(@"result encoding: gb2312");
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:encoding];
        }
        if(strResults){
            showText = [showText stringByAppendingString:strResults];
        }
        
        self.resultText=showText;
		self.resultView.text = showText;
        self.isSessionResultAppear=YES;
        self.isSessionEnd=YES;
        if(isLast){
            [self.popupView setText: NSLocalizedString(@"T_ISE_End", nil)];
            [self.view addSubview:self.popupView];
        }

	}
    else{
        if(isLast){
            [self.popupView setText: NSLocalizedString(@"M_ISE_Msg", nil)];
            [self.view addSubview:self.popupView];
        }
        self.isSessionEnd=YES;
    }
    self.startBtn.enabled=YES;
}

#pragma mark - ISEResultXmlParserDelegate

-(void)onISEResultXmlParser:(NSXMLParser *)parser Error:(NSError*)error{
    
}

-(void)onISEResultXmlParserResult:(ISEResult*)result{
    self.resultView.text=[result toString];
}


#pragma mark - IFlyPcmRecorderDelegate

- (void) onIFlyRecorderBuffer: (const void *)buffer bufferSize:(int)size
{
    NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
    
    int ret = [self.iFlySpeechEvaluator writeAudio:audioBuffer];
    if (!ret)
    {
        [self.iFlySpeechEvaluator stopListening];
    }
}

- (void) onIFlyRecorderError:(IFlyPcmRecorder*)recoder theError:(int) error
{
    
}

//range from 0 to 30
- (void) onIFlyRecorderVolumeChanged:(int) power
{
    [self.popupView setText:[NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"T_RecVol", nil),power]];
    [self.view addSubview:self.popupView];
}

@end
