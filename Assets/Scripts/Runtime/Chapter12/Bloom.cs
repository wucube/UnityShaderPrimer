using UnityEngine;

public class Bloom : PostEffectBase
{
    public Shader BloomShader;
    private Material _bloomMaterial;
    private Material BloomMaterial
    {  
        get {
            _bloomMaterial = CheckShaderAndCreateMaterial(BloomShader, _bloomMaterial);
            return _bloomMaterial;
        }  
    }

    // Blur iterations - larger number means more blur.
    [Range(0, 4)]
    public int Iterations = 3;
	
    // Blur spread for each iteration - larger value means more blur
    [Range(0.2f, 3.0f)]
    public float BlurSpread = 0.6f;

    [Range(1, 8)]
    public int DownSample = 2;

    // 配合 HDR，阈值上限可以突破 1.0
    [Range(0.0f, 4.0f)]
    public float LuminanceThreshold = 0.6f;

    private static readonly int s_LuminanceThresholdId = Shader.PropertyToID("_LuminanceThreshold");
    private static readonly int s_BlurSizeId = Shader.PropertyToID("_BlurSize");
    private static readonly int s_BloomTexId = Shader.PropertyToID("_Bloom");
    
    private void OnRenderImage (RenderTexture source, RenderTexture destination) {
        Material mat = BloomMaterial;
        
        if (mat != null) {
            mat.SetFloat(s_LuminanceThresholdId, LuminanceThreshold);

            int rtW = source.width/DownSample;
            int rtH = source.height/DownSample;
			
            // 必须使用源纹理的格式 (source.format) 来支持 HDR (通常为 DefaultHDR)
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0,source.format);
            buffer0.filterMode = FilterMode.Bilinear;
			
            // Pass 0: 提取高光区域存入 buffer0
            Graphics.Blit(source, buffer0, mat, 0);
			
            // 迭代执行高斯模糊 (借用 Pass 1 & Pass 2)
            for (int i = 0; i < Iterations; i++) {
                mat.SetFloat(s_BlurSizeId, 1.0f + i * BlurSpread);
				
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
				
                // Render the vertical pass
                Graphics.Blit(buffer0, buffer1, mat, 1);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
				
                // Render the horizontal pass
                Graphics.Blit(buffer0, buffer1, mat, 2);
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            mat.SetTexture (s_BloomTexId, buffer0);  
            Graphics.Blit (source, destination, mat, 3);  

            RenderTexture.ReleaseTemporary(buffer0);
        } else {
            Graphics.Blit(source, destination);
        }
    }
}
