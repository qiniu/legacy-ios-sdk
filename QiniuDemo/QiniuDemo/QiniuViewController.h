//
//  QiniuViewController.h
//  QiniuDemo
//
//  Created by Hugh Lv on 12-11-14.
//  Copyright (c) 2012年 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../QiniuSDK/QiniuUploadDelegate.h"
#import "../../QiniuSDK/QiniuSimpleUploader.h"

@interface QiniuViewController : UIViewController<QiniuUploadDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate>
{
    UIPopoverController *popoverController;
}
@property (retain, nonatomic) IBOutlet UIImageView *pictureViewer;
@property (retain, nonatomic) IBOutlet UIProgressView *progressBar;
@property (retain, nonatomic) IBOutlet UITextView *uploadStatus;
@property (retain, nonatomic) IBOutlet UIButton *uploadButton;
- (IBAction)uploadButtonPressed:(id)sender;
@end
