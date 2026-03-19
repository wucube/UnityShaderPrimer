Shader "Book Examples/Chapter_11.2.1/Image Sequence Animation"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Image Sequence", 2D) = "white" {}
        _HorizontalAmount ("Horizontal Amount", Float) = 4
        _VerticalAmount ("Vertical Amount", Float) = 4
        _Speed ("Speed", Range(1, 100)) = 30
    }
    
    SubShader
    {
        Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma  fragment frag
            
            #include "UnityCG.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct  a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return  o;
            }
            
            fixed4 frag(v2f i):SV_Target
            {
                //1. 计算当前时间对应的“离散帧索引” (向下取整)
                float frameIndex = floor(_Time.y * _Speed);
                // 2. 根据总帧数，计算当前所在的行数 (row) 与列数 (column)
                float row = floor(frameIndex / _HorizontalAmount);
                float column = frameIndex - row * _HorizontalAmount;
                
                // Unity 中纹理坐标竖直方向的顺序（从下到上递增）和序列帧纹理中的顺序（播放顺序是从上到下）是相反的 
                //half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
                //uv.x += column / _HorizontalAmount;
                //uv.y -= row / _VerticalAmount;
                
                // 3. 构建真正的采样坐标
                // 思想：先将基础 UV 平移到当前子图的起始点，然后再按比例缩放 UV
                half2 uv = i.uv + half2(column, -row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;
                
                fixed4 c = tex2D(_MainTex,uv);
                c.rgb *= _Color;
                
                return c;
            }
            
            ENDCG
        } 
    }
    Fallback "Transparent/VertexLit"
}
