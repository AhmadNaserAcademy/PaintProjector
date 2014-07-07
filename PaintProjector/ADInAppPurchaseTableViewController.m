//
//  InAppPurchaseTableViewController.m
//  PaintProjector
//
//  Created by 胡 文杰 on 2/22/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import "ADInAppPurchaseTableViewController.h"
#import "ADInAppPurchaseTableViewCell.h"
#import "ADIAPManager.h"
#import "Reachability.h"

@interface ADInAppPurchaseTableViewController ()
@property(retain, nonatomic)UIActivityIndicatorView *activityView;
@property(retain, nonatomic)UIAlertView *alertView;

@end

@implementation ADInAppPurchaseTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    DebugLogSystem(@"viewWillAppear");
    if([self.tableView numberOfSections] == 0){
        return;
    }

    if([self.tableView numberOfRowsInSection:0] == 0){
        return;
    }
    
    ADInAppPurchaseTableViewCell *cell = (ADInAppPurchaseTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    if(self.brushPreviewDelegate){
        cell.brushPreview.delegate = self.brushPreviewDelegate;
        
        //初始化brushPreview的绘制
        [cell destroyBrush];
        [cell.brushPreview tearDownGL];
        
        [cell.brushPreview setupGL];
        NSInteger iapBrushId = [self iapBrushIdFromProductFeatureIndex:self.iapProductProPackageFeatureIndex];
        [cell prepareBrushIAPBrushId:iapBrushId];
        
        cell.pageControl.currentPage = self.iapProductProPackageFeatureIndex;
    }
}

- (void)viewWillLayoutSubviews{
    DebugLogSystem(@"viewWillLayoutSubviews");
    self.view.superview.bounds = self.superViewBounds;

    if([self.tableView numberOfSections] == 0){
        return;
    }
    
    if([self.tableView numberOfRowsInSection:0] == 0){
        return;
    }
    
    ADInAppPurchaseTableViewCell *cell = (ADInAppPurchaseTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    if([cell.productFeatureCollectionView numberOfItemsInSection:0] == 0){
        return;
    }

    cell.pageControl.currentPage = self.iapProductProPackageFeatureIndex;
    CGPoint offset = cell.productFeatureCollectionView.contentOffset;
    offset.x = cell.productFeatureCollectionView.bounds.size.width * self.iapProductProPackageFeatureIndex;
    cell.productFeatureCollectionView.contentOffset = offset;
}

- (void)viewWillDisappear:(BOOL)animated{
    DebugLogSystem(@"viewWillDisappear");
    if([self.tableView numberOfSections] == 0){
        return;
    }
    
    if([self.tableView numberOfRowsInSection:0] == 0){
        return;
    }
    ADInAppPurchaseTableViewCell *cell = (ADInAppPurchaseTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    [cell destroyBrush];
    [cell.brushPreview tearDownGL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.superViewBounds = CGRectMake(0, 0, 500, 350);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionSucceeded:) name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
 
    [self reload];
}

- (void)dealloc{
    DebugLogSystem(@"dealloc");
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)transactionSucceeded:(id)arg{
    DebugLog(@"购买产品成功,刷新产品显示");
    [self.tableView reloadData];
}

- (void)reload{
    //如果应用启动时没有得到产品列表，则立即再次联网尝试获得产品列表
    if (![[ADIAPManager sharedInstance] isProductsRequested]){
        //检查是否有网络连接
        Reachability *reach = [Reachability reachabilityForInternetConnection];
        NetworkStatus netStatus = [reach currentReachabilityStatus];
        if (netStatus == NotReachable) {
            DebugLog(@"没有网络连接, 无法得到产品列表");
            self.alertView = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(@"IAPUnavailableByNoAccess", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
            [self.alertView show];
        }
        else{
            [[ADIAPManager sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
                if (success) {
                    DebugLog(@"获得产品列表成功,刷新产品显示");
                    [self.tableView reloadData];
                }
                else{
                    DebugLog(@"获得产品列表失败");
                    self.alertView = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(@"IAPUnavailableByRetreiveProductsFailure", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                    [self.alertView show];
                }
                
                //关闭Loading指示器
                if (self.activityView) {
                    [self.activityView stopAnimating];
                    [self.activityView removeFromSuperview];
                    self.activityView = nil;
                }
            }];
    
            //显示Loading指示器
            self.activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [self.tableView addSubview:self.activityView];
            self.activityView.center = CGPointMake(self.superViewBounds.size.width * 0.5, self.superViewBounds.size.height * 0.5);
            self.activityView.hidesWhenStopped = true;
            [self.activityView startAnimating];
            
            //查询超时处理
//            [self performSelector:@selector(requestProductsTimeOut:) withObject:nil afterDelay:10.0];
        }
    }
    //已经得到产品列表，直接显示
    else{
        
    }
}

- (void)requestProductsTimeOut:(id)arg{
    DebugLog(@"查询产品超时，无法得到产品列表");
    if ([[ADIAPManager sharedInstance] isRequestingProduct]) {
        //关闭Loading指示器
        if (self.activityView) {
            [self.activityView stopAnimating];
            [self.activityView removeFromSuperview];
            self.activityView = nil;
        }
        self.alertView = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(@"IAPUnavailableByRetreiveProductsFailure", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [self.alertView show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI
- (IBAction)doneButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"IAPDoneButtonTouchUp" identifier:sender];
    [self.delegate willIAPPurchaseDone];
}

- (IBAction)restoreButtonTouchUp:(UIButton *)sender {
    [RemoteLog logAction:@"IAPRestoreButtonTouchUp" identifier:sender];
    if ([[ADIAPManager sharedInstance] isDeviceJailBroken]) {
        DebugLog(@"越狱设备禁止IAP");
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(@"IAPUnavailableByJailbreakDevice", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alertView show];
    }
    else{
        if ([[ADIAPManager sharedInstance] canMakePurchases]) {
            DebugLog(@"可以进行恢复");
            Reachability *reach = [Reachability reachabilityForInternetConnection];
            NetworkStatus netStatus = [reach currentReachabilityStatus];
            if (netStatus == NotReachable) {
                DebugLog(@"没有网络连接, 无法恢复产品");
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(@"IAPUnavailableByNoAccess", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }
            else{
                [[ADIAPManager sharedInstance] restorePurchase];   
            }
        }
        else{
            DebugLog(@"设备禁止IAP");
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:NSLocalizedString(@"IAPUnavailableByDevice", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
            [alertView show];
        }
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[ADIAPManager sharedInstance] products].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"inAppPurchaseTableViewCell";
    ADInAppPurchaseTableViewCell *cell = (ADInAppPurchaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    
    SKProduct *product = [[[ADIAPManager sharedInstance] products] objectAtIndex:indexPath.row];
    
    if (!product) {
        DebugLogError(@"no product available!");
        return nil;
    }
    //产品名字
    cell.productName.text = product.localizedTitle;
    
    //产品价格
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];

    cell.buyProductButton.tag = indexPath.row;
    
    //TODO:语言显示
    if ([[ADIAPManager sharedInstance]productPurchased:product.productIdentifier]) {
        [cell.buyProductButton setTitle:NSLocalizedString(@"Purchased", nil) forState:UIControlStateNormal];
    }
    else{
        [cell.buyProductButton setTitle:formattedString forState:UIControlStateNormal];
    }

    //产品特性
    cell.productFeatures = [product.localizedDescription componentsSeparatedByString:@"."];


    
    return cell;
}

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

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 200;
//}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return self.titleView;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
//    return 66;
//}

#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [self.delegate willIAPPurchaseDone];
}

#pragma mark- InAppPurchaseTableViewCellDelegate
- (ADBrush *)willGetIAPBrushWithId:(NSInteger)brushId{
    return [self.delegate willIAPGetBrushById:brushId];
}
#pragma mark- 产品描述 IAPProductFeature
//从产品列表索引转换到笔刷索引
-(NSInteger)iapBrushIdFromProductFeatureIndex:(NSInteger)productIndex{
    return productIndex;
}
@end