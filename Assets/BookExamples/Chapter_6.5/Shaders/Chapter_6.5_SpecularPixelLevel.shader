Shader "Book Examples/Chapter_6.5/Specular Pixel-Level"
{
    Properties
    {
        // 漫反射颜色
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        // 高光反射颜色
        _Specular("Specular",Color) = (1,1,1,1)
        // 高光指数（控制光斑大小）
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

            // 属性对应的变量声明
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            // 输入结构体：顶点位置和法线
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            
            // 输出结构体：裁剪空间位置 + 计算的颜色
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 world_normal : TEXCOORD0;
                float3 world_pos:TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.world_normal = mul(v.normal,(float3x3)unity_WorldToObject);
                o.world_pos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(i.world_normal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));

                fixed3 world_relect_dir = normalize(reflect(-worldLightDir,worldNormal));
                fixed3 worldPos = normalize(i.world_pos);
                fixed3 world_view_dir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(world_relect_dir,world_view_dir)),_Gloss);
                
                return fixed4(specular+diffuse+ambient,1.0);
            }
            ENDCG
        }
    }

    Fallback "Specular"
}
