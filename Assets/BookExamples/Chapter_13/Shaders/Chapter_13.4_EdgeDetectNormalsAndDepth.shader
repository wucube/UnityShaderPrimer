Shader "Custom/Chapter_13.4/Edge Detect Normals And Depth"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // 调节边缘的显示强度，1 为仅显示边缘，0 为仅显示原图
        _EdgeOnly ("Edge Only", Float) = 1.0
        // 描边的颜色
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        // 纯色背景的颜色（当 _EdgeOnly 为 1 时作为底色）
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
        // 采样距离（描边粗细）。值越大，越能检测出宽的边缘
        _SampleDistance ("Sample Distance", Float) = 1.0
        // 灵敏度控制：x分量控制法线灵敏度，y分量控制深度灵敏度。值越大，越容易被判定为边缘
        _Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)
    }
    SubShader
    {
        CGINCLUDE
        
        #include "UnityCG.cginc"
        
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        fixed _EdgeOnly;
        fixed4 _EdgeColor;
        fixed4 _BackgroundColor;
        float _SampleDistance;
        half4 _Sensitivity;
        
        // Unity 内置生成的深度+法线纹理
        sampler2D _CameraDepthNormalsTexture;

        struct v2f
        {
            float4 pos : SV_POSITION;
            // 数组大小为 5：索引 0 存中心 UV，1~4 存对角线上的四个点 UV
            half2 uv[5] : TEXCOORD0;
        };
        
        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            half2 uv = v.texcoord;
            // 中心像素的 UV，用于最后采样原图颜色
            o.uv[0] = uv;
            
            // 【跨平台防坑】：DirectX 开启 MSAA 时，主纹理会被翻转，此处强行把深度UV翻转回来对齐
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0)
                uv.y = 1 - uv.y;
            #endif
            
            // 【Roberts 交叉采样法】：不去采样十字形，而是采样对角线的四个像素
            // _MainTex_TexelSize.xy 是单个像素的大小，乘以 _SampleDistance 控制偏移步长
            o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _SampleDistance;   // 右上
            o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _SampleDistance; // 左下
            o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _SampleDistance;  // 左上
            o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _SampleDistance;  // 右下
            
            return o;
        }
        
        // 核心裁决函数：检查对角线上的两个像素是否属于同一个平面
        half CheckSame(half4 center, half4 sample)
        {
            half2 centerNormal = center.xy;
            float centerDepth = DecodeFloatRG(center.zw);
            half2 sampleNormal = sample.xy;
            float sampleDepth = DecodeFloatRG(sample.zw);
            
            // 1. 法线差异判定
            // 【性能 Hack】：不去解码法线求点积，直接对比压缩状态下的 XY 分量差异。
            // 如果 A 像素和 B 像素在同一个平滑的平面上，它们在深度法线图里的 xy 编码值理应是极其接近的。
            half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
            // 如果差异之和小于阈值 0.1，则认为法线相同（返回 1）
            int isSameNormal = diffNormal.x + diffNormal.y < 0.1;
            
            // 2. 深度差异判定
            float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
            // 【防远景噪点 Hack】：阈值不写死，而是乘以 centerDepth。
            // 距离摄像机越远，允许的深度误差越大，防止远处的浮点数精度问题导致满屏黑线
            int isSameDepth = diffDepth < 0.1 * centerDepth;
            
            // 只有当法线和深度“同时”被判定为相同时，才返回 1.0（表示不是边缘）
            return isSameNormal * isSameDepth ? 1.0 : 0.0;
        }
        
        fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target
        {
            // 提取刚才在顶点着色器算好的对角线四个角的 深度+法线 数据
            half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]); // 右上
            half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]); // 左下
            half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]); // 左上
            half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]); // 右下
            
            // 初始假定该像素不是边缘 (edge = 1)
            half edge = 1.0;
            
            // 进行两组交叉比对：只要有任意一组检测到差异 (返回 0)，连乘结果就会让 edge 变成 0
            edge *= CheckSame(sample1, sample2); // 比对 1：右上 vs 左下
            edge *= CheckSame(sample3, sample4); // 比对 2：左上 vs 右下
            
            // 颜色混合策略
            // withEdgeColor: 原图上叠加边缘 (edge为0时取_EdgeColor，为1时取_MainTex原色)
            fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
            // onlyEdgeColor: 纯色背景上叠加边缘 (美术提取线稿用)
            fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
            
            // 最终通过 _EdgeOnly 滑动条，在这两种显示模式之间进行平滑过渡
            return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
        }
        
        ENDCG

        Pass
        {
            // 全屏后处理标准状态：关闭深度测试，关闭剔除，关闭深度写入
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment fragRobertsCrossDepthAndNormal
            
            ENDCG
        }
    }
    FallBack Off
}
