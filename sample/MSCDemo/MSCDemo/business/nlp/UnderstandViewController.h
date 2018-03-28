//
//  UnderstandViewController.h
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFlyMSC/IFlyMSC.h"

//forward declare
@class PopupView;
@class IFlyDataUploader;
@class IFlySpeechUnderstander;

/**
 demo of Natural Language Understanding (NLP)
 **/
@interface UnderstandViewController : UIViewController<IFlySpeechRecognizerDelegate>

//speech understanding control
@property (nonatomic,strong) IFlySpeechUnderstander *iFlySpeechUnderstander;
//text understanding control
@property (nonatomic,strong) IFlyTextUnderstander *iFlyUnderStand;

@property (nonatomic,weak)   UITextView *resultView;
@property (nonatomic,strong) PopupView  *popUpView;
@property (nonatomic, copy)  NSString * defaultText;

@property (nonatomic) BOOL isCanceled;
@property (nonatomic,strong) NSString *result;

@property (weak, nonatomic) IBOutlet UIButton *textUnderBtn;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *onlineRecBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;

@property (nonatomic) BOOL isSpeechUnderstander;
@property (nonatomic) BOOL isTextUnderstander;
@end
