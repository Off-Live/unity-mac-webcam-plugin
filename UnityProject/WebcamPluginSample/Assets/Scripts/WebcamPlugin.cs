using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;

public class WebcamPlugin : MonoBehaviour
{
    [DllImport("UnityMacWebcamPlugin")]
    private static extern void InitPlugin();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void UninitPlugin();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void StartCapture();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void StopCapture();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern IntPtr GetTexturePtr();


    [DllImport("UnityMacWebcamPlugin")]
    private static extern void CopyTexture();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void ReleaseTexture();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void SetTextureFromUnity(System.IntPtr texture, int w, int h);

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void SetTimeFromUnity(float t);

    [DllImport("UnityMacWebcamPlugin")]
    private static extern int GetTexWidth();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern int GetTexHeight();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern int GetNumDevices();

    [DllImport("UnityMacWebcamPlugin")]
    private static extern string GetDeviceName(int index);

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void SelectDeviceWithName(string name);

    [DllImport("UnityMacWebcamPlugin")]
    private static extern void SelectDeviceWithIndex(int index);

    public RawImage image;
    public int fps = 30;

    public Texture2D camRGBATexture
    {
        get
        {
            return m_camRGBATexture;
        }
    }

    public UnityEvent cameraReady;

    private Texture2D m_camRGBATexture;
    private bool m_quit = false;
    private Texture2D m_stagTexture;
    private List<string> m_deviceList = new();



    public void Play()
    {
        StartCapture();
    }

    public void Stop()
    {
        StopCapture();
    }

    public void SetDevice(string name)
    {
        SelectDeviceWithName(name);
    }

    public List<string> GetDevices()
    {
        return m_deviceList;
    }
    
    void Start()
    {

        InitPlugin();

        var numDevice = GetNumDevices();
        for(int i = 0; i < numDevice; i++)
        {
            m_deviceList.Add(GetDeviceName(i));
        }

       
        StartCoroutine(CameraLoop());
        cameraReady?.Invoke();
    }

   
    IEnumerator CameraLoop()
    {
        while (!m_quit)
        {
            yield return new WaitForSeconds(1.0f / fps);
            var result = ProcessTexture();
            
            yield return new WaitForEndOfFrame();
            if(result) ReleaseTexture();
        }
    }

    bool ProcessTexture()
    {
        int width = GetTexWidth();
        int height = GetTexHeight();
        if (width < 0) return false;

        Debug.Assert(width > 0 && height > 0);

        if (m_stagTexture == null)
        {
            m_stagTexture = new Texture2D(width, height, TextureFormat.BGRA32, false);
            m_camRGBATexture = new Texture2D(width, height, TextureFormat.RGBA32, false);
            SetTextureFromUnity(m_stagTexture.GetNativeTexturePtr(), width, height);
        }

        if(m_stagTexture.width!=width || m_stagTexture.height != height)
        {
            m_stagTexture = new Texture2D(width, height, TextureFormat.BGRA32, false);
            m_camRGBATexture = new Texture2D(width, height, TextureFormat.RGBA32, false);
            SetTextureFromUnity(m_stagTexture.GetNativeTexturePtr(), width, height);
        }

        var ptr = GetTexturePtr();
        if (ptr == (IntPtr)0) return false;
        CopyTexture();
        Graphics.ConvertTexture(m_stagTexture, m_camRGBATexture);
        m_camRGBATexture.ReadPixels(new Rect(0, 0, width, height), 0, 0);
        if (image != null) image.texture = m_camRGBATexture;
        return true;
    }
   

    private void OnDestroy()
    {
        m_quit = true;

        UninitPlugin();
    }
}
