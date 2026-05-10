using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectBase
{
    public Shader MotionBlurShader;
    
    private Material _motionBlurMaterial;
    public Material MotionBlurMaterial => CheckShaderAndCreateMaterial(MotionBlurShader, _motionBlurMaterial);
   
    private Camera _camera;
    public Camera Camera => _camera ??= GetComponent<Camera>();

    [Range(0.0f, 1.0f)]
    public float BlurSize = 0.5f;

    private Matrix4x4 _previousViewProjectionMatrix;

    protected override void OnEnable()
    {
        base.OnEnable();
        
        Camera.depthTextureMode |= DepthTextureMode.Depth;
        _previousViewProjectionMatrix = Camera.projectionMatrix * Camera.worldToCameraMatrix;
    }
    
    private static readonly int s_BlurSizeId = Shader.PropertyToID("_BlurSize");
    private static readonly int s_PreviousViewProjectionMatrixId = Shader.PropertyToID("_PreviousViewProjectionMatrix");
    private static readonly int s_CurrentViewProjectionInverseMatrixId = Shader.PropertyToID("_CurrentViewProjectionInverseMatrix");

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Material mat = MotionBlurMaterial;
        if (mat != null)
        {
            mat.SetFloat(s_BlurSizeId, BlurSize);
            mat.SetMatrix(s_PreviousViewProjectionMatrixId, _previousViewProjectionMatrix);

            var currentViewProjectionMatrix = Camera.projectionMatrix * Camera.worldToCameraMatrix;
            var currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            mat.SetMatrix(s_CurrentViewProjectionInverseMatrixId,currentViewProjectionInverseMatrix);
            _previousViewProjectionMatrix = currentViewProjectionMatrix;
            
            Graphics.Blit(source, destination, mat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
        
    }
}
