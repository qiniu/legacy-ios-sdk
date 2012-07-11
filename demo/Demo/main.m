//
//  main.m
//  QBox
//
//  Created by bert yuan on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DPAppDelegate.h"
#include "conf.h"

int main(int argc, char *argv[])
{
    // You can init your key info here.
    
    QBOX_ACCESS_KEY = "<Please apply your access key>";
    QBOX_SECRET_KEY = "<Dont send your secret key to anyone>";
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([DPAppDelegate class]));
    }
}
