//
//  StarView.swift
//  MMDB Swift
//
//  Created by Rob W on 12/11/15.
//  Copyright © 2015 Org Inc. All rights reserved.
//

import UIKit

class StarView: UIView {
  
  var rating: String?

  /**
   *  Since a star is an easy shape to draw, we are going to go ahead and do this programatically instead of
   *  having to include an extra Asset resource.
   */
  override func drawRect(rect: CGRect) {
    let aSize: CGFloat = min(rect.width, rect.height)
    let context: CGContextRef? = UIGraphicsGetCurrentContext()
    CGContextSetLineWidth(context, aSize)
    let xCenter: CGFloat = rect.width / 2.0
    let yCenter: CGFloat = rect.height / 2.0
    
    let w: CGFloat = aSize
    let r: CGFloat = w / 2.0
    let flip: CGFloat = -1.0
    
    let gold: CGColorRef = UIColor(red: 1, green: 215/255, blue: 0, alpha: 1).CGColor
    CGContextSetFillColorWithColor(context, gold)
    let stroke: CGColorRef = UIColor(red: 1, green: 215/255, blue: 0.2, alpha: 1).CGColor
    CGContextSetStrokeColorWithColor(context, stroke)
    
    let theta: CGFloat = 2.0 * CGFloat(M_PI) * (3.0 / 5.0) // 216 degrees
    
    CGContextMoveToPoint(context, xCenter, r*flip+yCenter);
    
    for i in 0..<5 {
      let x = r * sin(CGFloat(i) * theta)
      let y = r * cos(CGFloat(i) * theta)
      CGContextAddLineToPoint(context, x+xCenter, y*flip+yCenter)
    }
    
    CGContextClosePath(context)
    CGContextFillPath(context)
    
    // Draw out the rating near the center of the star
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .Center
    let attr: Dictionary = [NSForegroundColorAttributeName : UIColor.blackColor(),
                            NSFontAttributeName            : UIFont.systemFontOfSize(16),
                            NSParagraphStyleAttributeName  : paragraphStyle]
    self.rating?.drawAtPoint(CGPointMake(xCenter-10, yCenter-10), withAttributes:attr)
  }
}