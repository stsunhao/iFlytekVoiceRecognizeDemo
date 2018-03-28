//
//  ABNFViewController.h
//  MSCDemo
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFlyMSC/IFlyMSC.h"

@class PopupView;
@class IFlyDataUploader;
@class IFlySpeechRecognizer;

/**
 demo of Grammar Recognition (ASR)
 
 Five steps to integrating Grammar Recognition as follows:
 1.Instantiate IFlySpeechRecognizer singleton and IFlyDataUploader;
 2.Upload grammar file and acquire grammarID. Please refer to the inteface of buildGrammer in ABNFViewController.m for specific implementation;
 3.Set recognition params, especially obtained grammarID above;
 4.Add IFlySpeechRecognizerDelegate methods selectively;
 5.Start recognition;
 **/


@interface ABNFViewController : UIViewController<IFlySpeechRecognizerDelegate,UIActionSheetDelegate>


@property (nonatomic, strong) IFlySpeechRecognizer *iFlySpeechRecognizer;//Recognition conrol

@property (nonatomic, strong) PopupView *popUpView;


@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *uploadBtn;
@property (weak, nonatomic) IBOutlet UIButton *startRecBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;


@property (nonatomic, assign) BOOL isCanceled;
@property (nonatomic, strong) NSString *grammarType; //the type of grammar recognition
@property (nonatomic, strong) NSMutableString *curResult;//the results of current session
@end
