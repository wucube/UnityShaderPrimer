Shader "Book Examples/Chapter_14.2/Hatching Texture2DArray"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _TileFactor("Tile Factor", Float) = 1
        _Outline("Outline", Range(0,1)) = 0.1
        _HatchArray("Hatch Texture2DArray", 2DArray) = "" {}
        // 整体控制 hatch 线条参与度，0 时完全变白，1 时完全使用 hatch 纹理
        _HatchStrength("Hatch Strength", Range(0, 1)) = 1
        // 必须和 Texture2DArray 实际层数保持一致；Hatch0 最亮，最后一层最暗
        _HatchLayerCount("Hatch Layer Count", Float) = 6
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        UsePass "Book Examples/Chapter_14.1/Toon Shading/OUTLINE"

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            float _TileFactor;
            float _HatchStrength;
            float _HatchLayerCount;
            UNITY_DECLARE_TEX2DARRAY(_HatchArray);

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float hatchFactor : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy * _TileFactor;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed diff = saturate(dot(worldLightDir, worldNormal));

                // 把 [0,1] 的漫反射强度扩展成“hatch 层数 + 1”个区间
                // 多出来的 1 个区间用于高光纯白区域，避免亮面仍然出现素描线
                o.hatchFactor = diff * (max(_HatchLayerCount, 2.0) + 1.0);

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 把明暗值映射到 Texture2DArray 层级
                // 数组约定：0 是最亮的 Hatch0，maxLayer 是最暗层；所以光照越亮，layer 越小
                float layerCount = max(_HatchLayerCount, 2.0);
                float maxLayer = layerCount - 1.0;
                float t = saturate(i.hatchFactor / maxLayer);
                float layer = lerp(maxLayer, 0.0, t);

                // 优化核心：每个像素只采样当前层和相邻层，而不是像原版那样固定采样 6 张纹理
                float layer0 = floor(layer);
                float layer1 = min(layer0 + 1.0, maxLayer);
                // frac(layer) 表示当前像素落在两层之间的位置，用它做线性混合
                float blend = frac(layer);

                fixed4 hatch0 = UNITY_SAMPLE_TEX2DARRAY(_HatchArray, float3(i.uv, layer0));
                fixed4 hatch1 = UNITY_SAMPLE_TEX2DARRAY(_HatchArray, float3(i.uv, layer1));
                fixed4 hatchColor = lerp(hatch0, hatch1, blend);

                // 整体控制线条强度：降低强度时，hatch 纹理会整体向白色淡出
                hatchColor.rgb = lerp(fixed3(1, 1, 1), hatchColor.rgb, _HatchStrength);
                // 高光区单独混入白色，对应 hatchFactor 超过最亮 hatch 层之后的额外留白区间
                float whiteBlend = smoothstep(maxLayer, maxLayer + 1.0, i.hatchFactor);
                hatchColor.rgb = lerp(hatchColor.rgb, fixed3(1, 1, 1), whiteBlend);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}
