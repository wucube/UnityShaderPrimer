Shader "Book Reimplementations/Chapter_6.5/Specular Pixel-Level"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
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
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 normal_world : TEXCOORD0;
                float3 pos_world : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal_world = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                o.pos_world = normalize(mul(unity_ObjectToWorld,v.vertex).xyz);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                float3 light_world = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.normal_world,light_world));

                float3 relectDir = normalize(reflect(-light_world,i.normal_world));
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world.xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(viewDir,relectDir)),_Gloss);

                return fixed4(specular+diffuse+ambient,1.0);
            }

            
            ENDCG
        }
    }
    
    Fallback "Specular"
}
