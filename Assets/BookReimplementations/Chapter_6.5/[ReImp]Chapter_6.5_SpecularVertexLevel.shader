Shader "Book Reimplementations/Chapter_6.5/Specular Vertex-Level"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8,256)) = 8
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

            fixed3 _Diffuse;
            fixed3 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 normal_world = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                float3 light_dir_world = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(light_dir_world,normal_world));

                //TODO 数学原理
                float3 relect_light_dir = reflect(-light_dir_world,normal_world);
                //TODO 数学原理
                fixed3 view_dir  = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);
                //TODO 高光反射公式
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(view_dir,relect_light_dir)),_Gloss);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                o.color = specular + diffuse +ambient;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color,1.0);
            }
            
            ENDCG
        }
    }

    Fallback "Specular"
}
