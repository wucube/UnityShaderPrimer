using UnityEngine;

public class FogWithDepthTextureOrthographic : PostEffectBase
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
    private static readonly int s_CameraForward = Shader.PropertyToID("_CameraForward");
    
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
            
            float orthoSize = Camera.orthographicSize;
            float aspect = Camera.aspect;

            Vector3 toRight = CameraTransform.right * orthoSize * aspect;
            Vector3 toTop = CameraTransform.up * orthoSize;

            // 3. 计算四个角的【起点偏移量】（注意：不需要乘 Near 了，也不用算 Forward！）
            Vector3 topLeft = toTop - toRight;
            Vector3 topRight = toRight + toTop;
            Vector3 bottomLeft = -toTop - toRight;
            Vector3 bottomRight = toRight - toTop;
            
            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            mat.SetMatrix(s_FrustumCornersRayId, frustumCorners);
            
            mat.SetFloat(s_FogDensityId, FogDensity);
            mat.SetColor(s_FogColorId, FogColor);
            mat.SetFloat(s_FogStartId,FogStart);
            mat.SetFloat(s_FogEndId, FogEnd);
            mat.SetVector(s_CameraForward,CameraTransform.forward);
            
            Graphics.Blit(source, destination, mat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}

