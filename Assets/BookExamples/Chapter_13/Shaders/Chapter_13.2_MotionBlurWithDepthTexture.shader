Shader "Book Examples/Chapter_13_2/MotionBlur With Depth Texture"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include  "UnityCG.cginc"
        
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        float4x4 _CurrentViewProjectionInverseMatrix;
        float4x4 _PreviousViewProjectionMatrix;
        half _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
        };
        
        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            
            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;
            
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0) 
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif
            
            return o;
        }
        
        fixed4 frag(v2f i) : SV_Target
        {
            // 1. 获取当前像素的非线性深度值 (0 到 1 之间)
            float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
            // 修复反向Z (现代图形API兼容)
            #if defined(UNITY_REVERSED_Z)
            nonLinearDepth = 1.0 - nonLinearDepth;
            #endif
            
            // ndcPos is the viewport position at this pixel in the range -1 to 1.
            // 2. 组装 NDC (归一化设备坐标)，将 UV 和 深度 都映射到 [-1, 1] 区间
            float4 ndcPos = float4(i.uv.x * 2 - 1 , i.uv.y * 2 - 1, nonLinearDepth * 2 - 1, 1);
            // 3. 乘以视投逆矩阵，将屏幕 NDC 坐标还原为 3D 世界坐标 (此时还是未除以W的齐次坐标)
            float4 D = mul(_CurrentViewProjectionInverseMatrix, ndcPos);
            // 4. 执行透视除法 (除以 w 分量)，得到真正的世界坐标
            float4 worldPos = D / D.w;
            
            // 5. 计算速度向量
            // Current viewport position(当前帧的 NDC 坐标) 
            float4 currentPos = ndcPos;
            // 用上一帧的视投矩阵将当前世界坐标再转回为上一帧的屏幕齐次坐标
            // Use the world position and transform by the previous view-projection matrix.  
            float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
            // 执行透视除法，得到上一帧的屏幕 NDC 坐标
            previousPos /= previousPos.w;
            
            // 计算两帧之间的屏幕位置差，除以 2 是因为 NDC 坐标区间长度为 2 (从 -1 到 1)
            float2 velocity = (currentPos.xy - previousPos.xy) / 2.0;
            
            // 6. 顺着速度方向进行模糊采样
            float2 uv = i.uv;
            // 第 1 次采样：读取当前像素原本的颜色
            float4 c = tex2D(_MainTex, uv);
            // 将 UV 坐标向着速度方向推进一步
            uv += velocity * _BlurSize;
            // 开启循环进行后续采样
            for (int it = 1; it < 3; it++, uv += velocity * _BlurSize)
            {
                float4 currentColor = tex2D(_MainTex, uv);
                // 把新采样的颜色叠加进来
                c += currentColor;
            }
            
            // 求平均值
            c /= 3 ;
            
            return  fixed4(c.rgb, 1.0);
            
        }
       
        ENDCG

        Pass
        {
            ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            ENDCG
        }
    }
    FallBack Off
}