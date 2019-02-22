//
//  FaceResultViewController.m
//  FacePhotograph
//
//  Created by 王兴文 on 2017/12/28.
//  Copyright © 2017年 Shanghai Xiermei. All rights reserved.
//
#define MaxSCale 10.0  //最大缩放比例
#define MinScale 0.1  //最小缩放比例

//屏幕宽度
#define kScreenWidth        [[UIScreen mainScreen] bounds].size.width
//屏幕高度
#define kScreenHeight       [[UIScreen mainScreen] bounds].size.height

#import "FaceResultViewController.h"

@interface FaceResultViewController ()
@property (weak, nonatomic) IBOutlet UIView *faceView;
@property (weak, nonatomic) IBOutlet UIImageView *imageShowView;
@end

@implementation FaceResultViewController
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=[UIColor blackColor];
    
    self.imageShowView.image=self.showImage;
    [self.imageShowView setUserInteractionEnabled:YES];
    [self.imageShowView setMultipleTouchEnabled:YES];
    
    
    
    // 旋转手势
//    UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateView:)];
//    [self.faceView addGestureRecognizer:rotationGestureRecognizer];
    
    // 缩放手势
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.faceView addGestureRecognizer:pinch];
    
    // 移动手势
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    panGestureRecognizer.maximumNumberOfTouches=1;
    [self.faceView addGestureRecognizer:panGestureRecognizer];
    
}
#pragma mark- 返回
- (IBAction)backButtonClick:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark-恢复原状
- (IBAction)recoverButtonClick:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        self.faceView.transform=CGAffineTransformMakeScale(1.0, 1.0);
        self.faceView.frame=CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        
        self.faceView.transform = CGAffineTransformMakeRotation(0);
    }];
}
#pragma mark- 放大缩小
- (void)pinch:(UIPinchGestureRecognizer *)pinchGestureRecognizer{

    UIView *view = pinchGestureRecognizer.view;
    
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan){
        if (pinchGestureRecognizer.numberOfTouches==2) {
            CGPoint p1 = [pinchGestureRecognizer locationOfTouch: 0 inView:view];
            CGPoint p2 = [pinchGestureRecognizer locationOfTouch: 1 inView:view];
            CGPoint anchorPoint;
            anchorPoint.x =(p1.x+p2.x)/2/view.bounds.size.width;
            anchorPoint.y =(p1.y+p2.y)/2/view.bounds.size.height;
            
            [self setAnchorPoint:anchorPoint forView:view];
        }
    }
    
    CGFloat scale = pinchGestureRecognizer.scale;
    if((scale< MinScale) && (scale>MaxSCale))return;
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan || pinchGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        view.transform = CGAffineTransformScale(view.transform, scale, scale);
        pinchGestureRecognizer.scale = 1;
    }else
    {
        [self setDefaultAnchorPointforView:view];
    }
    
    
}
-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint oldOrigin =view.frame.origin;
    view.layer.anchorPoint=anchorPoint;
    CGPoint newOrigin =view.frame.origin;
    
    CGPoint transition;
    transition.x =newOrigin.x-oldOrigin.x;
    transition.y =newOrigin.y-oldOrigin.y;
    
    view.center=CGPointMake(view.center.x-transition.x, view.center.y-transition.y);
}
-(void)setDefaultAnchorPointforView:(UIView *)view
{
    [self setAnchorPoint:CGPointMake(0.5f, 0.5f) forView:view];
}
#pragma mark-处理拖拉手势
-(void)panView:(UIPanGestureRecognizer *)panGestureRecognizer
{
    UIView *view = panGestureRecognizer.view;
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan || panGestureRecognizer.state == UIGestureRecognizerStateChanged){CGPoint translation = [panGestureRecognizer translationInView:view.superview];
        [view setCenter:(CGPoint){view.center.x + translation.x, view.center.y + translation.y}];
        [panGestureRecognizer setTranslation:CGPointZero inView:view.superview];
    }
}
#pragma mark-处理旋转手势
-(void)rotateView:(UIRotationGestureRecognizer *)rotationGestureRecognizer{
    UIView *view = rotationGestureRecognizer.view;
    if (rotationGestureRecognizer.state == UIGestureRecognizerStateBegan || rotationGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        view.transform = CGAffineTransformRotate(view.transform, rotationGestureRecognizer.rotation);
        [rotationGestureRecognizer setRotation:0];
    }
}

- (IBAction)saveImageToPhotoAlbum:(UIButton *)sender {
    UIImageWriteToSavedPhotosAlbum(_showImage, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}
#pragma mark- 保存相册
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    UIAlertView* alert=[[UIAlertView alloc] initWithTitle:@"提示"
                                                  message:@"照片保存成功！"
                                                 delegate:self
                                        cancelButtonTitle:@"确定"
                                        otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark- 两张图片组成同一张
-(UIImage*)merge_image:(UIImage *)back_image frontImage:(UIImage *)front_image{
    UIGraphicsBeginImageContextWithOptions(back_image.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [back_image drawAtPoint:CGPointMake(0, 0)];
    [front_image drawAtPoint:CGPointMake(0, 0)] ;
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    
    UIImage* merged_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return merged_image;
}
@end

