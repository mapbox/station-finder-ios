#import "FilterTableViewController.h"

@interface FilterTableViewController ()

@property (nonatomic, copy) NSArray *lineColors;

@end

@implementation FilterTableViewController

#pragma mark - View Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // These are the lines we support, each should be a row in the table
    self.lineColors = @[@"Blue", @"Green", @"Orange", @"Red", @"Silver", @"Yellow"];

    // Register a "Cell" identifier for a UITableViewCell
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    // Add a done button to our navigation bar
    UIBarButtonItem *doneButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(donePressed:)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
}

#pragma mark - User Interface Handlers

- (void)donePressed:(id)sender
{
    [self.delegate didUpdateLines:self.selectedLines];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lineColors.count;
}

#pragma mark - Table view delegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *lineColor = self.lineColors[indexPath.row];
    cell.textLabel.text = lineColor;
    
    BOOL shouldBeChecked = [self.selectedLines containsObject:lineColor];
    
    if (shouldBeChecked)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Select the lines to display on the map";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *lineColor = self.lineColors[indexPath.row];
    
    // See if the color is currently in the selected line colors
    BOOL isCurrentlySelected = [self.selectedLines containsObject:lineColor];
    
    // If it's currently selected, deselect it
    if (isCurrentlySelected) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.selectedLines removeObject:lineColor];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedLines addObject:lineColor];
    }
    
    // Deselect the row so it does not stay highlighted
    cell.selected = NO;
}

@end
