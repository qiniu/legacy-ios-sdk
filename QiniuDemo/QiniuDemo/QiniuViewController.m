//
//  QiniuViewController.m
//  QiniuDemo
//
//  Created by Qiniu Developers 2013
//

#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "QiniuViewController.h"
#import "QiniuPutPolicy.h"
#import "../../QiniuSDK/QiniuSimpleUploader.h"
#import "../../QiniuSDK/QiniuResumableUpload.h"

// NOTE: Please replace with your own accessKey/secretKey.
// You can find your keys on https://portal.qiniu.com ,
static NSString *QiniuAccessKey = @"<Please specify your access key>";
static NSString *QiniuSecretKey = @"<Please specify your secret key>";
static NSString *QiniuBucketName = @"<Please specify your bucket name>";

@interface QiniuViewController ()

@end

@implementation QiniuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    QiniuAccessKey = @"<Please specify your access key>";
    QiniuSecretKey = @"<Please specify your secret key>";
    QiniuBucketName = @"<Please specify your bucket name>";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_pictureViewer release];
    [_progressBar release];
    [_uploadStatus release];
    [_uploadButton release];
    [_customPopoverController release];
    
    [_simpleUploader release];
    [_resumableUploader release];
    [_key release];

    [_uploadMode release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setPictureViewer:nil];
    [self setProgressBar:nil];
    [self setUploadStatus:nil];
    [self setUploadButton:nil];
    if (_simpleUploader) {
        _simpleUploader.delegate = nil;
    }
    if (_resumableUploader) {
        _resumableUploader.delegate = nil;
    }
    [self setUploadMode:nil];
    [super viewDidUnload];
}
- (IBAction)uploadButtonPressed:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        imagePicker.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
            [popover presentPopoverFromRect:CGRectMake(100, 50, 200, 300)
                                     inView:self.view
                   permittedArrowDirections:UIPopoverArrowDirectionUp
                                   animated:YES];
            [_customPopoverController release];
            _customPopoverController = popover;
            popover.delegate = self;
        } else {
            [self presentModalViewController:imagePicker animated:YES];
        }
    }
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)theInfo
{
    [picker dismissModalViewControllerAnimated:YES];
    [self performSelectorInBackground:@selector(uploadContent:) withObject:theInfo];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

// Progress updated.
- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent
{
    self.progressBar.progress = percent;
    
    [self.progressBar setNeedsDisplay];
    
    NSString *message = [NSString stringWithFormat:@"Progress of uploading %@ is: %.2f%%",  filePath, percent * 100];
    //NSLog(@"%@", message);
    
    [self.uploadStatus setText:message];
}

// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)filePath ret:(NSDictionary *)ret
{
    long long fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize] longLongValue];
    int speed = 0;
    if (fileSize > 0) {
        NSTimeInterval uploadTime = [[NSDate date] timeIntervalSince1970] - _uploadStartTime;
        speed = fileSize / uploadTime;
    }
    
    NSString *hash = [ret objectForKey:@"hash"];
    NSMutableString *message = [NSMutableString stringWithFormat:@"Successfully uploaded %@ \n Hash: %@ \n File size: %lld \n Speed: %d bytes/sec \n URL: http://%@.qiniudn.com/%@",  filePath, hash, fileSize, speed, QiniuBucketName, _key];
    
    NSLog(@"%@", message);
    
    [self.uploadStatus setText:message];
}

// Upload failed.
//
// (NSError *)error:
//      ErrorDomain - QiniuSimpleUploader
//      Code - It could be a general error (< 100) or a HTTP status code (>100)
//      Message - You can use this line of code to retrieve the message: [error.userInfo objectForKey:@"error"]
- (void)uploadFailed:(NSString *)filePath error:(NSError *)error
{
    NSString *message = @"";
    
    // For first-time users, this is an easy-to-forget preparation step.
    if ([QiniuAccessKey hasPrefix:@"<Please"]) {
        message = @"Please replace kAccessKey, kSecretKey and kBucketName with proper values. These values were defined on the top of QiniuViewController.m";
    } else {
        message = [NSString stringWithFormat:@"Failed uploading %@ with error: %@",  filePath, error];
    }
    NSLog(@"%@", message);
        
    self.progressBar.progress = 0; // Reset
    [self.progressBar setNeedsDisplay];
    
    [self.uploadStatus setText:message];
}

- (void)uploadContent:(NSDictionary *)theInfo {
    
    //obtaining saving path
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss"];
    //Optionally for time zone conversions
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    NSString *timeDesc = [formatter stringFromDate:[NSDate date]];
    
    [formatter release];
    
    //extracting image from the picker and saving it
    NSString *mediaType = [theInfo objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage] || [mediaType isEqualToString:(NSString *)ALAssetTypePhoto]) {
        
        NSString *key = [NSString stringWithFormat:@"%@.jpg", timeDesc];
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:key];
        NSLog(@"Upload Path: %@", filePath);
        
        NSData *webData = UIImageJPEGRepresentation([theInfo objectForKey:UIImagePickerControllerOriginalImage], 1);
        [webData writeToFile:filePath atomically:YES];
        
        _key = [key copy];
        
        _uploadStartTime = [[NSDate date] timeIntervalSince1970];
        
        [self uploadFile:filePath bucket:QiniuBucketName key:key];
    }
}

- (NSString *)tokenWithScope:(NSString *)scope
{
    QiniuPutPolicy *policy = [[QiniuPutPolicy new] autorelease];
    policy.scope = scope;
    
    return [policy makeToken:QiniuAccessKey secretKey:QiniuSecretKey];
}

- (void)uploadFile:(NSString *)filePath bucket:(NSString *)bucket key:(NSString *)key {
    
    self.progressBar.progress = 0;
    [self.progressBar setNeedsDisplay];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:filePath]) {
        
        if (_simpleUploader) {
            [_simpleUploader release];
            _simpleUploader = nil;
        }
        if (_resumableUploader) {
            [_resumableUploader release];
            _resumableUploader = nil;
        }
        
        if ([self.uploadMode selectedSegmentIndex] == 0) {
            _simpleUploader = [[QiniuSimpleUploader alloc] initWithToken:[self tokenWithScope:bucket]];
            _simpleUploader.delegate = self;
            
            [_simpleUploader uploadFile:filePath key:key extra:nil];
        } else { // Resumable
            _resumableUploader = [[QiniuResumableUpload alloc] initWithToken:[self tokenWithScope:bucket]];
            _resumableUploader.delegate = self;
            
            [_resumableUploader uploadFile:filePath key:key bucket:bucket extraParams:nil];
        }
    }
}

@end
