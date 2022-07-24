//
//  WebcamController.m
//  UnityMacWebcamPlugin
//
//  Created by Daehyeon Wi on 2022/07/23.
//

#import "WebcamController.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>


@implementation WebcamController

-(id) init
{
    self = [super init];
    _startedCV = [[NSCondition alloc] init];
    return self;
}

-(void) dealloc
{
    [self stopCapture];
    _session = nil;
    
    NSLog(@"MYTY Webcam : webcam deinit %hhd", [_thread isExecuting]);
    
}

-(void) initCaptureSession{
    if(!_thread){
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(doWork) object:nil];
        [_thread start];
        
        [_startedCV lock];
        [_startedCV wait];
        [_startedCV unlock];
    }
}

-(void) doWork
{
    CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _metalDevice, nil, &_textureCache);
    
    _runLoop = CFRunLoopGetCurrent();
    
    _session = [[AVCaptureSession alloc] init];
   
    
    AVCaptureDevice *device = nil;
    AVCaptureDeviceInput *device_input = nil;
    AVCaptureVideoDataOutput *video_output = nil;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for(AVCaptureDevice* dev in devices){
        if([[dev localizedName] isEqualToString:@"FaceTime HD Camera"]){
            device = dev;
        }
    }
    
    NSError *error;
    
    device_input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if(error){
        NSLog(@"MYTY Webcam : Error in create device input : %@", [error description]);
    }
    
    if([_session canAddInput:device_input])
        [_session addInput:device_input];
    else
        NSLog(@"MYTY Webcam : Cannot add device input");
    
    video_output = [[AVCaptureVideoDataOutput alloc] init];

    [video_output setVideoSettings:@{
        (NSString*)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
        (NSString*)kCVPixelBufferWidthKey : [NSNumber numberWithInt:640],
        (NSString*)kCVPixelBufferHeightKey : [NSNumber numberWithInt:360],
        
    }];
    
    [video_output setSampleBufferDelegate:self queue:dispatch_queue_create("sample_queue", DISPATCH_QUEUE_SERIAL)];
    
    if([_session canAddOutput:video_output])
        [_session addOutput:video_output];
    else
        NSLog(@"MYTY Webcam : Cannot add device output");
    
    NSLog(@"MYTY Webcam : Webcam plugin init");
    
    [_startedCV lock];
    [_startedCV signal];
    [_startedCV unlock];
    CFRunLoopRun();
}




-(void) startCapture{
    if(![_session isRunning])
        [_session startRunning];
    NSLog(@"MYTY Webcam : startCapture called");
}
-(void) stopCapture{
    if([_session isRunning])
        [_session stopRunning];
    NSLog(@"MYTY Webcam : stopCapture called");
}

- (void) captureOutput: (AVCaptureOutput*) output
   didOutputSampleBuffer: (CMSampleBufferRef) buffer
        fromConnection: (AVCaptureConnection*) connection
{
#pragma unused (output)
#pragma unused (connection)
    CVImageBufferRef frame = CMSampleBufferGetImageBuffer(buffer);
    size_t width = CVPixelBufferGetWidth(frame);
    size_t height = CVPixelBufferGetHeight(frame);
    
    if(!_imageTexture){
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, frame, nil, MTLPixelFormatBGRA8Unorm, width, height, 0, &_imageTexture);
    
        self.metalTexture = CVMetalTextureGetTexture(_imageTexture);
        //NSLog(@"MYTY Webcam : %lu %lu %lu %@",_metalTexture.width, _metalTexture.height, _metalTexture.pixelFormat, _metalTexture);
        
    }
}

-(void)releaseTexture{
    if(_imageTexture){
        CVBufferRelease(_imageTexture);
        _imageTexture = nil;
    }
}

-(int)getWidth{
    if(self.metalTexture){
        return self.metalTexture.width;
    }
    
    return -1;
}

-(int)getHeight{
    if(self.metalTexture){
        return self.metalTexture.height;
    }
    
    return -1;
}
+(NSString*) GetFormatName:(int)type{
    
    switch (type) {
        case kCVPixelFormatType_1Monochrome:                   return @"kCVPixelFormatType_1Monochrome";
        case kCVPixelFormatType_2Indexed:                      return @"kCVPixelFormatType_2Indexed";
        case kCVPixelFormatType_4Indexed:                      return @"kCVPixelFormatType_4Indexed";
        case kCVPixelFormatType_8Indexed:                      return @"kCVPixelFormatType_8Indexed";
        case kCVPixelFormatType_1IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_1IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_2IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_2IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_4IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_4IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_8IndexedGray_WhiteIsZero:      return @"kCVPixelFormatType_8IndexedGray_WhiteIsZero";
        case kCVPixelFormatType_16BE555:                       return @"kCVPixelFormatType_16BE555";
        case kCVPixelFormatType_16LE555:                       return @"kCVPixelFormatType_16LE555";
        case kCVPixelFormatType_16LE5551:                      return @"kCVPixelFormatType_16LE5551";
        case kCVPixelFormatType_16BE565:                       return @"kCVPixelFormatType_16BE565";
        case kCVPixelFormatType_16LE565:                       return @"kCVPixelFormatType_16LE565";
        case kCVPixelFormatType_24RGB:                         return @"kCVPixelFormatType_24RGB";
        case kCVPixelFormatType_24BGR:                         return @"kCVPixelFormatType_24BGR";
        case kCVPixelFormatType_32ARGB:                        return @"kCVPixelFormatType_32ARGB";
        case kCVPixelFormatType_32BGRA:                        return @"kCVPixelFormatType_32BGRA";
        case kCVPixelFormatType_32ABGR:                        return @"kCVPixelFormatType_32ABGR";
        case kCVPixelFormatType_32RGBA:                        return @"kCVPixelFormatType_32RGBA";
        case kCVPixelFormatType_64ARGB:                        return @"kCVPixelFormatType_64ARGB";
        case kCVPixelFormatType_48RGB:                         return @"kCVPixelFormatType_48RGB";
        case kCVPixelFormatType_32AlphaGray:                   return @"kCVPixelFormatType_32AlphaGray";
        case kCVPixelFormatType_16Gray:                        return @"kCVPixelFormatType_16Gray";
        case kCVPixelFormatType_30RGB:                         return @"kCVPixelFormatType_30RGB";
        case kCVPixelFormatType_422YpCbCr8:                    return @"kCVPixelFormatType_422YpCbCr8";
        case kCVPixelFormatType_4444YpCbCrA8:                  return @"kCVPixelFormatType_4444YpCbCrA8";
        case kCVPixelFormatType_4444YpCbCrA8R:                 return @"kCVPixelFormatType_4444YpCbCrA8R";
        case kCVPixelFormatType_4444AYpCbCr8:                  return @"kCVPixelFormatType_4444AYpCbCr8";
        case kCVPixelFormatType_4444AYpCbCr16:                 return @"kCVPixelFormatType_4444AYpCbCr16";
        case kCVPixelFormatType_444YpCbCr8:                    return @"kCVPixelFormatType_444YpCbCr8";
        case kCVPixelFormatType_422YpCbCr16:                   return @"kCVPixelFormatType_422YpCbCr16";
        case kCVPixelFormatType_422YpCbCr10:                   return @"kCVPixelFormatType_422YpCbCr10";
        case kCVPixelFormatType_444YpCbCr10:                   return @"kCVPixelFormatType_444YpCbCr10";
        case kCVPixelFormatType_420YpCbCr8Planar:              return @"kCVPixelFormatType_420YpCbCr8Planar";
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:     return @"kCVPixelFormatType_420YpCbCr8PlanarFullRange";
        case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:        return @"kCVPixelFormatType_422YpCbCr_4A_8BiPlanar";
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  return @"kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange";
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:   return @"kCVPixelFormatType_420YpCbCr8BiPlanarFullRange";
        case kCVPixelFormatType_422YpCbCr8_yuvs:               return @"kCVPixelFormatType_422YpCbCr8_yuvs";
        case kCVPixelFormatType_422YpCbCr8FullRange:           return @"kCVPixelFormatType_422YpCbCr8FullRange";
        case kCVPixelFormatType_OneComponent8:                 return @"kCVPixelFormatType_OneComponent8";
        case kCVPixelFormatType_TwoComponent8:                 return @"kCVPixelFormatType_TwoComponent8";
        case kCVPixelFormatType_30RGBLEPackedWideGamut:        return @"kCVPixelFormatType_30RGBLEPackedWideGamut";
        case kCVPixelFormatType_OneComponent16Half:            return @"kCVPixelFormatType_OneComponent16Half";
        case kCVPixelFormatType_OneComponent32Float:           return @"kCVPixelFormatType_OneComponent32Float";
        case kCVPixelFormatType_TwoComponent16Half:            return @"kCVPixelFormatType_TwoComponent16Half";
        case kCVPixelFormatType_TwoComponent32Float:           return @"kCVPixelFormatType_TwoComponent32Float";
        case kCVPixelFormatType_64RGBAHalf:                    return @"kCVPixelFormatType_64RGBAHalf";
        case kCVPixelFormatType_128RGBAFloat:                  return @"kCVPixelFormatType_128RGBAFloat";
        case kCVPixelFormatType_14Bayer_GRBG:                  return @"kCVPixelFormatType_14Bayer_GRBG";
        case kCVPixelFormatType_14Bayer_RGGB:                  return @"kCVPixelFormatType_14Bayer_RGGB";
        case kCVPixelFormatType_14Bayer_BGGR:                  return @"kCVPixelFormatType_14Bayer_BGGR";
        case kCVPixelFormatType_14Bayer_GBRG:                  return @"kCVPixelFormatType_14Bayer_GBRG";
        default: return @"UNKNOWN";
    }
}

@end
