using UnityEngine;

[ExecuteInEditMode]
public class ProceduralTextureGenerator : MonoBehaviour
{
    [SerializeField] private Material _material;
    
    [Header("Texture Settings")]
    [SerializeField] private int _textureWidth = 512;
    
    [Header("Color Settings")]
    [SerializeField] private Color _backgroundColor = Color.white;
    [SerializeField] private Color _circleColor = Color.yellow;
    
    [Header("Blur Settings")]
    [SerializeField] private float _blurFactor = 2.0f;

    private Texture2D _generatedTexture;

    private void Start()
    {
        if (_material == null)
        {
            if (TryGetComponent<Renderer>(out var renderer))
            {
                _material = renderer.sharedMaterial;
            }
            else
            {
                Debug.LogWarning("Cannot find a renderer.");
                return;
            }
        }

        UpdateTexture();
    }

    private void OnValidate()
    {
        if (_material == null && TryGetComponent<Renderer>(out var renderer))
        {
            _material = renderer.sharedMaterial;
        }

        if (_material != null)
        {
            UpdateTexture();
        }
    }

    private void UpdateTexture()
    {
        if (_material == null) return;

        // Cleanup old texture
        if (_generatedTexture != null)
        {
            DestroyImmediate(_generatedTexture);
        }

        _generatedTexture = GenerateProceduralTexture();
        _material.SetTexture("_MainTex", _generatedTexture);
    }

    private Texture2D GenerateProceduralTexture()
    {
        Texture2D texture = new Texture2D(_textureWidth, _textureWidth);
        Color32[] pixels = new Color32[_textureWidth * _textureWidth];

        float circleInterval = _textureWidth / 4.0f;
        float radius = _textureWidth / 10.0f;
        float edgeBlur = 1.0f / _blurFactor;

        // Pre-compute circle centers
        Vector2[] circleCenters = new Vector2[9];
        int centerIndex = 0;
        for (int i = 0; i < 3; i++)
        {
            for (int j = 0; j < 3; j++)
            {
                circleCenters[centerIndex++] = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));
            }
        }

        // Generate pixels using Color32 for better performance
        for (int h = 0; h < _textureWidth; h++)
        {
            for (int w = 0; w < _textureWidth; w++)
            {
                Color pixel = _backgroundColor;
                Vector2 pixelPos = new Vector2(w, h);

                // Draw nine circles
                for (int i = 0; i < 9; i++)
                {
                    // 计算当前像素到圆心的距离，减去半径
                    // dist > 0：在圆外
                    // dist = 0：在圆边缘
                    // dist < 0：在圆内
                    float dist = Vector2.Distance(pixelPos, circleCenters[i]) - radius;
                    
                    // 创建透明版本的当前像素（保留 RGB，alpha=0）
                    Color transparentPixel = new Color(pixel.r, pixel.g, pixel.b, 0.0f);
                    
                    // SmoothStep(0, 1, dist * edgeBlur) 实现边缘渐变：
                    // - dist < 0（圆内）：返回 0，Lerp 结果接近 circleColor
                    // - dist = 0（边缘）：返回 0.5，混合 50%
                    // - dist > 0（圆外）：返回 1，Lerp 结果接近 transparentPixel
                    // edgeBlur 控制渐变范围：值越小，渐变越宽
                    Color color = Color.Lerp(_circleColor, transparentPixel, Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));
                    
                    // 用 alpha 混合：把圆形颜色叠加到当前像素上
                    // color.a 决定混合强度（圆内 alpha 高，圆外 alpha 低）
                    pixel = Color.Lerp(pixel, color, color.a);
                }

                pixels[h * _textureWidth + w] = pixel;
            }
        }

        texture.SetPixels32(pixels);
        texture.Apply();

        return texture;
    }
}
