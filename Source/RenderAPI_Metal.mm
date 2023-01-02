
#include "RenderAPI.h"
#include "PlatformBase.h"


// Metal implementation of RenderAPI.


#if SUPPORT_METAL

#include "Unity/IUnityGraphicsMetal.h"
#import <Metal/Metal.h>


class RenderAPI_Metal : public RenderAPI
{
public:
	RenderAPI_Metal();
	virtual ~RenderAPI_Metal() { }

	virtual void ProcessDeviceEvent(UnityGfxDeviceEventType type, IUnityInterfaces* interfaces);

	virtual bool GetUsesReverseZ() { return true; }

    virtual void* GetGraphicsInterface();
    
    virtual void CopyTexture(void* src, void* dst);

private:
	IUnityGraphicsMetal*	m_MetalGraphics;
};


RenderAPI* CreateRenderAPI_Metal()
{
	return new RenderAPI_Metal();
}



RenderAPI_Metal::RenderAPI_Metal()
{
}


void RenderAPI_Metal::ProcessDeviceEvent(UnityGfxDeviceEventType type, IUnityInterfaces* interfaces)
{
    NSLog(@"MYTY Webcam : process device event!");
	if (type == kUnityGfxDeviceEventInitialize)
	{
		m_MetalGraphics = interfaces->Get<IUnityGraphicsMetal>();
	}
	else if (type == kUnityGfxDeviceEventShutdown)
	{
		//@TODO: release resources
	}
}

void* RenderAPI_Metal::GetGraphicsInterface(){
    return m_MetalGraphics;
}

void RenderAPI_Metal::CopyTexture(void* src, void *dst){\
    id<MTLTexture> srcTexture = CFBridgingRelease(src);
    id<MTLTexture> dstTexture = (__bridge id<MTLTexture>)dst;
    id<MTLCommandBuffer> cmd = [[m_MetalGraphics->MetalDevice() newCommandQueue] commandBuffer];
    id<MTLBlitCommandEncoder> blitEncoder = [cmd blitCommandEncoder];
    [blitEncoder copyFromTexture:srcTexture toTexture:dstTexture];
    [blitEncoder endEncoding];
    [cmd commit];
    [cmd waitUntilCompleted];
}
#endif // #if SUPPORT_METAL
