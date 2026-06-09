Shader "Book Examples/Chapter_14.2/Hatching Texture 3D"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _TileFactor("Tile Factor", Float) = 1
        _Outline("Outline", Range(0,1)) = 0.1
        // 实验版：把多张 hatch 纹理沿 z 方向烘焙进一张 3D 纹理
        // xy 仍然是普通纹理坐标，z 用来表示当前应该采样的明暗层
        _Hatch3D("Hatch 3D Texture", 3D) = "white" {}
        // 烘焙进 3D 纹理的 hatch 层数，需要和 Baker 中拖入的纹理数量一致
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
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            float _TileFactor;
            float _HatchLayerCount;
            sampler3D _Hatch3D;

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
                // 3D 纹理的 z 采样坐标，用来在 Hatch0~最后一层之间连续过渡
                // 注意：这是单次 3D 连续采样，不等同于原版 6 张 2D 纹理的权重混合
                float zDepth : TEXCOORD2;
                // 高光区域的留白混合权重；越接近 1，最终颜色越接近白色
                float whiteBlend : TEXCOORD3;
                SHADOW_COORDS(4)
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
                
                float layerCount = max(_HatchLayerCount, 2.0);
                float maxLayer = layerCount - 1.0;
                // 把 [0,1] 的漫反射强度扩展成“hatch 层数 + 1”个明暗区间
                // 多出来的 1 个区间用于高光留白，避免亮面仍然出现明显素描线
                float hatchFactor = diff * (layerCount + 1.0);
                
                // 高光留白仍然用连续方式处理，因为 3D 版本本质上是单次采样近似
                o.whiteBlend = smoothstep(maxLayer, maxLayer + 1.0, hatchFactor);

                // 使用固定线性映射把明暗区间转换到 3D 纹理深度，不再额外暴露调参项
                // 数组约定：Hatch0 是最亮层，最后一层是最暗层；所以光照越亮，采样 z 越靠前
                // 这里采样每层中心点附近：Hatch0 位于 z = 0.5 / layerCount，最后一层位于 z = (maxLayer + 0.5) / layerCount
                float t = saturate(hatchFactor / maxLayer);
                float layer = lerp(maxLayer + 0.5, 0.5, t);
                // Clamp 到合法层中心范围，避免 z 方向采到边界外或重复包裹
                o.zDepth = clamp(layer / layerCount, 0.5 / layerCount, (maxLayer + 0.5) / layerCount);
                
                TRANSFER_SHADOW(o);
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                // 单次 3D 纹理采样：xy 控制线条平铺，z 控制当前素描密度层
                // 这种方式采样次数少，但视觉上会比原版 6 权重混合更连续、更规则
                fixed4 hatchColor = tex3D(_Hatch3D, float3(i.uv, i.zDepth));
                // 在高光区域继续混入白色，以连续方式近似原版的留白逻辑
                hatchColor.rgb = lerp(hatchColor.rgb, fixed3(1, 1, 1), i.whiteBlend);
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(hatchColor.rgb * _Color.rgb * atten, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}