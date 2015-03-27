//
//  StationDotsView.m
//  Station Finder
//
//  Created by Scott Newman on 2/21/15.
//  Copyright (c) 2015 Example Company. All rights reserved.
//

#import "StationDotsView.h"

@interface StationDotsView ()
@property (nonatomic, strong) NSSet *lines;
@end

@implementation StationDotsView

- (instancetype)initWithLines:(NSSet *)lines
{
    self = [super initWithFrame:CGRectMake(0, 0, 38, 25)];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.lines = lines;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // These are all the lines the station *could* support
    NSArray *lineColors = @[@"Blue", @"Green", @"Orange", @"Red", @"Silver", @"Yellow"];
    
    // These match the colors used by WMATA on their map, so let's use them to fill
    NSArray *fillColors = @[
                            [UIColor colorWithRed:0.01 green:0.56 blue:0.84 alpha:1], // Blue
                            [UIColor colorWithRed:0 green:0.68 blue:0.3 alpha:1], // Green
                            [UIColor colorWithRed:0.89 green:0.54 blue:0 alpha:1], // Orange
                            [UIColor colorWithRed:0.75 green:0.08 blue:0.22 alpha:1], // Red
                            [UIColor colorWithRed:0.64 green:0.65 blue:0.64 alpha:1], // Silver
                            [UIColor colorWithRed:0.99 green:0.85 blue:0.1 alpha:1] // Yellow
                            ];
    
    // Iterate over each of the lines and decide if we should draw a colored circle
    // (meaning this annotation supports that line) or a gray circle (meaning
    // that the station does *not* support that line
    
    for (int i=0; i<6; i++)
    {
        float left = i * 13 + 1;
        float top = 1;
        
        // The second row of dots needs adjustment
        if (i>=3) {
            left -= 39.0;
            top = 14;
        }
        
        // If the station does not support the current line, show a
        // light gray circle, otherwise fill with the line color
        
        UIColor *fillColor;
        
        if ([self.lines containsObject:lineColors[i]])
            fillColor = fillColors[i];
        else
            fillColor = [UIColor colorWithRed:0.83 green:0.83 blue:0.83 alpha:0.4];
        
        // Draw an ellipse (circle) inside of a positioned rect
        CGRect rectangle = CGRectMake(left, top, 10, 10);
        CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
        CGContextFillEllipseInRect(ctx, rectangle);
    }
    
}

@end