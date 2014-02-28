//
//  QiniuDemoViewController.m
//  QiniuDemo
//
//  Created by ltz on 14-2-28.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import "QiniuDemoViewController.h"

@interface QiniuDemoViewController ()

@property (weak, nonatomic) IBOutlet UITextField *downloadUrl;

@property (strong, nonatomic) IBOutlet UIView *progress;
@property (weak, nonatomic) IBOutlet UITextView *msg;

@end

@implementation QiniuDemoViewController

- (IBAction)resumeUpload:(id)sender {
    if (self.extra != nil) {
        [self.rUploader uploadFile:self.filePath key:self.lastResumableKey extra:self.extra];
    }
}

- (IBAction)stopResumableUpload:(id)sender {
    if (self.extra != nil) {
        [self.extra cancelTasks];
    }
}


- (IBAction)resumableUpload:(id)sender {
    
    self.extra = [QiniuRioPutExtra extraWithParams:[NSDictionary dictionaryWithObject:@"haha" forKey:@"x:cus"]];
    self.lastResumableKey = [NSString stringWithFormat:@"test-%@", [self timeString]];
    [self.rUploader uploadFile:self.filePath key: self.lastResumableKey extra:self.extra];
}

- (IBAction)simpleUpload:(id)sender {

    [self.sUploader uploadFile:_filePath key:[NSString stringWithFormat:@"test-%@.png", [self timeString]] extra:nil];
}

- (IBAction)download:(id)sender {
    
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self timeString]];
    NSLog(@"%@", self.filePath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.filePath])
    {
        self.msg.text = [@"start download\n" stringByAppendingString:self.msg.text];
        NSURL *url = [NSURL URLWithString:self.downloadUrl.text];
        NSData *data = [NSData dataWithContentsOfURL:url];
        [data writeToFile:self.filePath atomically:TRUE];
    }
    NSString *msg = [NSString stringWithFormat:@"Download %@ success\n", self.downloadUrl.text];
    self.msg.text = [msg stringByAppendingString:self.msg.text];
}

// Upload progress
- (void)uploadProgressUpdated:(NSString *)theFilePath percent:(float)percent
{
    NSString *progressStr = [NSString stringWithFormat:@"Progress Updated: - %f\n", percent];
    
    self.msg.text = [progressStr stringByAppendingString:self.msg.text];
}

- (void)uploadSucceeded:(NSString *)theFilePath ret:(NSDictionary *)ret
{
    NSString *succeedMsg = [NSString stringWithFormat:@"Upload Succeeded: - Ret: %@\n", ret];
    
    self.msg.text = [succeedMsg stringByAppendingString:self.msg.text];
}

// Upload failed
- (void)uploadFailed:(NSString *)theFilePath error:(NSError *)error
{
    NSString *failMsg = [NSString stringWithFormat:@"Upload Failed: %@  - Reason: %@", theFilePath, error];
    
    self.msg.text = [failMsg stringByAppendingString:self.msg.text];
}

- (void)setProgressPercent:(float)percent
{
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (NSString *) timeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: @"yyyy-MM-dd-HH-mm-ss-zzz"];
    return [formatter stringFromDate:[NSDate date]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.msg.text = @"OK, let's start\nPlease download first";
    self.msg.scrollEnabled = YES;
    self.msg.editable = NO;
    
    self.token = @"6UOyH0xzsnOF-uKmsHgpi7AhGWdfvI8glyYV3uPg:m-8jeXMWC-4kstLEHEMCfZAZnWc=:eyJkZWFkbGluZSI6MTQyNDY4ODYxOCwic2NvcGUiOiJ0ZXN0MzY5In0=";
    
    self.sUploader = [QiniuSimpleUploader uploaderWithToken:self.token];
    self.sUploader.delegate = self;
    
    self.rUploader = [[QiniuResumableUploader alloc] initWithToken:self.token];
    self.rUploader.delegate = self;
    
    self.downloadUrl.delegate = self;
    
    //self.downloadUrl.text = @"http://127.0.0.1:9200/ori.mp4";
    self.downloadUrl.text = @"http://qiniuphotos.qiniudn.com/gogopher.jpg";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
