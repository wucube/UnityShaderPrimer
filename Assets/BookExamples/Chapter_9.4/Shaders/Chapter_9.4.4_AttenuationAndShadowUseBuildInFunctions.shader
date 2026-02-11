Shader "Book Examples/Chapter_9.4.4/AttenuationAndShadowUseBuildInFunctions"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    
    SubShader
    {
        Tags {"RenderType" = "Opaque"}
        
        Pass
        {
            // Pass for ambient light and first pixel light(directional light)
            Tags {"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            
            // Apparently need to add this declaration 
           // 用于生成处理平行光光照和阴影所需的 Shader 变体
            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct  a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                // 声明一个用于对阴影纹理采样的坐标,参数为下一个可用的插值寄存器的索引值
                SHADOW_COORDS(2)
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                //Pass shadow coordinates to pixel shader
                TRANSFER_SHADOW(o) 
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                // 环境光只需计算一次，因此放在 Base Pass 中
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 计算漫反射和高光（Blinn-Phong 模型）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                
                // 计算光照衰减和阴影
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                return fixed4(ambient + (diffuse + specular) * atten ,1.0);
            }
            
            ENDCG
        }

        Pass
        {
            // Pass for other pixel lights
            Tags {"LightMode" = "ForwardAdd"}
            
            //将此 Pass 的光照结果与 Base Pass 的结果在帧缓存中叠加
            Blend One One
            
            CGPROGRAM
            // Apparently need to add this declaration
            // 用于生成处理点光源、聚光灯等不同光源类型的变体
            #pragma multi_compile_fwdadd
            // Use the line below to add shadows for point and spot lights
            // #pragma multi_compile_fwdadd_fullshadows
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                
                // UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                return fixed4((diffuse + specular) * atten, 1.0);
            }
                
            ENDCG
        }
    }

    Fallback "Specular"
}
