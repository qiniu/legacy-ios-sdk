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
    QBOX_ACCESS_KEY = "RLT1NBD08g3kih5-0v8Yi6nX6cBhesa2Dju4P7mT";
    QBOX_SECRET_KEY = "k6uZoSDAdKBXQcNYG3UOm4bP3spDVkTg-9hWHIKm";
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([DPAppDelegate class]));
    }
}
