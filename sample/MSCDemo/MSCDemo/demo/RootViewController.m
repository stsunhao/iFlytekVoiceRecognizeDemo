//
//  RootViewController.m
//  MSCDemo
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Definition.h"
#import "PopupView.h"
#import "IFlyMSC/IFlyMSC.h"

/*
 The SDK Demo includes seven services as follows：
 1.Short Form ASR                   (business -> isr)
 2.Natural Language Understanding   (business -> nlp)
 3.Grammar Recognition              (business -> asr)
 4.Text-to-Speech                   (business -> tts)
 5.Speech Evaluation                (business -> ise)
 6.Voice Wakeup                     (Not integrated)
 7.Voiceprint Recognition           (Not integrated)
*/

@implementation RootViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ( IOS7_OR_LATER )
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif
    _tbView.delegate = self;
    _tbView.dataSource = self;
    _tbView.separatorColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
    
    
    
    UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
    temporaryBarButtonItem.title = NSLocalizedString(@"B_Back", nil);
    temporaryBarButtonItem.target = self;
    self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
    

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}




-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if ( indexPath.row == 5 || indexPath.row == 6) {
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"T_Alter", nil)
                                       message:NSLocalizedString(@"M_Alter", nil)
                                      delegate:self
                             cancelButtonTitle:NSLocalizedString(@"B_Ok", nil) otherButtonTitles:nil];
            [alert show];
        }
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, 0.5)];
        view.backgroundColor = [UIColor blackColor];
        return  view;
    }else {
        return nil;
    }
}

@end
