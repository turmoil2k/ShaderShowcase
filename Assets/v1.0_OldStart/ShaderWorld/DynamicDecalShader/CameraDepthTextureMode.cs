using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraDepthTextureMode : MonoBehaviour
{
    [SerializeField] DepthTextureMode dtm;

    private void Start()
    {
        Camera cam = GetComponent<Camera>();
        dtm = DepthTextureMode.Depth;
        cam.depthTextureMode = dtm;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
