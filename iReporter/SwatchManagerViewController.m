//
//  SwatchManagerViewController.m
//  PaintProjector
//
//  Created by 胡 文杰 on 3/6/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import "SwatchManagerViewController.h"
#import "SwatchManagerTableViewCell.h"
#import "SwatchCollectionViewCell.h"
#import "UIColor+String.h"

@interface SwatchManagerViewController ()
@property(retain, nonatomic) NSArray *swatches;
@property (retain,nonatomic) NSMutableArray *filteredSwatches;

@end

@implementation SwatchManagerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.swatches = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"swatch" subdirectory:@"Swatches"];
    self.filteredSwatches = [NSMutableArray arrayWithCapacity:[self.swatches count]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Action
- (IBAction)backButtonTouchUp:(UIButton *)sender {
    [self.delegate willSetSwatchFile:nil];
}

- (IBAction)swatchChartButtonTouchUp:(SwatchChartButton *)sender {
    NSInteger index = sender.tag;
    BOOL filtered = sender.filtered;
    NSURL *url = nil;
    // 检查现在应该显示普通列表还是过滤后的列表
    if (filtered) {
        url = self.filteredSwatches[index];
    }
    else{
        url = self.swatches[index];
    }
    
    [self.delegate willSetSwatchFile:url];
}

- (IBAction)swatchChartButtonTouchDown:(UIButton *)sender {

    //交互动画
//    CGRect frame = sender.frame;
//    DebugLog(@"frame %@", NSStringFromCGRect(frame));
//    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width*2, frame.size.height*2);
//    DebugLog(@"scaled frame %@", NSStringFromCGRect(newFrame));
//    CGPoint center = sender.center;
//    [UIView animateWithDuration:1 animations:^{
//        sender.transform = CGAffineTransformMakeScale(2, 2);
//    }completion:^(BOOL finished) {
//    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"swatchManagerTableViewCell";
    SwatchManagerTableViewCell *cell = (SwatchManagerTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    // 检查现在应该显示普通列表还是过滤后的列表
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.swatchCollectionView.tag = 1;
    }
    else {
        cell.swatchCollectionView.tag = 0;
    }
    
    return cell;
}

#pragma mark - Table view delegate
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.tableView.bounds.size.height;
}

#pragma mark- UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    NSInteger count = 0;
    if (collectionView.tag == 1){
        count = self.filteredSwatches.count;
    }
    else if(collectionView.tag == 0){
        count = self.swatches.count;
    }
    
    return count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"swatchCollectionViewCell";
    SwatchCollectionViewCell *cell = (SwatchCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSArray *urls = nil;
    if (collectionView.tag == 1) {
        urls = self.filteredSwatches;
    }
    else if (collectionView.tag == 0){
        urls = self.swatches;
    }
    
    NSURL *url = [urls objectAtIndex:indexPath.row];
    NSArray *colorDatas = [NSArray arrayWithContentsOfURL:url];
    
    //对colorDatas按照百分比进行排序
    NSArray *sortedColors = [[[colorDatas sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id obj1, id obj2) {
        CGFloat percent1 = [[[(NSString*)obj1 componentsSeparatedByString:@"%"]lastObject]floatValue];
        CGFloat percent2 = [[[(NSString*)obj2 componentsSeparatedByString:@"%"]lastObject]floatValue];
        NSNumber *p1 = [NSNumber numberWithFloat:percent1];
        NSNumber *p2 = [NSNumber numberWithFloat:percent2];
        return [p1 compare:p2];
    }] reverseObjectEnumerator]allObjects];
    
    cell.swatchChartButton.swatchColors = sortedColors;
    
    //tag正负号代表是否是查询过滤表格
    cell.swatchChartButton.tag = indexPath.row;
    cell.swatchChartButton.filtered = collectionView.tag == 1;
    
    NSString *fileName = [url.pathComponents lastObject];
    NSString *swatchName = [fileName stringByDeletingPathExtension];
    cell.swatchNameLabel.text = swatchName;
    cell.swatchNameLabel.tag = indexPath.row;
    
    return cell;
}

#pragma mark- UICollectionViewDelegate
//- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
//    NSURL *url = nil;
//    // 检查现在应该显示普通列表还是过滤后的列表
//    if (collectionView.tag == 1) {
//        url = [self.filteredSwatches objectAtIndex:indexPath.row];
//    }
//    else if(collectionView.tag == 0) {
//        url = [self.swatches objectAtIndex:indexPath.row];
//    }
//    
//    [self.delegate willSetSwatchFile:url];
//}

#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // 根据搜索栏的内容和范围更新过滤后的数组。
    // 先将过滤后的数组清空。
    [self.filteredSwatches removeAllObjects];
    // 用NSPredicate来过滤数组。
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.path contains[c] %@",searchText];
    self.filteredSwatches = [NSMutableArray arrayWithArray:[self.swatches filteredArrayUsingPredicate:predicate]];
}

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // 当用户改变搜索字符串时，让列表的数据来源重新加载数据
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // 返回YES，让table view重新加载。
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    // 当用户改变搜索范围时，让列表的数据来源重新加载数据
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    // 返回YES，让table view重新加载。
    return YES;
}

@end
