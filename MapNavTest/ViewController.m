//
//  ViewController.m
//  MapNavTest
//
//  Created by Dry on 16/9/1.
//  Copyright © 2016年 Dry. All rights reserved.
//

#import "ViewController.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

@interface ViewController ()<MAMapViewDelegate,AMapSearchDelegate>
{
    UIImageView *centerAnnotaionView;
}
@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) AMapSearchAPI *searchAPI;

@property (nonatomic) CLLocation *currentLocation;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ViewController


/*使用说明：
 *1、项目使用需进行二次封装
 *2、用前请配置高德地图AppKey
 *
 */


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [self setUpUI];
}

- (void)setUpUI {
    [self creatMapView];

    [self setUpCenterAnnotationView];
}

- (void)creatMapView {
    _mapView = [[MAMapView alloc]initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    _mapView.showsCompass = NO;
    _mapView.showsScale = NO;
    _mapView.rotateEnabled = NO;
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    _mapView.customizeUserLocationAccuracyCircleRepresentation = YES;
    [_mapView setZoomLevel:15.1 animated:NO];
    [self.view addSubview:_mapView];
}

- (void)setUpCenterAnnotationView {
    //添加地图中间图标
    UIImage *image = [UIImage imageNamed:@"position"];
    
    float origin_X = (self.mapView.frame.size.width - image.size.width)*0.5;
    float origin_y = self.mapView.frame.size.height*0.5 - image.size.height;
    
    centerAnnotaionView = [[UIImageView alloc]initWithFrame:CGRectMake(origin_X, origin_y, image.size.width, image.size.height)];
    centerAnnotaionView.image = image;
    centerAnnotaionView.contentMode = UIViewContentModeScaleAspectFill;
    [self.mapView addSubview:centerAnnotaionView];
}




#pragma mark delegate
#pragma mark MAMapViewDelegate
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    
    NSLog(@"%d",updatingLocation);
    NSLog(@"位置更新");
    NSLog(@"当前位置：%f,%f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    
    if (!userLocation.location || !(userLocation.location.coordinate.latitude>0)) {
        return;
    }
    
    if (!_currentLocation)
    {   //第一次进入地图移动地图至用户当前位置
        _mapView.userTrackingMode = MAUserTrackingModeFollow;
        [self centerAnnotaionAnimation];
        [self POIAroundSearchRequest:[AMapGeoPoint locationWithLatitude:userLocation.location.coordinate.latitude longitude:userLocation.location.coordinate.longitude]];
    }
    _currentLocation = userLocation.location;
}

/**
 * @brief 地图将要发生移动时调用此接口
 */
- (void)mapView:(MAMapView *)mapView mapWillMoveByUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        [self removeStopAnnotaion];
    }
}

/**
 * @brief 地图移动结束后调用此接口
 */
- (void)mapView:(MAMapView *)mapView mapDidMoveByUser:(BOOL)wasUserAction {
    if (wasUserAction)
    {
//        [self removeStopAnnotaion];
        NSLog(@"滑动地图结束");
        [self POIAroundSearchRequest:[AMapGeoPoint locationWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude]];
    }
}


/**
 * @brief 地图将要发生缩放时调用此接口
 */
- (void)mapView:(MAMapView *)mapView mapWillZoomByUser:(BOOL)wasUserAction {
    if (wasUserAction) {
        [self removeStopAnnotaion];
    }
}

/**
 * @brief 地图缩放结束后调用此接口
 */
- (void)mapView:(MAMapView *)mapView mapDidZoomByUser:(BOOL)wasUserAction {
    NSLog(@"地图缩放结束");
    if (wasUserAction) {
//        [self removeStopAnnotaion];
        [self POIAroundSearchRequest:[AMapGeoPoint locationWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude]];
    }
}


/**
 * @brief 根据anntation生成对应的View
 */
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    
    //用户当前位置大头针
    if ([annotation isKindOfClass:[MAUserLocation class]])
    {
        static NSString *userLocationStyleReuseIndetifier = @"userLocationStyleReuseIndetifier";
        
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        
        if (annotationView == nil)
        {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:userLocationStyleReuseIndetifier];
        }
        
        annotationView.canShowCallout = NO;
        annotationView.image = [UIImage imageNamed:@"heardImg_passenger_default"];
        annotationView.frame = CGRectMake(0, 0, 26, 26);
        annotationView.contentMode = UIViewContentModeScaleToFill;
        annotationView.layer.masksToBounds = YES;
        
        return annotationView;
    }
    
    //停车场位置大头针
    else if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *stopCarReuseIndetifier = @"stopCarReuseIndetifier";
        
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:stopCarReuseIndetifier];
        
        if (annotationView == nil)
        {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:stopCarReuseIndetifier];
        }
        
        UIImage *image = [UIImage imageNamed:@"centerAnnotation"];
        annotationView.image = image;
        annotationView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        annotationView.contentMode = UIViewContentModeScaleToFill;
        annotationView.layer.masksToBounds = YES;
        annotationView.centerOffset = CGPointMake(0, -0.5*image.size.height);
        
        return annotationView;
    }

    return nil;
}

#pragma mark AMapSearchDelegate
/**
 * @brief POI查询回调函数
 */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.pois.count == 0) {
        NSLog(@"暂无停车场信息");
        return;
    }

    //清空数据源
    [self.dataSource removeAllObjects];
    
    for (AMapPOI *poi in response.pois) {
        NSLog(@"%@",poi.name);
        NSLog(@"%@",poi.address);
        
        MAPointAnnotation *anotation = [[MAPointAnnotation alloc]init];
        anotation.title = poi.name;
        anotation.subtitle = poi.address;
        anotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
        [self.dataSource addObject:anotation];
    }
    //添加附近车库大头针
    [self.mapView addAnnotations:self.dataSource];
}

#pragma mark private
//发起poi检索
- (void)POIAroundSearchRequest:(AMapGeoPoint *)point {
    //取消所有未回调的请求，防止多次叠加请求，防止造成数据源错乱
    [self.searchAPI cancelAllRequests];
    //地图移动结束，请求高德地图附近停车场信息
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc]init];
    request.keywords = @"停车库";
    request.radius = 3000;
    request.location = point;
    /*发起搜索*/
    [self.searchAPI AMapPOIAroundSearch:request];
}
//移除地图上所有的停车场大头针
- (void)removeStopAnnotaion {
    [UIView animateWithDuration:.5 animations:^{
        
        NSMutableArray *removeAnnotations = [[NSMutableArray alloc]init];
        [removeAnnotations addObjectsFromArray:self.mapView.annotations];
        [removeAnnotations removeObject:self.mapView.userLocation];
        [self.mapView removeAnnotations:removeAnnotations];
        
    } completion:^(BOOL finished) {
        [self centerAnnotaionAnimation];
    }];
}
//跳动动画
- (void)centerAnnotaionAnimation {
    UIImage *centerAnnotationImage = [UIImage imageNamed:@"position"];
    
    float origin_x = (self.view.frame.size.width - centerAnnotationImage.size.width)*0.5;
    float origin_y = self.mapView.frame.size.height*0.5 - centerAnnotationImage.size.height*2+10;
    //组动画
    CAKeyframeAnimation *anima1 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    NSValue *value0 = [NSValue valueWithCGPoint:CGPointMake(origin_x+centerAnnotationImage.size.width/2, origin_y+centerAnnotationImage.size.height+10)];
    NSValue *value1 = [NSValue valueWithCGPoint:CGPointMake(origin_x+centerAnnotationImage.size.width/2, origin_y-30+centerAnnotationImage.size.height+10)];
    NSValue *value2 = [NSValue valueWithCGPoint:CGPointMake(origin_x+centerAnnotationImage.size.width/2, origin_y+centerAnnotationImage.size.height+10)];
    anima1.values = [NSArray arrayWithObjects:value0,value1,value2, nil];
    //缩放动画
//    CABasicAnimation *anima2 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
//    anima2.fromValue = [NSNumber numberWithFloat:0.5f];
//    anima2.toValue = [NSNumber numberWithFloat:1.0f];
    //组动画
    CAAnimationGroup *groupAnimation = [CAAnimationGroup animation];
    groupAnimation.animations = [NSArray arrayWithObjects:anima1, nil];
    groupAnimation.duration = 0.5f;
    groupAnimation.fillMode = kCAFillModeForwards;
    groupAnimation.removedOnCompletion = NO;
    [centerAnnotaionView.layer addAnimation:groupAnimation forKey:@"groupAnimation"];
}

#pragma mark set
- (AMapSearchAPI *)searchAPI {
    if (!_searchAPI) {
        _searchAPI = [[AMapSearchAPI alloc]init];
        _searchAPI.delegate = self;
    }
    return _searchAPI;
}
- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc]init];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
