// Example low level rendering Unity plugin

#include "PlatformBase.h"
#include "Unity/IUnityGraphicsMetal.h"
#include "RenderAPI.h"
#include <assert.h>
#include <math.h>
#include <vector>
#import "WebcamController.h"

// --------------------------------------------------------------------------
// SetTimeFromUnity, an example function we export which is called by one of the scripts.

static WebcamController * webcam = nil;

static RenderAPI* s_CurrentAPI = NULL;

static float g_Time;


extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API SetTimeFromUnity (float t) { g_Time = t; }


// --------------------------------------------------------------------------
// SetTextureFromUnity, an example function we export which is called by one of the scripts.

static void* g_TextureHandle = NULL;
static int   g_TextureWidth  = 0;
static int   g_TextureHeight = 0;

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API SetTextureFromUnity(void* textureHandle, int w, int h)
{
	// A script calls this at initialization time; just remember the texture pointer here.
	// Will update texture pixels each frame from the plugin rendering event (texture update
	// needs to happen on the rendering thread).
	g_TextureHandle = textureHandle;
	g_TextureWidth = w;
	g_TextureHeight = h;
}


// --------------------------------------------------------------------------
// UnitySetInterfaces

static void UNITY_INTERFACE_API OnGraphicsDeviceEvent(UnityGfxDeviceEventType eventType);

static IUnityInterfaces* s_UnityInterfaces = NULL;
static IUnityGraphics* s_Graphics = NULL;

extern "C" void	UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces)
{
	s_UnityInterfaces = unityInterfaces;
	s_Graphics = s_UnityInterfaces->Get<IUnityGraphics>();
	s_Graphics->RegisterDeviceEventCallback(OnGraphicsDeviceEvent);
	
#if SUPPORT_VULKAN
	if (s_Graphics->GetRenderer() == kUnityGfxRendererNull)
	{
		extern void RenderAPI_Vulkan_OnPluginLoad(IUnityInterfaces*);
		RenderAPI_Vulkan_OnPluginLoad(unityInterfaces);
	}
#endif // SUPPORT_VULKAN

	// Run OnGraphicsDeviceEvent(initialize) manually on plugin load
	OnGraphicsDeviceEvent(kUnityGfxDeviceEventInitialize);
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload()
{
	s_Graphics->UnregisterDeviceEventCallback(OnGraphicsDeviceEvent);
    webcam = nil;
}

#if UNITY_WEBGL
typedef void	(UNITY_INTERFACE_API * PluginLoadFunc)(IUnityInterfaces* unityInterfaces);
typedef void	(UNITY_INTERFACE_API * PluginUnloadFunc)();

extern "C" void	UnityRegisterRenderingPlugin(PluginLoadFunc loadPlugin, PluginUnloadFunc unloadPlugin);

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API RegisterPlugin()
{
	UnityRegisterRenderingPlugin(UnityPluginLoad, UnityPluginUnload);
}
#endif

// --------------------------------------------------------------------------
// GraphicsDeviceEvent


static UnityGfxRenderer s_DeviceType = kUnityGfxRendererNull;


static void UNITY_INTERFACE_API OnGraphicsDeviceEvent(UnityGfxDeviceEventType eventType)
{
	// Create graphics API implementation upon initialization
	if (eventType == kUnityGfxDeviceEventInitialize)
	{
		assert(s_CurrentAPI == NULL);
		s_DeviceType = s_Graphics->GetRenderer();
		s_CurrentAPI = CreateRenderAPI(s_DeviceType);
	}

	// Let the implementation process the device related events
	if (s_CurrentAPI)
	{
		s_CurrentAPI->ProcessDeviceEvent(eventType, s_UnityInterfaces);
        IUnityGraphicsMetal *metal = (IUnityGraphicsMetal*) s_CurrentAPI->GetGraphicsInterface();
        webcam = [[WebcamController alloc] init];
        webcam.metalDevice = metal->MetalDevice();
        
	}

	// Cleanup graphics API implementation upon shutdown
	if (eventType == kUnityGfxDeviceEventShutdown)
	{
		delete s_CurrentAPI;
		s_CurrentAPI = NULL;
		s_DeviceType = kUnityGfxRendererNull;
	}
}



static void UNITY_INTERFACE_API OnRenderEvent(int eventID)
{
	// Unknown / unsupported graphics device type? Do nothing
	if (s_CurrentAPI == NULL)
		return;

}


// --------------------------------------------------------------------------
// GetRenderEventFunc, an example function we export which is used to get a rendering event callback function.

extern "C" UnityRenderingEvent UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetRenderEventFunc()
{
	return OnRenderEvent;
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API InitPlugin(void){
    if(webcam){
        [webcam initCaptureSession];
    }
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UninitPlugin(void){
    if(webcam){
        webcam = nil;
        IUnityGraphicsMetal *metal = (IUnityGraphicsMetal*) s_CurrentAPI->GetGraphicsInterface();
        webcam = [[WebcamController alloc] init];
        webcam.metalDevice = metal->MetalDevice();
    }
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API StartCapture(void){
    if(webcam){
        [webcam startCapture];
    }
}
extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API StopCapture(void){
    if(webcam){
        [webcam stopCapture];
    }
}

extern "C" int UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetTexWidth(){
    if(webcam){
        return [webcam getWidth];
    }
    
    return -1;
}


extern "C" int UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetTexHeight(){
    if(webcam){
        return [webcam getHeight];
    }
    return -1;
}


extern "C"  id<MTLTexture>  UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetTexturePtr(void){
    if(webcam){
        if(webcam.metalTexture && g_TextureHandle){
            s_CurrentAPI->CopyTexture((void*)CFBridgingRetain(webcam.metalTexture), g_TextureHandle);
            return webcam.metalTexture;
        }else return nil;
    }
    return nil;
}


extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API ReleaseTexture(void){
    if(webcam){
        [webcam releaseTexture];
    }
}

extern "C" int UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetNumDevices(void){
    if(webcam){
        return [webcam getNumDevices];
    }
    return -1;
}

extern "C" char* UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API GetDeviceName(int index){
    if(!webcam) return NULL;
    int n = [webcam getNumDevices];
    if(index<0 || index>=n) return NULL;
    const char * cstr = [[webcam getDeviceName:index] UTF8String];
    char* retStr = (char*) malloc(strlen(cstr)+1);
    strcpy(retStr, cstr);
    return retStr;
}
