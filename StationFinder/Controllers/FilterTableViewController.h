//
//  FilterTableViewController.h
//  Station Finder
//
//  Created by Scott Newman on 3/6/15.
//  Copyright (c) 2015 Example Company. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StationFilterDelegate
- (void)didUpdateLines:(NSMutableSet *)selectedLines;
@end

@interface FilterTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableSet *selectedLines;
@property (nonatomic, weak) id<StationFilterDelegate> delegate;

@end
