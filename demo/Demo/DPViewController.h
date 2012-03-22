//
//  DPViewController.h
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DPViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (retain, nonatomic) IBOutlet UIButton *chooseButton;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (retain, nonatomic) IBOutlet UITextView *resultTextView;

- (IBAction)didChoosePhotoAndUpload:(id)sender;

- (void)start;
- (void)stop;

@end
