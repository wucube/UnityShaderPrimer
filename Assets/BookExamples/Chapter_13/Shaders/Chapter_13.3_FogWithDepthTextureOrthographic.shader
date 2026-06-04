Shader "Book Examples/Chapter_13.3/Fog With Depth Texture Orthographic"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _FogDensity("Fog Density", Float) = 1.0
        _FogColor("Fog Color", Color) = (1,1,1,1)
        _FogStart("Fog Start", Float) = 0.0
        _FogEnd("Fog End", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include  "UnityCG.cginc"
        
        float4x4 _FrustumCornersRay;
        
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        half _FogDensity;
        fixed4 _FogColor;
        float _FogStart;
        float _FogEnd;
        
        // 摄像机正前方方向
        float3 _CameraForward;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
            float4 interpolatedRay : TEXCOORD2;
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
            
            int index = 0;
            if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
            {
                index = 0;
            } else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
                index = 1;
            } else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
                index = 2;
            } else {
                index = 3;
            }
            
            #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0) 
                index = 3 - index;
            #endif
            
            o.interpolatedRay = _FrustumCornersRay[index];
            
            return o;
        }
        
        fixed4 frag(v2f i) : SV_Target
        {
            // 1. 获取原始深度值 (0 到 1 之间)
            float rawDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
            
            // 2. 跨平台处理：DirectX 平台的深度是反的 (近处是1，远处是0)，需要翻转回正常进度条
            #if UNITY_REVERSED_Z
                rawDepth = 1.0 - rawDepth;
            #endif
            
            // 3. 将 [0, 1] 的进度条转换为真实的物理距离
            // _ProjectionParams.y 是 Near，_ProjectionParams.z 是 Far
            float depthDistance = _ProjectionParams.y + rawDepth * (_ProjectionParams.z - _ProjectionParams.y);
            
            // 4. 正交坐标重构公式：相机位置 + 屏幕XY偏移量 + 相机朝向 * 物理距离
            float3 worldPos = _WorldSpaceCameraPos + i.interpolatedRay.xyz + _CameraForward * depthDistance;
            
            float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
            fogDensity = saturate(fogDensity  * _FogDensity);
            
            fixed4 finalColor = tex2D(_MainTex, i.uv);
            finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb , fogDensity);
            
            return finalColor;
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