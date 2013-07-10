//
//  QiniuViewController.h
//  QiniuDemo
//
//  Created by Qiniu Developers on 12-11-14.
//  Copyright (c) 2012 Shanghai Qiniu Information Technologies Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../QiniuSDK/QiniuUploadDelegate.h"
#import "../../QiniuSDK/QiniuSimpleUploader.h"
#import "../../QiniuSDK/QiniuResumableUpload.h"

@interface QiniuViewController : UIViewController<QiniuUploadDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate>
{
    UIPopoverController *_customPopoverController;
    QiniuResumableUpload *_resumableUploader;
    QiniuSimpleUploader *_simpleUploader;
    NSTimeInterval _uploadStartTime; // For profiling.
    NSString *_key;
}
@property (retain, nonatomic) IBOutlet UIImageView *pictureViewer;
@property (retain, nonatomic) IBOutlet UIProgressView *progressBar;
@property (retain, nonatomic) IBOutlet UITextView *uploadStatus;
@property (retain, nonatomic) IBOutlet UIButton *uploadButton;
@property (retain, nonatomic) IBOutlet UISegmentedControl *uploadMode;
- (IBAction)uploadButtonPressed:(id)sender;
@end
