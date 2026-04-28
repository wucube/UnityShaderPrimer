using UnityEngine;

public class BrightnessSaturationAndContrast : PostEffectBase
{
    public Shader BriSatConShader;
    
    private Material _briSatConMaterial;
    private Material BriSatConMaterial
    {
         get
        {
            _briSatConMaterial = CheckShaderAndCreateMaterial(BriSatConShader, _briSatConMaterial);
            return _briSatConMaterial;
        }
    }

    [Range(0.0f, 3.0f)]
    public float Brightness = 1.0f;

    [Range(0.0f, 3.0f)] 
    public float Saturation = 1.0f;
    
    [Range(0.0f, 3.0f)]
    public float Contrast = 1.0f;
    
    // 提前将 Shader 属性名转换为整型 ID 缓存起来
    private static readonly int s_BrightnessId = Shader.PropertyToID("_Brightness");
    private static readonly int s_SaturationId = Shader.PropertyToID("_Saturation");
    private static readonly int s_ContrastId = Shader.PropertyToID("_Contrast");
    
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // 性能优化核心：每帧只获取一次材质实例并缓存到局部变量中
        Material mat = BriSatConMaterial;
        
        if (mat != null)
        {
            mat.SetFloat(s_BrightnessId, Brightness);
            mat.SetFloat(s_SaturationId, Saturation);
            mat.SetFloat(s_ContrastId, Contrast);
            
            Graphics.Blit(source, destination, mat);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
