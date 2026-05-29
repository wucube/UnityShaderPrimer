using UnityEngine;

public class FogWithDepthTexture : PostEffectBase
{
    public Shader FogShader;

    private Material _fogMaterial;
    public Material FogMaterial => CheckShaderAndCreateMaterial(FogShader, _fogMaterial);

    private Camera _camera;

    public Camera Camera
    {
        get
        {
            if (_camera == null) _camera = GetComponent<Camera>();
            return _camera;
        }
    }
    
    private Transform _cameraTransform;

    public Transform CameraTransform
    {
        get
        {
            if (_cameraTransform == null) _cameraTransform = GetComponent<Transform>();
            return _cameraTransform;
        }
    }

    [Range(0.0f, 3.0f)]
    public float FogDensity = 1.0f;

    public Color FogColor = Color.white;

    public float FogStart = 0.0f;
    public float FogEnd = 2.0f;

    private static readonly int s_FrustumCornersRayId  = Shader.PropertyToID("_FrustumCornersRay");
    private static readonly int s_FogDensityId  = Shader.PropertyToID("_FogDensity");
    private static readonly int s_FogColorId  = Shader.PropertyToID("_FogColor");
    private static readonly int s_FogStartId  = Shader.PropertyToID("_FogStart");
    private static readonly int s_FogEndId  = Shader.PropertyToID("_FogEnd");
    
     protected override void OnEnable()
    {
        base.OnEnable();
        
        Camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Material mat = FogMaterial;
        if (mat != null)
        {
            // 创建 4 x 4 的单位矩阵
            Matrix4x4 frustumCorners = Matrix4x4.identity;
            
            float fov = Camera.fieldOfView;
            float near =  Camera.nearClipPlane;
            float aspect = Camera.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = CameraTransform.right * halfHeight * aspect;
            Vector3 toTop = CameraTransform.up * halfHeight;
            
            Vector3 topLeft = CameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;
            
            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = CameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = CameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = CameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;
            
            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            mat.SetMatrix(s_FrustumCornersRayId, frustumCorners);
            
            mat.SetFloat(s_FogDensityId, FogDensity);
            mat.SetColor(s_FogColorId, FogColor);
            mat.SetFloat(s_FogStartId,FogStart);
            mat.SetFloat(s_FogEndId, FogEnd);
            
            Graphics.Blit(source, destination, mat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
