using UnityEngine;

public class MotionBlur : PostEffectBase
{
    public Shader MotionBlurShader;
    
    private Material _motionBlurMaterial;

    private Material MotionBlurMaterial {  
        get {
            _motionBlurMaterial = CheckShaderAndCreateMaterial(MotionBlurShader, _motionBlurMaterial);
            return _motionBlurMaterial;
        }  
    }

    [Range(0.0f, 0.9f)]
    public float BlurAmount = 0.5f;
	
    // 跨帧持久化的累计缓存
    private RenderTexture _accumulationTexture;
    
    private static readonly int BlurAmountId = Shader.PropertyToID("_BlurAmount");

    // 显存生命周期终点：脚本禁用时必须安全释放
    private void OnDisable() {
        if (_accumulationTexture != null)
        {
            _accumulationTexture.Release(); // 强制释放 GPU VRAM
            DestroyImmediate(_accumulationTexture);
            _accumulationTexture = null;
        }
    }

    private void OnRenderImage (RenderTexture source, RenderTexture destination) {
        Material mat = MotionBlurMaterial;
        if (mat != null) {
            // Create the accumulation texture
            if (_accumulationTexture == null || _accumulationTexture.width != source.width || _accumulationTexture.height != source.height) {
                
                OnDisable(); // 复用清理逻辑
                
                // 必须继承 source.format (如 DefaultHDR)，防止高光在累计过程中被截断发灰
                _accumulationTexture = new RenderTexture(source.width, source.height, 0, source.format)
                {
                    hideFlags = HideFlags.HideAndDontSave
                };
                
                // 首次运行，直接将当前画面拷入缓存打底
                Graphics.Blit(source, _accumulationTexture);
            }
            
            mat.SetFloat(BlurAmountId, 1.0f - BlurAmount);
            
            // 利用 mat 将当前画面 (source) 半透明叠加到缓存 (_accumulationTexture) 上
            Graphics.Blit (source, _accumulationTexture, mat);
            
            // 将叠加完毕的缓存输出到最终屏幕
            Graphics.Blit (_accumulationTexture, destination);
        } 
        else 
        {
            Graphics.Blit(source, destination);
        }
    }
}
