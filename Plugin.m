//
//  Plugin.m
//  UnityMacWebcamPlugin
//
//  Created by Daehyeon Wi on 2022/07/23.
//

#import <Foundation/Foundation.h>
#import "Plugin.h"
#import "WebcamController.h"

WebcamController* webcam = nil;;

UNITY_PLUGIN_EXPORT int InitPlugin(void){
    if(!webcam){
        webcam = [[WebcamController alloc] init];
        [webcam initCaptureSession];
    }
    
    
    return 1;
}

UNITY_PLUGIN_EXPORT void UninitPlugin(void){
    if(webcam){
        webcam = nil;
    }
}

UNITY_PLUGIN_EXPORT void StartCapture(void){
    if(webcam){
        [webcam startCapture];
    }
}


UNITY_PLUGIN_EXPORT void StopCapture(void){
    if(webcam){
        [webcam stopCapture];
    }
}
