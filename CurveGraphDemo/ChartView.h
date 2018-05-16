//
//  ChartView.h
//  NeishaChartDemo
//
//  Created by paperclouds on 2018/5/11.
//  Copyright © 2018年 neisha. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChartView : UIView

@property (nonatomic, copy) NSArray *xDataArray; //横坐标信息数组
@property (nonatomic, copy) NSArray *yDataArray; //纵坐标信息数组
@property (nonatomic, copy) NSArray *daysArray; //天数X轴坐标位置数组
@property (nonatomic, copy) NSArray *priceArray; //价格Y轴坐标位置数组
@property (nonatomic, copy) NSArray *priceDataArray; //价格数组
@property (nonatomic, strong) NSMutableArray *dataArray; //曲线数据坐标数组

@property (nonatomic, copy) void (^didSelectPointBlock)(NSString *timeStr, NSString *moneyStr);

@end
