//
//  ChartView.m
//  NeishaChartDemo
//
//  Created by paperclouds on 2018/5/11.
//  Copyright © 2018年 neisha. All rights reserved.
//

#import "ChartView.h"

#define P_M(x,y) CGPointMake(x, y)

#define UIColorFromRGB(rgbValue)    [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromAlphaRGB(rgbValue,a) \
[UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]

#define kScreenWidth   [UIScreen mainScreen].bounds.size.width

#define LineWidth 1 //坐标轴宽度
#define YToViewPadding 30 //Y轴到页面的边距
#define XToViewPadding 30 //X轴到页面的边距
#define FontSize 11 //坐标轴信息字体大小
#define YAxisColor 0x7f7df1 //滑杆颜色

@interface ChartView()

@property (nonatomic, assign) CGFloat xInfoSpacing; //X轴文字间距
@property (nonatomic, assign) CGFloat yInfoSpacing; //y轴文字间距
@property (nonatomic, assign)  CGFloat  maxYValue ; //y轴最大值
@property (nonatomic, strong)  CAShapeLayer *markLayerX;
@property (nonatomic, strong)  CAShapeLayer *markLayerY;
@property (nonatomic, strong)  CAShapeLayer *littleRingLayer;
@property (nonatomic, strong)  CAShapeLayer *bigRingLayer;
@property (nonatomic, strong) UILabel *priceLbl; //价格标签

@end

@implementation ChartView
{
    CGPoint _endPoint;
    CALayer *_baseLayer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.priceLbl = [[UILabel alloc]init];
        self.priceLbl.frame = CGRectMake(XToViewPadding + 10 + 12, -10, 100, 20);
        [self addSubview:self.priceLbl];
        self.priceLbl.textColor = [UIColor grayColor];
        self.priceLbl.font = [UIFont systemFontOfSize:13];
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    _yInfoSpacing = (CGRectGetHeight(self.frame) - YToViewPadding - 20) /(_yDataArray.count-1); //Y轴文字间距
    _xInfoSpacing = (CGRectGetWidth(self.frame) - XToViewPadding - 40) / 30; //X轴文字间距
    [self drawXAndYLine];
    [self drawXAndYInfo];
    [self configValueDataArray];
    [self drawGridWithDaysArray];
    [self drawBezierPathWithDataArray:_dataArray];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self drawXYLineAtMaxPointWithDataArray:_daysArray andContext:context];
}

// 绘制X、Y轴
- (void)drawXAndYLine{
     CGContextRef context = UIGraphicsGetCurrentContext(); //获取当前的图形上下文
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor); //设置X、Y轴的颜色
    CGContextSetLineWidth(context, LineWidth); //设置坐标轴宽度
    
    // 绘制Y轴
    CGContextMoveToPoint(context, YToViewPadding, 0); //Y轴起点坐标(原点在左上角)
    CGContextAddLineToPoint(context, YToViewPadding, CGRectGetHeight(self.frame)-YToViewPadding); //从Y轴起点坐标到Y轴终点坐标画线
    CGContextStrokePath(context);
    
    // 绘制X轴
    CGContextMoveToPoint(context, YToViewPadding, CGRectGetHeight(self.frame)-YToViewPadding); //X轴起点坐标
    CGContextAddLineToPoint(context, CGRectGetWidth(self.frame)-XToViewPadding, CGRectGetHeight(self.frame)-YToViewPadding); ////从X轴起点坐标到X轴终点坐标画线
    CGContextStrokePath(context);
}

// 绘制坐标轴信息
- (void)drawXAndYInfo{
    // X轴
    __weak typeof(self)weakself=self;
    [_xDataArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 设置文字相关属性
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        attributes[NSForegroundColorAttributeName] = [UIColor grayColor]; //文字颜色
        CGSize infoSize = [self getTextSizeWithText:obj fontSize:FontSize maxSize:CGSizeMake(MAXFLOAT, FontSize)]; //文字大小
    
        // 文字绘制起点
        NSString *index = weakself.daysArray[idx];
        float startPointX = XToViewPadding+(index.intValue-1)*weakself.xInfoSpacing; //横坐标
        float startPointY = CGRectGetHeight(self.frame) - YToViewPadding + (YToViewPadding - infoSize.height)/2.0; //纵坐标
        CGPoint startPoint = CGPointMake(startPointX, startPointY);
        [obj drawAtPoint:startPoint withAttributes:attributes];
        
    }];
    
    
    // Y轴
    [_yDataArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 设置文字相关属性
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        attributes[NSForegroundColorAttributeName] = [UIColor grayColor]; //文字颜色
        CGSize infoSize = [self getTextSizeWithText:obj fontSize:FontSize maxSize:CGSizeMake(MAXFLOAT, FontSize)]; //文字大小
        
        // 文字绘制起点
        float startPointX = XToViewPadding/2-infoSize.width/2;
        float startPointY = CGRectGetHeight(self.frame) - YToViewPadding - idx*weakself.yInfoSpacing-10;
        CGPoint startPoint = CGPointMake(startPointX, startPointY);
        [obj drawAtPoint:startPoint withAttributes:attributes];
    }];
}

// 将数据转换为坐标
- (void)configValueDataArray{
    self.dataArray = [NSMutableArray array];
    for (NSInteger i = 0; i < _priceDataArray.count; i++) {
        NSString *index = self.daysArray[i];
        float startPointX = XToViewPadding+(index.intValue-1)*self.xInfoSpacing+10; //横坐标
        NSString *price = _priceDataArray[i];
        float startPointY = 20+(CGRectGetHeight(self.frame)-YToViewPadding-20)*(15-price.floatValue)/15;
        CGPoint p = P_M(startPointX, startPointY);
        NSValue *value = [NSValue valueWithCGPoint:p];
        [_dataArray addObject:value];
//        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(p.x-1, p.y-1, 3, 3) cornerRadius:5];
//        CAShapeLayer *layer = [CAShapeLayer layer];
//        layer.strokeColor = [UIColor yellowColor].CGColor;
//        layer.fillColor = [UIColor yellowColor].CGColor;
//        layer.path = path.CGPath;
//        [self.layer addSublayer:layer];
    }
}

// 绘制背景网格
- (void)drawGridWithDaysArray{
    for (NSInteger i = 1; i < _dataArray.count-1; i++) {
        NSValue *value = _dataArray[i];
        CGPoint p = value.CGPointValue;
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:P_M(p.x, CGRectGetHeight(self.frame)-YToViewPadding)];
        [path addLineToPoint:P_M(p.x, 0)];
        
        CAShapeLayer *shadeLayer = [CAShapeLayer new];
        shadeLayer.path = path.CGPath;
        shadeLayer.strokeColor = UIColorFromRGB(0xf2f2f2).CGColor;
        shadeLayer.lineWidth = 0.5;
        [self.layer addSublayer:shadeLayer];
    }
}

// 开始画线
- (void)drawBezierPathWithDataArray:(NSMutableArray *)dataArray{
    UIBezierPath *path = [UIBezierPath bezierPath];
    NSValue *firstPointValue = [NSValue valueWithCGPoint:CGPointMake(XToViewPadding, (CGRectGetHeight(self.frame) - YToViewPadding) / 2)];
    [dataArray insertObject:firstPointValue atIndex:0];
    NSValue *endPointValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetWidth(self.frame), (CGRectGetHeight(self.frame) - YToViewPadding) / 2)];
    [dataArray addObject:endPointValue];
    NSLog(@"%@",dataArray);
    for (NSInteger i = 0; i < self.priceDataArray.count-1; i++) {
        CGPoint p1 = [[dataArray objectAtIndex:i] CGPointValue];
        CGPoint p2 = [[dataArray objectAtIndex:i+1] CGPointValue];
        CGPoint p3 = [[dataArray objectAtIndex:i+2] CGPointValue];
        CGPoint p4 = [[dataArray objectAtIndex:i+3] CGPointValue];
        if (i == 0) {
            [path moveToPoint:p2];
            [self ponitToData:p2];
        }
        [self getControlPointx0:p1.x andy0:p1.y x1:p2.x andy1:p2.y x2:p3.x andy2:p3.y x3:p4.x andy3:p4.y path:path];
    }
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame)-XToViewPadding, CGRectGetHeight(self.frame)-YToViewPadding);
    gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    gradientLayer.endPoint = CGPointMake(0.5, 1);
    gradientLayer.cornerRadius = 5;
    gradientLayer.masksToBounds = YES;
    gradientLayer.colors = @[(__bridge id)UIColorFromRGB(0x7571ff).CGColor,(__bridge id)UIColorFromRGB(0x679eff).CGColor,(__bridge id)UIColorFromRGB(0x4ccaff).CGColor];
    gradientLayer.locations = @[@0.4,@0.7];
    
    CAShapeLayer *shadeLayer = [CAShapeLayer new];
    shadeLayer.path = path.CGPath;
    shadeLayer.lineWidth = 5;
    shadeLayer.strokeColor = [UIColor blueColor].CGColor;
    shadeLayer.lineCap = kCALineCapButt;
    shadeLayer.fillColor = [UIColor clearColor].CGColor;
    
    gradientLayer.mask = shadeLayer;
    [self.layer addSublayer:gradientLayer];
    
    [self addGradientLayer];
    
}

// 渐变图层
-(void)addGradientLayer{
    UIBezierPath *path = [UIBezierPath bezierPath];
    NSValue *value = _dataArray[1];
    CGPoint p = value.CGPointValue;
    
    for (NSInteger i = 0; i < self.priceDataArray.count-1; i++) {
        CGPoint p1 = [[_dataArray objectAtIndex:i] CGPointValue];
        CGPoint p2 = [[_dataArray objectAtIndex:i+1] CGPointValue];
        CGPoint p3 = [[_dataArray objectAtIndex:i+2] CGPointValue];
        CGPoint p4 = [[_dataArray objectAtIndex:i+3] CGPointValue];
        if (i == 0) {
            [path moveToPoint:CGPointMake(p2.x, p2.y+1.5)];
        }
        [self getControlPointx0:p1.x andy0:p1.y+1.5 x1:p2.x andy1:p2.y+1.5 x2:p3.x andy2:p3.y+1.5 x3:p4.x andy3:p4.y+1.5 path:path];
        if (i == _dataArray.count - 2) {
            _endPoint = CGPointMake(p2.x, p2.y+1.5);
            [path moveToPoint:_endPoint];
        }
    }
    
    for (NSInteger i = 0; i < self.dataArray.count; i++) {
        CGPoint p1 = [[_dataArray objectAtIndex:i] CGPointValue];
        if (i == 0) {
            [path moveToPoint:CGPointMake(p1.x, p1.y+1.5)];
        }
        if (i == _dataArray.count - 2) {
            _endPoint = CGPointMake(p1.x, p1.y+1.5);
            [path moveToPoint:_endPoint];
        }
    }
    
    [path addLineToPoint:CGPointMake(_endPoint.x, CGRectGetHeight(self.frame)-YToViewPadding)];
    [path addLineToPoint:CGPointMake(p.x, CGRectGetHeight(self.frame)-YToViewPadding)];
    [path addLineToPoint:CGPointMake(p.x, p.y+1.5)];
    
    CAShapeLayer *shadeLayer = [CAShapeLayer new];
    shadeLayer.path = path.CGPath;
    shadeLayer.strokeColor = [UIColor clearColor].CGColor;
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame)-XToViewPadding, CGRectGetHeight(self.frame)-YToViewPadding);
    gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    gradientLayer.endPoint = CGPointMake(0.5, 1);
    gradientLayer.cornerRadius = 5;
    gradientLayer.masksToBounds = YES;
    gradientLayer.colors = @[(__bridge id)UIColorFromAlphaRGB(0xbab7fe, 0.2).CGColor,(__bridge id)UIColorFromAlphaRGB(0x8ec0ff,0.2).CGColor,(__bridge id)[UIColor colorWithWhite:1 alpha:0.2].CGColor];
    gradientLayer.locations = @[@0.4,@0.6];
    if (_baseLayer) {
        [_baseLayer removeFromSuperlayer];
    }//需要删除原来的
    _baseLayer = [CALayer layer];
    [_baseLayer addSublayer:gradientLayer];
    [_baseLayer setMask:shadeLayer];
    [self.layer addSublayer:_baseLayer];

    CABasicAnimation *anmio = [CABasicAnimation animation];
    anmio.keyPath = @"bounds";
    anmio.duration = 2.0f;
    anmio.toValue = [NSValue valueWithCGRect:CGRectMake(5, 0, 2*_endPoint.x, CGRectGetHeight(self.frame)-YToViewPadding)];
    anmio.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anmio.fillMode = kCAFillModeForwards;
    anmio.autoreverses = NO;
    anmio.removedOnCompletion = NO;
    [gradientLayer addAnimation:anmio forKey:@"bounds"];
}

- (void)getControlPointx0:(CGFloat)x0 andy0:(CGFloat)y0
                       x1:(CGFloat)x1 andy1:(CGFloat)y1
                       x2:(CGFloat)x2 andy2:(CGFloat)y2
                       x3:(CGFloat)x3 andy3:(CGFloat)y3
                     path:(UIBezierPath*) path{
    CGFloat smooth_value = 0.6;
    CGFloat ctrl1_x;
    CGFloat ctrl1_y;
    CGFloat ctrl2_x;
    CGFloat ctrl2_y;
    CGFloat xc1 = (x0 + x1) /2.0;
    CGFloat yc1 = (y0 + y1) /2.0;
    CGFloat xc2 = (x1 + x2) /2.0;
    CGFloat yc2 = (y1 + y2) /2.0;
    CGFloat xc3 = (x2 + x3) /2.0;
    CGFloat yc3 = (y2 + y3) /2.0;
    CGFloat len1 = sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0));
    CGFloat len2 = sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1));
    CGFloat len3 = sqrt((x3-x2) * (x3-x2) + (y3-y2) * (y3-y2));
    CGFloat k1 = len1 / (len1 + len2);
    CGFloat k2 = len2 / (len2 + len3);
    CGFloat xm1 = xc1 + (xc2 - xc1) * k1;
    CGFloat ym1 = yc1 + (yc2 - yc1) * k1;
    CGFloat xm2 = xc2 + (xc3 - xc2) * k2;
    CGFloat ym2 = yc2 + (yc3 - yc2) * k2;
    ctrl1_x = xm1 + (xc2 - xm1) * smooth_value + x1 - xm1;
    ctrl1_y = ym1 + (yc2 - ym1) * smooth_value + y1 - ym1;
    ctrl2_x = xm2 + (xc2 - xm2) * smooth_value + x2 - xm2;
    ctrl2_y = ym2 + (yc2 - ym2) * smooth_value + y2 - ym2;
    [path addCurveToPoint:CGPointMake(x2, y2) controlPoint1:CGPointMake(ctrl1_x, ctrl1_y) controlPoint2:CGPointMake(ctrl2_x, ctrl2_y)];
}

// 绘制十字线
- (void)drawXYLineAtMaxPointWithDataArray:(NSArray *)dataArray andContext:(CGContextRef)context{
    
    CGFloat markMaxL = CGFLOAT_MAX;
    CGFloat markMaxX = CGFLOAT_MAX;
    for (NSInteger i = 0; i< dataArray.count; i++) {
        
        NSValue *value = dataArray[i];
        CGPoint p = value.CGPointValue;
        
        if (p.y < markMaxL) {
            markMaxL = p.y;
            markMaxX = p.x;
        }
        
    }    
    
    UIBezierPath *linePath1 = [UIBezierPath bezierPath];
    // 起点
    [linePath1 moveToPoint:P_M(XToViewPadding+10, 0)];
    [linePath1 addLineToPoint:P_M(XToViewPadding+10,CGRectGetHeight(self.frame) - YToViewPadding)];
    
    _markLayerY = [CAShapeLayer layer];
    _markLayerY.path = linePath1.CGPath;
    _markLayerY.strokeColor = UIColorFromRGB(YAxisColor).CGColor;
    _markLayerY.lineWidth = 1;
    
    [self.layer addSublayer:_markLayerY];
    
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:P_M(XToViewPadding+10, 0) radius:2.5 startAngle:0.0 endAngle:180.0 clockwise:YES];
    
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 addArcWithCenter:P_M(XToViewPadding+10, 0) radius:6 startAngle:0.0 endAngle:180.0 clockwise:YES];
    
    // 大圆环
    _bigRingLayer = [CAShapeLayer layer];
    _bigRingLayer.path = path1.CGPath;
    _bigRingLayer.strokeColor = UIColorFromRGB(YAxisColor).CGColor;
    _bigRingLayer.lineWidth = 0.5;
    _bigRingLayer.fillColor = [UIColor whiteColor].CGColor;
    
    [self.layer insertSublayer:_bigRingLayer above:_markLayerY];
    
    // 小圆环
    _littleRingLayer = [CAShapeLayer layer];
    _littleRingLayer.path = path.CGPath;
    _littleRingLayer.strokeColor = UIColorFromRGB(YAxisColor).CGColor;
    _littleRingLayer.lineWidth = 0.5;
    _littleRingLayer.fillColor = [UIColor whiteColor].CGColor;
    
    [self.layer insertSublayer:_littleRingLayer above:_bigRingLayer];
}

// 点击曲线对应某点
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:self]; //返回触摸点在视图中的当前坐标
    CGFloat touchX = point.x;
    
    CGFloat touchY = point.y;
    
    if (touchX < XToViewPadding + 10 || touchX > CGRectGetWidth(self.frame)-XToViewPadding - 10 || touchY > CGRectGetHeight(self.frame) - YToViewPadding) {
        return;
    }
    
    CGPoint intersectionPoint;
    for (NSInteger i = 0; i < self.dataArray.count; i++) {
        
        if (i + 1 > self.dataArray.count - 1) {  //5
            break;
        }
        
        NSValue *valueA = self.dataArray[i];//4
        CGPoint A = valueA.CGPointValue;
        
        NSValue *valueB = self.dataArray[i + 1];//3
        
        CGPoint B = valueB.CGPointValue;
        //判处不在触摸点范围内的线段
        if (touchX < A.x  || touchX > B.x) {
            continue;
        }
        
        //AB 为数组中取得的线段
        //获得交点
        CGPoint p = [self twoLineWithFistLine:P_M(A.x, -A.y) :P_M(B.x, -B.y) withSecondLine:P_M(touchX, 0.0) :P_M(touchX, -1000.0)];

        intersectionPoint = P_M(p.x, - p.y);

    }

    [self ponitToData:CGPointMake(intersectionPoint.x, intersectionPoint.y)];

//    //横线
//    UIBezierPath *linePath = [UIBezierPath bezierPath];
//
//    [linePath moveToPoint:P_M(XToViewPadding,intersectionPoint.y)];
//
//    [linePath addLineToPoint:P_M(XToViewPadding +CGRectGetWidth(self.frame)-XToViewPadding*2, intersectionPoint.y)];
//
//    self.markLayerX.path = linePath.CGPath;

    //竖线
    UIBezierPath *linePath1 = [UIBezierPath bezierPath];

    [linePath1 moveToPoint:P_M(intersectionPoint.x ,0)];

    [linePath1 addLineToPoint:P_M(intersectionPoint.x, CGRectGetHeight(self.frame) - YToViewPadding)];
    self.markLayerY.path = linePath1.CGPath;
    
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 addArcWithCenter:P_M(intersectionPoint.x, 0) radius:6 startAngle:0.0 endAngle:180.0 clockwise:YES];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:P_M(intersectionPoint.x, 0) radius:2.5 startAngle:0.0 endAngle:180.0 clockwise:YES];

    _bigRingLayer.path = path1.CGPath;
    _littleRingLayer.path = path.CGPath;
    
    self.priceLbl.frame = CGRectMake(intersectionPoint.x + 12, -10, 100, 20);
    
    if (intersectionPoint.x + 12 + 100 > kScreenWidth) {
        self.priceLbl.frame = CGRectMake(intersectionPoint.x - 12 - 80, -10, 100, 20);
    }
}

// 拖动曲线对应某点
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:self]; //返回触摸点在视图中的当前坐标
    CGFloat touchX = point.x;
    CGFloat touchY = point.y;
    
    if (touchX < XToViewPadding + 10 || touchX > CGRectGetWidth(self.frame)-XToViewPadding - 10 || touchY > CGRectGetHeight(self.frame) - YToViewPadding) {
        return;
    }
    
    CGPoint intersectionPoint;
    
    for (NSInteger i = 0; i < _dataArray.count; i++) {
        if (i + 1 > _dataArray.count - 1) {  //5
            break;
        }
        
        NSValue *valueA = _dataArray[i];
        CGPoint A = valueA.CGPointValue;
        
        NSValue *valueB = _dataArray[i + 1];
        
        CGPoint B = valueB.CGPointValue;
        
        if (touchX < A.x  || touchX > B.x) {
            continue;
        }
        
        CGPoint p = [self twoLineWithFistLine:P_M(A.x, -A.y) :P_M(B.x, -B.y) withSecondLine:P_M(touchX, 0.0) :P_M(touchX, -1000.0)];
        
        intersectionPoint = P_M(p.x, - p.y);
        
    }
    
    [self ponitToData:CGPointMake(intersectionPoint.x, intersectionPoint.y)];
    
//    横线
//    UIBezierPath *linePath = [UIBezierPath bezierPath];
//
//    [linePath moveToPoint:P_M(XToViewPadding,intersectionPoint.y)];
//
//    [linePath addLineToPoint:P_M(XToViewPadding + CGRectGetWidth(self.frame) - XToViewPadding * 2, intersectionPoint.y)];
//
//    self.markLayerX.path = linePath.CGPath;
    UIBezierPath *linePath1 = [UIBezierPath bezierPath];
    
    [linePath1 moveToPoint:P_M(intersectionPoint.x , 0)];
    
    [linePath1 addLineToPoint:P_M(intersectionPoint.x, CGRectGetHeight(self.frame) - YToViewPadding)];
    self.markLayerY.path = linePath1.CGPath;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:P_M(intersectionPoint.x, 0) radius:2.5 startAngle:0.0 endAngle:180.0 clockwise:YES];
    
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 addArcWithCenter:P_M(intersectionPoint.x, 0) radius:6 startAngle:0.0 endAngle:180.0 clockwise:YES];
    
    _littleRingLayer.path = path.CGPath;
    _bigRingLayer.path = path1.CGPath;
    
    self.priceLbl.frame = CGRectMake(intersectionPoint.x + 12, -10, 100, 20);
    if (intersectionPoint.x + 12 + 100 > kScreenWidth) {
        self.priceLbl.frame = CGRectMake(intersectionPoint.x - 12 - 80, -10, 100, 20);
    }
}

- (CGPoint)twoLineWithFistLine:(CGPoint)a :(CGPoint)b withSecondLine:(CGPoint)c :(CGPoint)d {
    CGFloat x1 = a.x, y1 = a.y, x2 = b.x, y2 = b.y;
    
    CGFloat x3 = c.x, y3 = c.y, x4 = d.x, y4 = d.y;
    CGFloat x = ((x1 - x2) * (x3 * y4 - x4 * y3) - (x3 - x4) * (x1 * y2 - x2 * y1))
    / ((x3 - x4) * (y1 - y2) - (x1 - x2) * (y3 - y4));
    
    CGFloat y = ((y1 - y2) * (x3 * y4 - x4 * y3) - (x1 * y2 - x2 * y1) * (y3 - y4))
    / ((y1 - y2) * (x3 - x4) - (x1 - x2) * (y3 - y4));
    
    return P_M(x, y);
}

#pragma mark  将坐标 转换为数据
-(void)ponitToData:(CGPoint) p{
    
    _maxYValue = [[self.yDataArray valueForKeyPath:@"@max.floatValue"] floatValue];
    
    CGFloat x  =  p.x - XToViewPadding;
    CGFloat y = p.y - YToViewPadding;
    
    NSInteger time = x / (CGRectGetWidth(self.frame) - XToViewPadding * 2) * 30 + 1;
    CGFloat price = (CGRectGetHeight(self.frame) - YToViewPadding - y) / (CGRectGetHeight(self.frame) - YToViewPadding) * 15;
    
    NSString *timeStr= [NSString stringWithFormat:@"%ld天",time];
    NSString *priceStr = [NSString stringWithFormat:@"%f",price];
    
    self.priceLbl.text = [NSString stringWithFormat:@"%@(租赁期)",timeStr];

    self.didSelectPointBlock(timeStr, priceStr);
    
}


// 根据文字内容设置文字大小
- (CGSize)getTextSizeWithText:(NSString *)text fontSize:(CGFloat)fontSize maxSize:(CGSize)maxSize{
    CGSize size = CGSizeZero;
    if(text.length > 0){
        size = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]} context:nil].size;
    }
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

@end
