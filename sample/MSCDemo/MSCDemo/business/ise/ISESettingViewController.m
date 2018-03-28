//
//  ISESettingViewController.m
//  MSCDemo_UI
//
//  Created by 张剑 on 15/1/16.
//
//

#import "ISESettingViewController.h"
#import "ISEParams.h"
#import "PopupView.h"
#import "Definition.h"

#pragma mark - const values

int const KCSectionCount=1;
int const KCCellCount=7;

#pragma mark -

@interface ISESettingViewController () 

@property (nonatomic, strong) PopupView* popView;

@end


@implementation ISESettingViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
	
    //set TableView DataSource
	self.iseParams = [ISEParams fromUserDefaults];

	return [super initWithStyle:style];
}

#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ( IOS7_OR_LATER )
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
        self.navigationController.navigationBar.translucent = NO;
    }
#endif
    
    self.title= NSLocalizedString(@"T_ISE_SetTil", nil);

    //popupView
    self.popView = [[PopupView alloc]initWithFrame:CGRectMake(100, 300, 0, 0)];
    self.popView.ParentView = self.view;
    
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor=[UIColor blackColor];
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if([self.tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]){
        [self.tableView setCellLayoutMarginsFollowReadableWidth:NO];
    }

    
}

- (void)reloadData {
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    [self.iseParams toUserDefaults];
    
	if (self.delegate && [self.delegate respondsToSelector:@selector(onParamsChanged:)]) {
		[self.delegate onParamsChanged:self.iseParams];
	}
}

#pragma mark - TableviewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return KCSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return KCCellCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* const KCCellIdentifier=@"ISESettingCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:KCCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:KCCellIdentifier];
        cell.backgroundColor=[UIColor blackColor];
        cell.autoresizesSubviews=YES;
        cell.autoresizingMask =UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	}
    switch (indexPath.row) {
        case 0:{
            cell.textLabel.text = NSLocalizedString(@"K_ISE_Lang", nil);
            cell.detailTextLabel.text = NSLocalizedString(self.iseParams.languageShow, nil);
        }
            break;
        case 1:{
            cell.textLabel.text = NSLocalizedString(@"K_ISE_Cate", nil);
            cell.detailTextLabel.text = NSLocalizedString(self.iseParams.categoryShow, nil);
        }
            break;
        case 2:{
            cell.textLabel.text = NSLocalizedString(@"K_ISE_RstLv", nil);
            cell.detailTextLabel.text = self.iseParams.rstLevel;
        }
            break;
        case 3:{
            cell.textLabel.text = NSLocalizedString(@"K_BOS", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ ms",self.iseParams.bos];
        }
            break;
        case 4:{
            cell.textLabel.text = NSLocalizedString(@"K_EOS", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ ms",self.iseParams.eos];
        }
            break;
        case 5:{
            cell.textLabel.text = NSLocalizedString(@"K_ISE_Timeout", nil);
            int value=[self.iseParams.timeout intValue];
            if( value >= 0 ){
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ ms",self.iseParams.timeout];
            }
            else{
                cell.detailTextLabel.text = self.iseParams.timeout;
            }
            
        }
            break;
        case 6:{
            cell.textLabel.text = NSLocalizedString(@"K_AudSource", nil);
            if ([self.iseParams.audioSource isEqualToString:KCSourceMIC]){
                cell.detailTextLabel.text = NSLocalizedString(@"K_MIC", nil);
            }else{
                cell.detailTextLabel.text = NSLocalizedString(@"K_Stream", nil);
            }
        }
            break;
            
        default:
            break;
    }
	
    cell.detailTextLabel.font=[UIFont systemFontOfSize:13.0f];
	cell.detailTextLabel.textColor =[UIColor whiteColor];
    cell.textLabel.font=[UIFont systemFontOfSize:17.0f];
    cell.textLabel.textColor=[UIColor colorWithRed:29.0/255.0 green:207.0/255.0 blue:0.0 alpha:1.0];
    
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
	return cell;
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	switch (indexPath.row) {
		case 0: {
			NSString *title = NSLocalizedString(@"K_ISE_Cate", nil);
			UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
			                                                         delegate:self
			                                                cancelButtonTitle:nil
			                                           destructiveButtonTitle:nil
			                                                otherButtonTitles:nil, nil];
			actionSheet.tag = indexPath.row;
            if(![self.iseParams.rstLevel isEqualToString:KCRstLevelPlain]){//Plain is not supported in Chinese
                [actionSheet addButtonWithTitle: NSLocalizedString(@"K_LangCHZN", nil)];
            }
            if(![self.iseParams.category isEqualToString:KCCategorySyllable]){//Syllable is not supported in English
                [actionSheet addButtonWithTitle: NSLocalizedString(@"K_LangEng", nil)];
            }
			
			actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"B_Cancel", nil)];
			[actionSheet showInView:self.view];
		}
		break;

		case 1: {
            NSString *title = NSLocalizedString(@"K_ISE_Cate", nil);
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil, nil];
            actionSheet.tag = indexPath.row;
            [actionSheet addButtonWithTitle:NSLocalizedString(@"K_ISE_CateSent", nil)];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"K_ISE_CateWord", nil)];
            if(![self.iseParams.language isEqualToString:KCLanguageENUS]){//Syllable is not supported in English
                [actionSheet addButtonWithTitle:NSLocalizedString(@"K_ISE_CateSyll", nil)];
            }

            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"B_Cancel", nil)];
            [actionSheet showInView:self.view];

		}
		break;

		case 2: {
			NSString *title = NSLocalizedString(@"K_ISE_RstLv", nil);
			UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
			                                                         delegate:self
			                                                cancelButtonTitle:nil
			                                           destructiveButtonTitle:nil
			                                                otherButtonTitles:nil, nil];
			actionSheet.tag = indexPath.row;
            
            if(![self.iseParams.language isEqualToString:KCLanguageZHCN]){//Plain is not supported in Chinese
                [actionSheet addButtonWithTitle:KCRstLevelPlain];
            }
            
            [actionSheet addButtonWithTitle:KCRstLevelComplete];

			actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"B_Cancel", nil)];
			[actionSheet showInView:self.view];
		}
		break;

		case 3: {
			NSString *title = NSLocalizedString(@"K_BOS", nil);
			NSString *message = @"";
			NSString *btnOkTitle = NSLocalizedString(@"B_Ok", nil);
			NSString *btnCancelTitle = NSLocalizedString(@"B_Cancel", nil);
			NSString *placeholderText = @"";

			if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
				UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
				                                                                         message:message
				                                                                  preferredStyle:UIAlertControllerStyleAlert];
				[alertController addTextFieldWithConfigurationHandler: ^(UITextField *textField) {
				    NSString *defValue = self.iseParams.bos;
				    if (!defValue) {
				        defValue = placeholderText;
					}
				    textField.font = [UIFont systemFontOfSize:9];
				    textField.text = defValue;
                    textField.keyboardType=UIKeyboardTypeNumberPad;
                    textField.tag=0;
                    textField.delegate=self;
				}];
				UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:btnCancelTitle
				                                                       style:UIAlertActionStyleCancel
				                                                     handler: ^(UIAlertAction *action) {
				}];
				UIAlertAction *okAction = [UIAlertAction actionWithTitle:btnOkTitle
				                                                   style:UIAlertActionStyleDefault
				                                                 handler: ^(UIAlertAction *action) {
				    UITextField *textField = alertController.textFields.firstObject;
                    if(textField.text){
                        int value=[textField.text intValue];
                        if([textField.text length]<1){
                            [self.popView setText: NSLocalizedString(@"M_ISE_NoEmpty", nil)];
                            [self.view addSubview:self.popView];
                        }
                        else if(value>=0 && value<=30000){
                            self.iseParams.bos = textField.text;
                        }else{
                            [self.popView setText:[NSString stringWithFormat:@"%@0~30000", NSLocalizedString(@"M_ISE_Range", nil)]];
                            [self.view addSubview:self.popView];
                        }
                        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                    }
                    else{
                        [self.popView setText: NSLocalizedString(@"T_ISE_Unknown", nil)];
                        [self.view addSubview:self.popView];
                    }

				}];
				[alertController addAction:cancelAction];
				[alertController addAction:okAction];
				[self presentViewController:alertController animated:YES completion:nil];
			}
			else {
				UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:title
				                                                    message:message
				                                                   delegate:self
				                                          cancelButtonTitle:btnCancelTitle
				                                          otherButtonTitles:btnOkTitle, nil];
				alertview.alertViewStyle = UIAlertViewStylePlainTextInput;
				UITextField *textField = [alertview textFieldAtIndex:0];
                textField.keyboardType=UIKeyboardTypeNumberPad;
                textField.delegate=self;
                textField.tag=0;
				alertview.tag = indexPath.row;
				NSString *defValue = self.iseParams.bos;
				if (!defValue) {
					defValue = placeholderText;
				}
				textField.font = [UIFont systemFontOfSize:9];
				textField.text = defValue;
				[alertview show];
			}
		}
		break;

		case 4: {
			NSString *title = NSLocalizedString(@"K_EOS", nil);
			NSString *message = @"";
			NSString *btnOkTitle = NSLocalizedString(@"B_Ok", nil);
			NSString *btnCancelTitle = NSLocalizedString(@"B_Cancel", nil);
			NSString *placeholderText = @"";

			if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
				UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
				                                                                         message:message
				                                                                  preferredStyle:UIAlertControllerStyleAlert];
				[alertController addTextFieldWithConfigurationHandler: ^(UITextField *textField) {
				    NSString *defValue = self.iseParams.eos;
				    if (!defValue) {
				        defValue = placeholderText;
					}
				    textField.font = [UIFont systemFontOfSize:9];
				    textField.text = defValue;
                    textField.keyboardType=UIKeyboardTypeNumberPad;
                    textField.delegate=self;
                    textField.tag=1;
				}];
				UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:btnCancelTitle
				                                                       style:UIAlertActionStyleCancel
				                                                     handler: ^(UIAlertAction *action) {
				}];
				UIAlertAction *okAction = [UIAlertAction actionWithTitle:btnOkTitle
				                                                   style:UIAlertActionStyleDefault
				                                                 handler: ^(UIAlertAction *action) {
				    UITextField *textField = alertController.textFields.firstObject;
                     if(textField.text){
                         int value=[textField.text intValue];
                         if([textField.text length]<1){
                             [self.popView setText: NSLocalizedString(@"M_ISE_NoEmpty", nil)];
                             [self.view addSubview:self.popView];
                         }
                         else if(value>=0 && value<=30000){
                             self.iseParams.eos = textField.text;
                         }else{
                             [self.popView setText:[NSString stringWithFormat:@"%@0~30000", NSLocalizedString(@"M_ISE_Range", nil)]];
                             [self.view addSubview:self.popView];
                         }
                         [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                     }
                     else{
                         [self.popView setText: NSLocalizedString(@"T_ISE_Unknown", nil)];
                         [self.view addSubview:self.popView];
                     }
				}];
				[alertController addAction:cancelAction];
				[alertController addAction:okAction];
				[self presentViewController:alertController animated:YES completion:nil];
			}
			else {
				UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:title
				                                                    message:message
				                                                   delegate:self
				                                          cancelButtonTitle:btnCancelTitle
				                                          otherButtonTitles:btnOkTitle, nil];
				alertview.alertViewStyle = UIAlertViewStylePlainTextInput;
				UITextField *textField = [alertview textFieldAtIndex:0];
                textField.keyboardType=UIKeyboardTypeNumberPad;
                textField.delegate=self;
                textField.tag=1;
				alertview.tag = indexPath.row;
				NSString *defValue = self.iseParams.eos;
				if (!defValue) {
					defValue = placeholderText;
				}
				textField.font = [UIFont systemFontOfSize:9];
				textField.text = defValue;
				[alertview show];
			}
		}
		break;

		case 5: {
			NSString *title = NSLocalizedString(@"K_ISE_Timeout", nil);
			NSString *message = @"";
			NSString *btnOkTitle = NSLocalizedString(@"B_Ok", nil);
			NSString *btnCancelTitle = NSLocalizedString(@"B_Cancel", nil);
			NSString *placeholderText = @"";

			if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
				UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
				                                                                         message:message
				                                                                  preferredStyle:UIAlertControllerStyleAlert];
				[alertController addTextFieldWithConfigurationHandler: ^(UITextField *textField) {
				    NSString *defValue = self.iseParams.timeout;
				    if (!defValue) {
				        defValue = placeholderText;
					}
				    textField.font = [UIFont systemFontOfSize:9];
				    textField.text = defValue;
                    textField.keyboardType=UIKeyboardTypeNumbersAndPunctuation;
                    textField.delegate=self;
                    textField.tag=2;
				}];
				UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:btnCancelTitle
				                                                       style:UIAlertActionStyleCancel
				                                                     handler: ^(UIAlertAction *action) {
				}];
				UIAlertAction *okAction = [UIAlertAction actionWithTitle:btnOkTitle
				                                                   style:UIAlertActionStyleDefault
				                                                 handler: ^(UIAlertAction *action) {
				    UITextField *textField = alertController.textFields.firstObject;
                    
                     if(textField.text){
                         int value=[textField.text intValue];
                         if([textField.text length]<1){
                             [self.popView setText: NSLocalizedString(@"M_ISE_NoEmpty", nil)];
                             [self.view addSubview:self.popView];
                         }
                         else if(value>=-1){
                             self.iseParams.timeout = textField.text;
                         }else{
                             [self.popView setText:[NSString stringWithFormat:@"%@ >=-1", NSLocalizedString(@"M_ISE_Range", nil)]];
                             [self.view addSubview:self.popView];
                         }
                         [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                     }
                     else{
                         [self.popView setText: NSLocalizedString(@"T_ISE_Unknown", nil)];
                         [self.view addSubview:self.popView];
                     }
				}];
				[alertController addAction:cancelAction];
				[alertController addAction:okAction];
				[self presentViewController:alertController animated:YES completion:nil];
			}
			else {
				UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:title
				                                                    message:message
				                                                   delegate:self
				                                          cancelButtonTitle:btnCancelTitle
				                                          otherButtonTitles:btnOkTitle, nil];
				alertview.alertViewStyle = UIAlertViewStylePlainTextInput;
				UITextField *textField = [alertview textFieldAtIndex:0];
                textField.keyboardType=UIKeyboardTypeNumbersAndPunctuation;
                textField.delegate=self;
                textField.tag=2;
				alertview.tag = indexPath.row;
				NSString *defValue = self.iseParams.timeout;
				if (!defValue) {
					defValue = placeholderText;
				}
				textField.font = [UIFont systemFontOfSize:9];
				textField.text = defValue;
				[alertview show];
			}
		}
		break;
            
        case 6: {
            NSString *title = NSLocalizedString(@"K_AudSource", nil);
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil, nil];
            actionSheet.tag = indexPath.row;
            
            [actionSheet addButtonWithTitle: NSLocalizedString(@"K_MIC", nil)];
            [actionSheet addButtonWithTitle: NSLocalizedString(@"K_Stream", nil)];
            
            actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"B_Cancel", nil)];
            [actionSheet showInView:self.view];
        }
            break;

		default:
			break;
	}
}

#pragma mark  UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	switch (actionSheet.tag) {
		case 0: {
			switch (buttonIndex) {
				case 0: {
                    if(![self.iseParams.rstLevel isEqualToString:KCRstLevelPlain]){//Plain is not supported in Chinese
                        self.iseParams.language = KCLanguageZHCN;
                        self.iseParams.languageShow = @"K_LangCHZN";
                    }
                    else{
                        self.iseParams.language = KCLanguageENUS;
                        self.iseParams.languageShow = @"K_LangEng";
                    }
				}
				break;

				case 1: {
                    if(![self.iseParams.category isEqualToString:KCCategorySyllable]){//Syllable is not supported in English
                        self.iseParams.language = KCLanguageENUS;
                        self.iseParams.languageShow = @"K_LangEng";
                    }
				}
				break;
			}
		}
		break;

		case 1: {
			switch (buttonIndex) {
                case 0: {
                    self.iseParams.category = KCCategorySentence;
                    self.iseParams.categoryShow = @"K_ISE_CateSent";
                }
                    break;
                    
				case 1: {
                    self.iseParams.category = KCCategoryWord;
                    self.iseParams.categoryShow = @"K_ISE_CateWord";
				}
				break;

                case 2: {
                    if(![self.iseParams.language isEqualToString:KCLanguageENUS]){//Syllable is not supported in English
                        self.iseParams.category = KCCategorySyllable;
                        self.iseParams.categoryShow = @"K_ISE_CateSyll";
                    }
                }
                    break;
			
			}
		}
		break;

		case 2: {
			switch (buttonIndex) {
				case 0: {
                     if([self.iseParams.language isEqualToString:KCLanguageENUS]){//Plain is not supported in Chinese
                        self.iseParams.rstLevel = KCRstLevelPlain;
                     }
                     else{
                         self.iseParams.rstLevel = KCRstLevelComplete;
                     }
				}
				break;

				case 1: {
					self.iseParams.rstLevel = KCRstLevelComplete;
				}
				break;
			}
		}
		break;
            
        case 6:{
            switch (buttonIndex) {
                case 0: {
                    self.iseParams.audioSource = KCSourceMIC;
                }
                break;
                    
                case 1: {
                    self.iseParams.audioSource = KCSourceSTREAM;
                }
                break;
            }
        }
        break;
	}
	[self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

#pragma mark - AlertviewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (alertView.tag) {
		case 3: {
			switch (buttonIndex) {
				case 1: {
					UITextField *textField = [alertView textFieldAtIndex:0];
                    
                    if(textField.text){
                        int value=[textField.text intValue];
                        if([textField.text length]<1){
                            [self.popView setText: NSLocalizedString(@"M_ISE_NoEmpty", nil)];
                            [self.view addSubview:self.popView];
                        }
                        else if(value>=0 && value<=30000){
                            self.iseParams.bos = textField.text;
                        }else{
                            [self.popView setText:[NSString stringWithFormat:@"%@0~30000", NSLocalizedString(@"M_ISE_Range", nil)]];
                            [self.view addSubview:self.popView];
                        }
                        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                    }
                    else{
                        [self.popView setText: NSLocalizedString(@"T_ISE_Unknown", nil)];
                        [self.view addSubview:self.popView];
                    }
				}
				break;

				default:
					break;
			}
		}
		break;

		case 4: {
			switch (buttonIndex) {
				case 1: {
					UITextField *textField = [alertView textFieldAtIndex:0];
                    if(textField.text){
                        int value=[textField.text intValue];
                        if([textField.text length]<1){
                            [self.popView setText: NSLocalizedString(@"M_ISE_NoEmpty", nil)];
                            [self.view addSubview:self.popView];
                        }
                        else if(value>=0 && value<=30000){
                            self.iseParams.eos = textField.text;
                        }else{
                            [self.popView setText:[NSString stringWithFormat:@"%@0~30000", NSLocalizedString(@"M_ISE_Range", nil)]];
                            [self.view addSubview:self.popView];
                        }
                        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                    }
                    else{
                        [self.popView setText: NSLocalizedString(@"T_ISE_Unknown", nil)];
                        [self.view addSubview:self.popView];
                    }
				}
				break;

				default:
					break;
			}
		}
		break;

		case 5: {
			switch (buttonIndex) {
				case 1: {
					UITextField *textField = [alertView textFieldAtIndex:0];
                    
                    if(textField.text){
                        int value=[textField.text intValue];
                        if([textField.text length]<1){
                            [self.popView setText: NSLocalizedString(@"M_ISE_NoEmpty", nil)];
                            [self.view addSubview:self.popView];
                        }
                        else if(value>=-1){
                            self.iseParams.timeout = textField.text;
                        }else{
                            [self.popView setText:[NSString stringWithFormat:@"%@ >=-1", NSLocalizedString(@"M_ISE_Range", nil)]];
                            [self.view addSubview:self.popView];
                        }
                        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                    }
                    else{
                        [self.popView setText: NSLocalizedString(@"T_ISE_Unknown", nil)];
                        [self.view addSubview:self.popView];
                    }
				}
				break;

				default:
					break;
			}
		}
		break;

		default:
			break;
	}
	[self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}


#pragma mark - UITextFieldDelegat

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    BOOL isValid=YES;
    
    if(textField.tag<2){
        NSCharacterSet* validSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        int  i=0;
        while(i<string.length){
            NSString * subStr= [string substringWithRange:NSMakeRange(i, 1)];
            NSRange subRange = [subStr rangeOfCharacterFromSet:validSet];
            if (subRange.length == 0) {
                isValid = NO;
                break;
            }
            i++;
        }
    }
    else{
        NSCharacterSet* validFSet = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
        NSCharacterSet* validOSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        int  i=0;
        while(i<string.length){
            NSString * subStr= [string substringWithRange:NSMakeRange(i, 1)];
            NSRange subRange;
            if(0==i && range.location==0){
                subRange = [subStr rangeOfCharacterFromSet:validFSet];
            }else{
                subRange = [subStr rangeOfCharacterFromSet:validOSet];
            }
            if (subRange.length == 0) {
                isValid = NO;
                break;
            }
            i++;
        }
    }
    return isValid;
}

@end
