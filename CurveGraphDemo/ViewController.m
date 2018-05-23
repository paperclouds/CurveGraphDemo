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
    chartView.xArray = @[@1,@3,@5,@7,@15,@20,@25,@30];
    NSMutableArray *ary = [NSMutableArray arrayWithCapacity:30];
    for (int i=1;i<31 ; i++) {
        [ary addObject:[NSNumber numberWithInt:i]];
    }
    chartView.daysArray = ary;
    chartView.priceDataArray = @[@79.96,@54.03,@39.98,@32.24,@26.65,@22.72,@19.99,@19.6,@19.22,@18.86,@18.51,@18.17,@17.85,@17.69,@17.54,@16.66,@15.99,@15.74,@14.92,@14.18,@13.51,@12.98,@12.49,@12.04,@11.69,@11.36,@11.04,@10.86,@10.69,@10.52];
    NSString *firstValue = chartView.priceDataArray.firstObject;
    int maxFloat = ((firstValue.intValue/10)+1)*10;
    NSMutableArray * array = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        [array addObject:[NSString stringWithFormat:@"%d",(maxFloat/4)*i]];
    }
    chartView.yDataArray = array;
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
