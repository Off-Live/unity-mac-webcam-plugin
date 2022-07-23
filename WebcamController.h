//
//  WebcamController.h
//  UnityMacWebcamPlugin
//
//  Created by Daehyeon Wi on 2022/07/23.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
NS_ASSUME_NONNULL_BEGIN

@interface WebcamController : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
- (void)    captureOutput: (AVCaptureOutput*) output
    didOutputSampleBuffer: (CMSampleBufferRef) buffer
           fromConnection: (AVCaptureConnection*) connection;
@end

@interface WebcamController(){
    AVCaptureSession* _session;
    CVMetalTextureCacheRef _textureCache;
    CFRunLoopRef _runLoop;
    NSThread * _thread;
    NSCondition* _startedCV;
    CVMetalTextureRef _imageTexture;
}

@property (nonatomic, weak) id<MTLTexture> metalTexture;
@property (nonatomic, weak) id<MTLDevice> metalDevice;

-(void) initCaptureSession;
-(void) doWork;
-(void) startCapture;
-(void) stopCapture;
-(void) releaseTexture;



+(NSString*) GetFormatName: (int) type;

@end

NS_ASSUME_NONNULL_END
