Shader "Book Examples/Chapter_14.1/Toon Shading"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        // 控制漫反射色调的渐变纹理（卡通渲染的灵魂：将平滑光照强制分阶）
        _Ramp ("Ramp Texture", 2D) = "white" {}
        _Outline ("Outline", Range(0, 1)) = 0.1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 0)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 控制高光阈值的大小，值越小高光面积越大
        _SpecularScale("Specular Scale", Range(0, 0.1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry" }
        
        // ==========================================
        // Pass 1: 过程式几何描边 (渲染背面向外膨胀的黑色外壳)
        // ==========================================
        Pass
        {
            NAME "OUTLINE"
            
            // 剔除正面，只渲染背面多边形
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            float _Outline;
            fixed4 _OutlineColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                
                // 1. 将顶点坐标从【模型空间】转换到【观察空间 (相机空间)】
                float4 pos = float4(UnityObjectToViewPos(v.vertex), 1.0);
                
                // 2. 将法线从【模型空间】转换到【观察空间】
                // 注意：变换法线必须使用逆转置矩阵 (UNITY_MATRIX_IT_MV)
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                
                // 3. 【防穿模魔法】强制修改观察空间下的法线 Z 分量
                // 让法线变得“扁平”，向屏幕两侧扩散，防止背面模型膨胀后刺穿正面
                normal.z = -0.5;
                
                // 4. 沿着修改后的法线方向，把顶点向外推 _Outline 的距离
                pos = pos + float4(normalize(normal), 0) * _Outline;
                
                // 5. 将推远后的顶点从【观察空间】转换到【裁剪空间】，交由 GPU 栅格化
                o.pos = mul(UNITY_MATRIX_P, pos);
                
                return o;
            }
            
            float4 frag(v2f i) : SV_Target
            {
                // 背面直接输出纯色的描边颜色
                return float4(_OutlineColor.rgb, 1);
            }
            ENDCG
        }

        // ==========================================
        // Pass 2: 卡通光照模型 (渲染正面，实现色块与硬边缘高光)
        // ==========================================
        Pass
        {
            // 告诉 Unity 光照流水线，这是一个前向渲染的基础 Pass，用来接收主光源和阴影
            Tags { "LightMode" = "ForwardBase" }
            
            // 恢复正常的剔除背面，只渲染正面
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 确保能接收到正确的光照衰减、阴影等宏定义
            #pragma multi_compile_fwdbase
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"
            
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                // 声明用于接收阴影坐标的宏
                SHADOW_COORDS(3)
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                // 一步到位：模型空间 -> 裁剪空间 (MVP 变换)
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                // 模型空间法线 -> 世界空间法线
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 模型空间坐标 -> 世界空间坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                
                // 计算该顶点的阴影坐标
                TRANSFER_SHADOW(o);
                return o;
            }
            
            float4 frag(v2f i) : SV_Target
            {
                // ---- 1. 准备光照所需的基础向量 ----
                // 归一化世界空间下的法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 主光源方向 (指向光源)
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                // 视线方向 (指向摄像机)
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 半角向量 (光线与视线的中间角，用于算 Blinn-Phong 高光)
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);
                
                // 采样主贴图颜色
                fixed4 c = tex2D(_MainTex, i.uv);
                fixed3 albedo = c.rgb * _Color.rgb;
                
                // ---- 2. 环境光 (Ambient) ----
                // 直接获取 Unity Lighting 面板里的环境光颜色
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                // 获取当前像素的阴影衰减值 (0代表全阴影，1代表无阴影)
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                
                // ---- 3. 漫反射 (Diffuse) - 卡通化降维打击 ----
                // 经典兰伯特光照 (N dot L)，结果范围 [-1, 1]
                fixed diff = dot(worldNormal, worldLightDir);
                // 转换为半兰伯特 (Half-Lambert)，结果范围 [0, 1]，防止背光面死黑
                diff = (diff * 0.5 + 0.5) * atten; 
                // 【核心魔法】不直接用 diff 算亮度，而是把它当做 UV 坐标去采样 Ramp 渐变图！
                // 这会将平滑的光照强制切分成 Ramp 图上的几个硬色阶
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;
                
                // ---- 4. 高光 (Specular) - 硬边缘与抗锯齿 ----
                // 经典 Blinn-Phong 高光 (N dot H)
                fixed spec = dot(worldNormal, worldHalfDir);
                // fwidth 求导数，算出当前像素的梯度变化大小
                fixed w = fwidth(spec) * 2.0;
                // smoothstep 在极其微小的边缘内进行平滑过渡，消除锯齿
                // step(0.0001, _SpecularScale) 用于当 Scale 为 0 时彻底关闭高光
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * (0.0001, _SpecularScale);
                
                // ---- 5. 最终画面合成 ----
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}