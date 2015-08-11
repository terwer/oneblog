//
//  BrowserViewController.m
//  OneblogiOS
//
//  Created by Terwer Green on 15/7/29.
//  Copyright (c) 2015年 Terwer Green. All rights reserved.
//

#import "BrowserViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD.h>
#import "Utils.h"

@interface BrowserViewController ()<UIWebViewDelegate, UIScrollViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIWebView *detailsView;
@property (nonatomic, strong) MBProgressHUD *HUD;

@end

@implementation BrowserViewController

@synthesize url=_url,pageTitle=_pageTitle;

-(instancetype)initWithURL:(NSURL *)url andTitle:(NSString *)pageTitle {
    if (self = [super init]) {
        _url = url;
        _pageTitle = pageTitle ;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(returnBack)];
    //设置网页标题
    self.navigationItem.title = _pageTitle;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"分享" style:UIBarButtonItemStylePlain target:self action:@selector(showShare:)];
    
    NSLog(@"即将访问:%@ 网页标题：%@",_url,_pageTitle);
    
    _detailsView = [[UIWebView alloc]initWithFrame:CGRectMake(0.0f,0.0f,self.view.frame.size.width, self.view.frame.size.height)];
    _detailsView.delegate = self;
    _detailsView.scrollView.delegate = self;
    _detailsView.scrollView.bounces = NO;
    _detailsView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //下面两行代码可以设置UIWebView的背景
    [_detailsView setBackgroundColor:[UIColor themeColor]];
    [_detailsView setOpaque:NO];
    
    [self.view addSubview:_detailsView];
    
    //加载数据
    [self fetchDetails];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  返回
 */
-(void)returnBack{
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 * 使用Safari打开网页
 *
 *  @param sender 当前按钮
 */
-(void)showShare:(id)sender{
    UIAlertController *confirmCtl = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"是否使用Safari打开网页？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:_url]; //调用Safari打开网页
    }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:nil];
    [confirmCtl addAction:yesAction];
    [confirmCtl addAction:noAction];
    [self presentViewController:confirmCtl animated:YES completion:nil];
    NSLog(@"分享：%@",_url);
}


/**
 *  访问网页
 */
- (void)fetchDetails
{
    // 添加等待动画
    _HUD = [Utils createHUD];
    _HUD.detailsLabelText = @"网页加载中";
    _HUD.userInteractionEnabled = NO;
    
    NSLog(@"fetch details");
    
    
    NSString *requestURL=[_url absoluteString];
    //requestURL = @"https://www.baidu.com";//测试https
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //设置返回HTML
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //是否允许无效证书（也就是自建的证书），默认为NO
    manager.securityPolicy.allowInvalidCertificates = YES;
    [manager GET:requestURL parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSString *html = operation.responseString;
             NSString *markedString = html;
             if (![html hasPrefix:@"<!DOCTYPE html>"]) {
                 markedString = [Utils markdownToHtml:html];
             }
             [_detailsView loadHTMLString:markedString baseURL:nil];
             //NSLog(@"获取到的数据为：%@",html);
             //隐藏加载状态
             [_HUD hide:YES afterDelay:1];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"发生错误！%@",error);
             _HUD.mode = MBProgressHUDModeCustomView;
             _HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
             NSString *errorMesage =  [NSString stringWithFormat:@"网络异常，加载详情失败:%@",[error localizedDescription]];
             _HUD.labelText = errorMesage;
             NSLog(@"%@",errorMesage);
             [_HUD hide:YES afterDelay:1];
         }];
}

@end
