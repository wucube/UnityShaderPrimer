// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Book Examples/Chapter_6.4/Diffuse Vertex-Level"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            
            fixed4 _Diffuse;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //把顶点位置从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //通过内置变量  UNITY _LIGHTMODEL_AMBIENT 得到环境光部分。
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 world_normal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                fixed3 world_light = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(world_normal,world_light));

                o.color = ambient + diffuse;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                return fixed4(i.color,1.0);
            }
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}
