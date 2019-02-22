//
//  FaceRecognitionController.m
//  FacePhotograph
//
//  Created by 王兴文 on 2017/12/21.
//  Copyright © 2017年 Shanghai Xiermei. All rights reserved.
//

#import "FaceRecognitionController.h"
#import <AVFoundation/AVFoundation.h>
#import "LY_AudioPalyTool.h"

#import "FaceResultViewController.h"

@interface FaceRecognitionController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic)AVCaptureDevice *device;
// AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic, strong)AVCaptureSession *session;
// AVCaptureDeviceInput对象是输入流
@property (nonatomic, strong)AVCaptureDeviceInput *videoInput;
// 照片输出流对象
@property (nonatomic, strong)AVCaptureStillImageOutput *stillImageOutput;
// 预览图层，来显示照相机拍摄到的画面
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
// 放置预览图层的View
@property (weak, nonatomic) IBOutlet UIView *ViewContainer;
// 用来展示拍照获取的照片
@property (weak, nonatomic) IBOutlet UIImageView *face_box_imageView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;//拍照
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (nonatomic, assign) BOOL isflashOn;


@property (nonatomic,strong) LY_AudioPalyTool *audioPalyTool;//播放
@property (strong) AVCaptureVideoDataOutput *frameOutput;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic,strong)UIImage *changingImage;//获取到的每一帧图片

@end

@implementation FaceRecognitionController
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.session) {
        [self.session startRunning];
    }
    self.face_box_imageView.hidden=NO;
    [self setUpCameraLayer];
    [self setupFrameOutput];
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.session) {
        [self.session stopRunning];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initialSession];
    
}
#pragma mark- 拍照属性
- (void)initialSession
{
    self.session = [[AVCaptureSession alloc] init];
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:nil];
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    // 这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
        
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
}

#pragma mark- 显示范围
- (void)setUpCameraLayer
{
    if (self.previewLayer == nil) {
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        
        CALayer * viewLayer = [self.ViewContainer layer];
        [viewLayer setMasksToBounds:YES];
        [self.previewLayer setFrame:viewLayer.bounds];
        [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [viewLayer addSublayer:self.previewLayer];
    }
}
#pragma mark- 开关闪光灯
- (IBAction)FlashOpenOrCloseButtonClick:(UIButton *)sender {
    
    
    
    if ([_device lockForConfiguration:nil]) {
        
        if (self.videoInput.device.position ==AVCaptureDevicePositionBack)
        {
            if (_isflashOn) {
                if ([_device isFlashModeSupported:AVCaptureFlashModeOff]) {
                    [_device setFlashMode:AVCaptureFlashModeOff];
                    _isflashOn = NO;
                    [_flashButton setImage:[UIImage imageNamed:@"flashClose"] forState:UIControlStateNormal];
                }
            }else{
                if ([_device isFlashModeSupported:AVCaptureFlashModeOn]) {
                    [_device setFlashMode:AVCaptureFlashModeOn];
                    _isflashOn = YES;
                    [_flashButton setImage:[UIImage imageNamed:@"flashOpen"] forState:UIControlStateNormal];
                }
            }
        }else
        {
            if ([_device isFlashModeSupported:AVCaptureFlashModeOff]) {
                [_device setFlashMode:AVCaptureFlashModeOff];
                _isflashOn = NO;
                [_flashButton setImage:[UIImage imageNamed:@"flashClose"] forState:UIControlStateNormal];
            }
        }

        [_device unlockForConfiguration];
    }
}
#pragma mark- 这是拍照按钮的方法
- (IBAction)shutterCamera:(UIButton *)sender {
    AVCaptureConnection *videoConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!videoConnection) {
        return;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *quartzImage = [UIImage imageWithData:imageData];
        
        if (self.videoInput.device.position ==AVCaptureDevicePositionFront) {
//            _changingImage = [UIImage imageWithCGImage:_changingImage.CGImage scale:1.0f orientation:UIImageOrientationUpMirrored];
            quartzImage = [UIImage imageWithCGImage:quartzImage.CGImage scale:1.0f orientation:UIImageOrientationLeftMirrored];
        }
        if (quartzImage) {
            FaceResultViewController *resultVC =[[FaceResultViewController alloc]init];
            resultVC.showImage=quartzImage;
            [self.navigationController pushViewController:resultVC animated:YES];
        }
    }];
}
#pragma mark- 这是切换镜头的按钮方法
- (IBAction)toggleCamera:(UIButton *)sender {
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[_videoInput device] position];
        if (position == AVCaptureDevicePositionBack) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
            [_flashButton setImage:[UIImage imageNamed:@"flashClose"] forState:UIControlStateNormal];
        } else if (position == AVCaptureDevicePositionFront) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        } else {
            return;
        }
        
        if (newVideoInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.videoInput];
            if ([self.session canAddInput:newVideoInput]) {
                [self.session addInput:newVideoInput];
                self.videoInput = newVideoInput;
            } else {
                [self.session addInput:self.videoInput];
            }
            [self.session commitConfiguration];
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
    }
}
//这是获取前后摄像头对象的方法
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            self.device=device;
            return device;
        }
    }
    return nil;
}
- (AVCaptureDevice *)frontCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}
- (AVCaptureDevice *)backCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}


#pragma mark- 自动识别
-(void)setupFrameOutput
{
    self.frameOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    if ([self.session canAddOutput:self.frameOutput]){
        [self.session addOutput:self.frameOutput];
    }
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL);
//       self.frameOutput.minFrameDuration = CMTimeMake(1, 25);
//       self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
    [self.frameOutput setSampleBufferDelegate:self queue:queue];
    self.frameOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                      nil];
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    _changingImage = [self scaleToSize:[self imageFromSampleBuffer:sampleBuffer] size:CGSizeMake(Screen_Width, Screen_Height)];
    
    CIImage* myImage = [CIImage imageWithCGImage:_changingImage.CGImage];
    NSDictionary *options = @{ CIDetectorSmile: [NSNumber numberWithBool:YES], CIDetectorEyeBlink: [NSNumber numberWithBool:YES]};
    NSArray *features = [self.faceDetector featuresInImage:myImage options:options];
    
    BOOL foundWink = NO;
    for (CIFaceFeature * face in features) {
        if (face.hasLeftEyePosition && face.hasRightEyePosition && face.hasMouthPosition) {
            BOOL leftEyeFound = [face hasLeftEyePosition];
            BOOL rightEyeFound = [face hasRightEyePosition];
            
            if (!leftEyeFound &&!rightEyeFound ) continue;// 没有眼睛，退出此次循环

            CGPoint maoCenter = CGPointMake((face.leftEyePosition.x + face.rightEyePosition.x) * 0.5,(face.mouthPosition.y+face.rightEyePosition.y) * 0.5);
            if(CGRectContainsPoint(_face_box_imageView.frame,maoCenter)){
                foundWink = true;
            }
            
        }
    }
    //设置标志变绿
    if (foundWink==YES) {
        [self performSelectorOnMainThread:@selector(displayImageGreen) withObject:nil waitUntilDone:YES];
//        [self performSelectorOnMainThread:@selector(playWithName:) withObject:@"verygood" waitUntilDone:YES];
    }else{
        [self performSelectorOnMainThread:@selector(displayImage2) withObject:nil waitUntilDone:YES];
//        [self performSelectorOnMainThread:@selector(playWithName:) withObject:@"LightNotice" waitUntilDone:YES];
        
    }
}
- (CIDetector *)faceDetector
{
    if (!_faceDetector) {
        // setup the accuracy of the detector
        NSDictionary *detectorOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                         CIDetectorAccuracyHigh, CIDetectorAccuracy, nil];
        
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    }
    return _faceDetector;
}
- (LY_AudioPalyTool *)audioPalyTool
{
    if (!_audioPalyTool) {
        _audioPalyTool = [LY_AudioPalyTool sharedAudioPaly];
    }
    return _audioPalyTool;
}
- (void)playWithName:(NSString *)name
{
    if (self.audioPalyTool.lY_AudioPlayer.rate > 0) {
        return;
    }else{
        [self.audioPalyTool PlayLatterResourceWithName:name];
        [self.audioPalyTool play];
    }
}
- (void)playSeccuseName:(NSString *)name
{
    [self.audioPalyTool PlayLatterResourceWithName:name];
    [self.audioPalyTool play];
}
-(void)displayImageGreen{
    _face_box_imageView.image= [UIImage imageNamed:@"photo-facebox-green"];
    self.takePhotoButton.enabled=YES;
}
-(void)displayImage2{
    _face_box_imageView.image= [UIImage imageNamed:@"photo-facebox-red"];
    self.takePhotoButton.enabled=NO;
}
//修改image的大小
- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    //释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);
}
- (void)dealloc{
    if (self.session) {
        [self.session stopRunning];
        [self.session removeInput:self.videoInput];
        self.videoInput = nil;
        [self.session removeOutput:self.frameOutput];
        self.frameOutput = nil;
        self.session= nil;
        //移除localView里面的预览内容
        for(CALayer *layer in _ViewContainer.layer.sublayers){
            if ([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]]){
                [layer removeFromSuperlayer];
                return;
            }
        }
        _ViewContainer = nil;
    }
}










#pragma mark- 裁剪图片的指定区域
- (UIImage *)getImageByCuttingImage:(UIImage *)image Rect:(CGRect )rect{
    // 定义 myImageRect ，截图的区域
    CGRect myImageRect = rect;
    UIImage * bigImage= image;
    CGImageRef imageRef = bigImage. CGImage ;
    CGImageRef subImageRef = CGImageCreateWithImageInRect (imageRef, myImageRect);
    CGSize size;
    size. width = rect. size . width ;
    size. height = rect. size . height ;
    UIGraphicsBeginImageContext (size);
    CGContextRef context = UIGraphicsGetCurrentContext ();
    CGContextDrawImage (context, myImageRect, subImageRef);
    UIImage * smallImage = [ UIImage imageWithCGImage :subImageRef];
    CGImageRelease(subImageRef);
    UIGraphicsEndImageContext ();
    return smallImage;
}

@end
