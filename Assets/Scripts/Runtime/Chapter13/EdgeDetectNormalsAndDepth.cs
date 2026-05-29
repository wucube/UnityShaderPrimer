using UnityEngine;

public class EdgeDetectNormalsAndDepth : PostEffectBase
{
    public Shader EdgeDetectShader;
    
    private Material _edgeDetectMaterial;
    public Material EdgeDetectMaterial => CheckShaderAndCreateMaterial(EdgeDetectShader, _edgeDetectMaterial);
    
    private Camera _camera;

    public Camera Camera
    {
        get
        {
            if (_camera == null) _camera = GetComponent<Camera>();
            return _camera;
        }
    }

    [Range(0.0f, 1.0f)]
    public float EdgeOnly;
    
    public Color EdgeColor = Color.black;

    public Color BackgroundColor = Color.white;

    public float SampleDistance = 1.0f;

    // 深度灵敏度（值越大，越微小的深度落差也会被强制识别为边缘）
    public float SensitivityDepth = 1.0f;

    // 法线灵敏度（值越大，越微小的表面转角也会被强制识别为边缘）
    public float SensitivityNormals = 1.0f;

    protected override void OnEnable()
    {
        base.OnEnable();
        Camera.depthTextureMode |= DepthTextureMode.DepthNormals;
    }
    
    private static readonly int s_EdgeOnlyId = Shader.PropertyToID("_EdgeOnly");
    private static readonly int s_EdgeColorId = Shader.PropertyToID("_EdgeColor");
    private static readonly int s_BackgroundColorId = Shader.PropertyToID("_BackgroundColor");
    private static readonly int s_SampleDistanceId = Shader.PropertyToID("_SampleDistance");
    private static readonly int s_SensitivityId = Shader.PropertyToID("_Sensitivity");

    
    [ImageEffectOpaque] //强制该特效在“不透明物体渲染完，半透明物体尚未渲染”的间隙提前执行。
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Material mat = EdgeDetectMaterial;
        if (mat != null)
        {
            mat.SetFloat(s_EdgeOnlyId, EdgeOnly);
            mat.SetColor(s_EdgeColorId, EdgeColor);
            mat.SetColor(s_BackgroundColorId, BackgroundColor);
            mat.SetFloat(s_SampleDistanceId, SampleDistance);
            
            // 将法线灵敏度和深度灵敏度打包进一个 Vector4 传给 Shader 
            // （x 对应 Shader 里的 _Sensitivity.x，y 对应 _Sensitivity.y）
            mat.SetVector(s_SensitivityId, new Vector4(SensitivityNormals, SensitivityDepth, 0.0f, 0.0f));
            
            Graphics.Blit(source, destination, mat);
        } else {
            Graphics.Blit(source, destination);
        }
    }
}
