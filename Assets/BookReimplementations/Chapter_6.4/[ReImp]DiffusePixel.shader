Shader "Book Reimplementations/Chapter_6.4/DiffusePixel"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1.0, 1.0, 1.0, 1.0)
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
                float4 vertex :POSITION;
                float3 noraml :NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                
                float3 worldNormal:COLOR0;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(v.noraml,(float3x3)unity_WorldToObject);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                float3 world_normal = normalize(i.worldNormal);
                float3 world_light = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*saturate(dot(world_normal,world_light));

                fixed3 color = diffuse + ambient;
                
                return fixed4(color,1.0); 
            }
            ENDCG
        }
    }

    Fallback "Diffuse"
}
