Shader "Book ReImplementations/Chapter_6.5/BlinnPhong"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1, 1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20.0
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
                float3 noraml : NORMAL;
            };

            struct v2f
            {
                float4 pos_clip : SV_POSITION;
                float3 normal_world:TEXCOORD0;
                float4 pos_world:TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos_clip = UnityObjectToClipPos(v.vertex);
                o.normal_world = mul(v.noraml,(float3x3)unity_WorldToObject);
                o.pos_world = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag(v2f i) :SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                float3 normal = normalize(i.normal_world);
                float3 lightDir =  normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(lightDir,normal));
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world.xyz);
                float3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,normal)),_Gloss);

                return fixed4(specular+diffuse+ambient,1.0);
            }
            
            ENDCG
        }
    }

    Fallback "Specular"
}
