//
//  ViewController.m
//  CurveGraphDemo
//
//  Created by paperclouds on 2018/5/16.
//  Copyright © 2018年 hechang. All rights reserved.
//

#import "ViewController.h"
#import "ChartView.h"

#define kScreenWidth   [UIScreen mainScreen].bounds.size.width

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UILabel *priceLbl = [[UILabel alloc]initWithFrame:CGRectMake(200, 100, 100, 50)];
    [self.view addSubview:priceLbl];
    priceLbl.textAlignment = NSTextAlignmentRight;
    
    ChartView *chartView = [[ChartView alloc]initWithFrame:CGRectMake(0, 200, kScreenWidth, 135)];
    [self.view addSubview:chartView];
    chartView.xDataArray = @[@"1D",@"3D",@"5D",@"7D",@"15D",@"20D",@"25D",@"1M"]; //X轴信息
    chartView.yDataArray = @[@"0",@"5",@"10",@"15"]; //y轴信息
    chartView.daysArray = @[@1,@3,@5,@7,@15,@20,@25,@30];
    chartView.priceDataArray = @[@13.32,@7.99,@6.15,@4.99,@2.85,@2.25,@1.86,@1.57];
    chartView.didSelectPointBlock = ^(NSString *timeStr, NSString *moneyStr) {
        NSLog(@"%@ %@",timeStr,moneyStr);
        priceLbl.text = [NSString stringWithFormat:@"¥%.2f/天",moneyStr.floatValue];
    };
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
