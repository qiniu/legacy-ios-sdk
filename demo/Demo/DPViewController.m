//
//  DPViewController.m
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DPViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSDate+Utils.h"
#import "QBoxRS.h"
#import "Constants.h"


@implementation DPViewController
@synthesize chooseButton;
@synthesize activityIndicator;
@synthesize resultTextView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    activityIndicator.hidden = YES;
}

- (void)viewDidUnload
{
    [self setResultTextView:nil];
    [self setActivityIndicator:nil];
    [self setChooseButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc {
    [resultTextView release];
    [activityIndicator release];
    [chooseButton release];
    [super dealloc];
}


- (IBAction)didChoosePhotoAndUpload:(id)sender {
//    resultTextView.text = @"hello, text";
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		imagePicker.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        
        [self presentModalViewController:imagePicker animated:YES];
    }
    [imagePicker release];

}


- (void)uploadResourceWithInfo:(NSDictionary *)info {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    //obtaining saving path
    NSString *timeDesc = [[NSDate date] fileNameWithCurrentLocale];
    NSString *fileName = nil;
    NSString *localPath = nil;
    
    BOOL compress = YES;
    NSNumber *compressValue = [info objectForKey:@"compress"];
    if (compressValue != nil) {
        compress = compressValue.boolValue;
    }
    
    //extracting image from the picker and saving it
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage] || [mediaType isEqualToString:(NSString *)ALAssetTypePhoto]) {
        fileName = [NSString stringWithFormat:@"%@%@", timeDesc, @".jpg"];
        localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        
        NSData *webData = UIImageJPEGRepresentation([info objectForKey:UIImagePickerControllerOriginalImage], 0.6);
        [webData writeToFile:localPath atomically:YES];
    } 

    NSString *resultStr = nil;
    if (localPath != nil && [manager fileExistsAtPath:localPath]) {
        NSLog(@"upload path:%@", localPath);
        int result = [QBoxRS putFileWithUrl:kPutURL 
                                  tableName:kTableName 
                                        key:kKey 
                                   mimeType:@"image/jpeg" 
                                   filePath:localPath
                                 customMeta:kCustomMeta 
                             callbackParams:kCallbackParams];
        resultStr = [NSString stringWithFormat:@"returned status code:%d", result];
    } else {
        resultStr = @"invalid file";
    }
    [self.resultTextView performSelectorOnMainThread:@selector(setText:) 
                                          withObject:resultStr
                                       waitUntilDone:NO];
    
    [self performSelectorOnMainThread:@selector(stop) withObject:nil waitUntilDone:NO];
    [pool release];
}


#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissModalViewControllerAnimated:YES];
    [self performSelectorInBackground:@selector(uploadResourceWithInfo:) withObject:info];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissModalViewControllerAnimated:YES];
}

- (void)start {
    activityIndicator.hidden = NO;
    [activityIndicator startAnimating];
    chooseButton.enabled = NO;
    resultTextView.text = @"";
}

- (void)stop {
    [activityIndicator stopAnimating];
    activityIndicator.hidden = YES;
    chooseButton.enabled = YES;
}

@end
