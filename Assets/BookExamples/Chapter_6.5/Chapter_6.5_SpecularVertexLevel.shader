Shader "Book Examples/Chapter_6.5/Specular Vertex-Level"
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
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
                float3 world_normal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                float3 world_light_dir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(world_light_dir,world_normal));

                //TODO 数学原理
                fixed3 world_relect_dir = normalize(reflect(-world_light_dir,world_normal));
                //TODO 数学原理
                fixed3 world_view_dir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(world_relect_dir,world_view_dir)),_Gloss);

                o.color = ambient + diffuse + specular;

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
