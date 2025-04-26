Shader "Book Reimplementations/Chapter_6.5/Specular Vertex-Level"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
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
                float3 noraml : NORMAL;
            };

            struct v2f
            {
                float4 pos :SV_POSITION;
                fixed3 color: TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                fixed3 ambient =  UNITY_LIGHTMODEL_AMBIENT.rgb;

                // TODO 复习通过变换矩阵实现的坐标空间变换
                float3 normal_world = normalize(mul(v.noraml,(float3x3)unity_WorldToObject));
                float3 lightDir_world = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(lightDir_world,normal_world));

                float3 relectDir = reflect(-lightDir_world,normal_world);
                // TODO 矩阵左乘和右乘的区别
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex));
                fixed3 specular  = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(view_dir,relectDir)),_Gloss);

                o.color = specular + diffuse + ambient;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color,1.0);
            }
            
            ENDCG
        }
    }
    
    FallBack "Specular"
    
}
