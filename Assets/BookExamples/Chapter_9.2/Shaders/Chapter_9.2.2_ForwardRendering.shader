Shader "Book Examples/Chapter_9.2.2/Forward Rendering"
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
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                // 环境光只需计算一次，因此放在 Base Pass 中
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 计算漫反射和高光（Blinn-Phong 模型）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                
                // 平行光+没有距离衰减，固定为 1.0
                fixed atten = 1.0;
                
                return fixed4(ambient + (diffuse + specular) * atten,1.0);
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
                // 判断当前处理的是否是平行光
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    // 如果是点光源或聚光灯，灯光方向等于：光源位置 - 顶点位置
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif
                
                // 注意：Additional Pass 不计算环境光，否则环境光会随着光源数量增加而错误变亮
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                
                // --- 处理光照衰减 (Attenuation) ---
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0; // 附加平行光依然无衰减
                #else 
                    #if defined(POINT)
                        // 点光源衰减：将顶点转到光源空间，并采样衰减纹理
                        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined(SPOT)
                        // 聚光灯衰减：包含距离衰减和圆锥体范围判断
                        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
                        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        fixed atten = 1.0;
                    #endif
                #endif
                
                return fixed4((diffuse + specular) * atten, 1.0);
            }
                
            ENDCG
        }
    }

    Fallback "Specular"
}
