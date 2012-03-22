//
//  NSDate+Utils.m
//  QBox
//
//  Created by bert yuan on 5/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSDate+Utils.h"


@implementation NSDate (NSDate_Utils)

- (NSString *)fileNameWithCurrentLocale {
    NSDateComponents *components = [[NSCalendar currentCalendar] components: NSSecondCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:self];
    return [NSString stringWithFormat:@"%d-%02d-%02d %02d.%02d.%02d", [components year], [components month], [components day], [components hour], [components minute], [components second]];
}

@end
