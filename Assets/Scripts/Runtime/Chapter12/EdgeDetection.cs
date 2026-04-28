using UnityEngine;

public class EdgeDetection : PostEffectBase
{
    public Shader EdgeDetectShader;
    private Material _edgeDetectMaterial;
    private Material EdgeDetectMaterial {  
        get {
            _edgeDetectMaterial = CheckShaderAndCreateMaterial(EdgeDetectShader, _edgeDetectMaterial);
            return _edgeDetectMaterial;
        }  
    }

    [Range(0.0f, 1.0f)]
    public float EdgesOnly = 0.0f;
    public Color EdgeColor = Color.black;
    public Color BackgroundColor = Color.white;

    // 缓存 Shader 属性 ID
    private static readonly int s_EdgeOnlyId = Shader.PropertyToID("_EdgeOnly");
    private static readonly int s_EdgeColorId = Shader.PropertyToID("_EdgeColor");
    private static readonly int s_BackgroundColorId = Shader.PropertyToID("_BackgroundColor");
    
    private void OnRenderImage (RenderTexture source, RenderTexture destination) {
        Material mat = EdgeDetectMaterial;
        
        if (mat != null) {
            mat.SetFloat(s_EdgeOnlyId, EdgesOnly);
            mat.SetColor(s_EdgeColorId, EdgeColor);
            mat.SetColor(s_BackgroundColorId, BackgroundColor);

            Graphics.Blit(source, destination, mat);
        } else {
            Graphics.Blit(source, destination);
        }
    }
}
