Shader "Unity Shaders Book/Chapter_6.3_AmbientEmission"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {} // 主纹理（基础颜色贴图），默认白色
        _EmissionColor ("Emission Color", Color) = (0, 0, 0, 1) // 自发光颜色（默认黑色表示不发光）
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" } // 标记为不透明物体渲染
        
        CGPROGRAM
        #pragma surface surf Standard // 使用Standard表面着色器

        sampler2D  _MainTex;
        fixed4 _EmissionColor;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf(Input input, inout SurfaceOutputStandard o)
        {
            o.Albedo = tex2D(_MainTex, input.uv_MainTex).rgb; // 物体表面的基础颜色来自纹理采样
            o.Emission = _EmissionColor.rgb;// 使物体产生自发光效果，颜色强度由_EmissionColor控制
        }
        ENDCG
    }
    
    FallBack "Diffuse"
}
