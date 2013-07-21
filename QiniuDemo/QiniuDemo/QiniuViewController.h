//
//  QiniuViewController.h
//  QiniuDemo
//
//  Created by Qiniu Developers 2013
//

#import <UIKit/UIKit.h>
#import "../../QiniuSDK/QiniuUploadDelegate.h"
#import "../../QiniuSDK/QiniuSimpleUploader.h"
#import "../../QiniuSDK/QiniuResumableUploader.h"

@interface QiniuViewController : UIViewController<QiniuUploadDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate>
{
    UIPopoverController *_customPopoverController;
    QiniuResumableUploader *_resumableUploader;
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
