using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

public class Dropdown : MonoBehaviour
{
    public WebcamPlugin webcamPlugin;
    public void OnCameraReady()
    {
        var dropdown = GetComponent<TMP_Dropdown>();
        var devices = webcamPlugin.GetDevices();

        dropdown.ClearOptions();
        dropdown.AddOptions(devices);
        dropdown.value = 0;

        dropdown.onValueChanged.AddListener((id) =>
        {
            webcamPlugin.SetDevice(dropdown.options[id].text);
        });
    }
}
