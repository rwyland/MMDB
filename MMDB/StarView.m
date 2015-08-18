//
//  StarView.m
//  MMDB
//
//  Created by Rob Wyland on 8/16/15.
//  Copyright (c) 2015 Org Inc. All rights reserved.
//

#import "StarView.h"

@implementation StarView

/**
 *  Since a star is an easy shape to draw, we are going to go ahead and do this programatically instead of
 *  having to include an extra Asset resource.
 */
- (void)drawRect:(CGRect)rect {
    int aSize = MIN(rect.size.width, rect.size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, aSize);
    CGFloat xCenter = rect.size.width / 2.f;
    CGFloat yCenter = rect.size.height / 2.f;
    
    float  w = aSize;
    double r = w / 2.f;
    float flip = -1.f;
    
    CGColorRef gold = [UIColor colorWithRed:1.f green:215/255.f blue:0.f alpha:1.0f].CGColor;
    CGContextSetFillColorWithColor(context, gold);
    CGColorRef stroke = [UIColor colorWithRed:1.f green:215/255.f blue:0.2f alpha:1.0f].CGColor;
    CGContextSetStrokeColorWithColor(context, stroke);
    
    double theta = 2.f * M_PI * (3.f / 5.f); // 216 degrees
    
    CGContextMoveToPoint(context, xCenter, r*flip+yCenter);
    
    for (NSUInteger i=1; i<5; i++) {
        float x = r * sin(i * theta);
        float y = r * cos(i * theta);
        CGContextAddLineToPoint(context, x+xCenter, y*flip+yCenter);
    }
    
    CGContextClosePath(context);
    CGContextFillPath(context);
    
    // Draw out the rating near the center of the star
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment                = NSTextAlignmentCenter;
    NSDictionary *attr = @{NSForegroundColorAttributeName : [UIColor blackColor],
                                   NSFontAttributeName            : [UIFont systemFontOfSize:16.f],
                                   NSParagraphStyleAttributeName  : paragraphStyle};
    [self.rating drawAtPoint:CGPointMake(xCenter-10.f, yCenter-10.f) withAttributes:attr];
}

@end
