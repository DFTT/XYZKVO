//
//  XRootViewController.m
//  XYZKVO
//
//  Created by dadadongl on 2025/10/27.
//

#import "XRootViewController.h"
#import "ViewController.h"
@interface XRootViewController ()

@end

@implementation XRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(100, 300, 100, 100);
    btn.backgroundColor = UIColor.lightGrayColor;
    [btn setTitle:@"点我push" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(push) forControlEvents:UIControlEventTouchUpInside];
}
- (void)push {
    ViewController *vc =  [[ViewController alloc] init];
    [self.navigationController pushViewController:vc animated:true];
}

@end
