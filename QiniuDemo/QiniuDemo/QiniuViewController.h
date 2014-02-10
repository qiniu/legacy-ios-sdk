//
//  QiniuViewController.h
//  QiniuDemo
//
//  Created by Qiniu Developers 2013
//

#import <UIKit/UIKit.h>
#import "../../QiniuSDK/QiniuSimpleUploader.h"

@interface QiniuViewController : UIViewController<QiniuUploadDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate>
{
    UIPopoverController *_customPopoverController;
    QiniuSimpleUploader *_uploader;
}
@property (retain, nonatomic) IBOutlet UIImageView *pictureViewer;
@property (retain, nonatomic) IBOutlet UIProgressView *progressBar;
@property (retain, nonatomic) IBOutlet UITextView *uploadStatus;
@property (retain, nonatomic) IBOutlet UIButton *uploadButton;
- (IBAction)uploadButtonPressed:(id)sender;
@end
