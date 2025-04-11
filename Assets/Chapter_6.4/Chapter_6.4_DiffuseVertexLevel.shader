// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter_6.4/Diffuse Vertex-Level"
{
    Properties
    {
        // 定义漫反射颜色属性，默认白色
        _Diffuse("Diffuse",Color) = (1, 1, 1, 1)
    }
    
    SubShader
    {
        Pass
        {
            // 指定光照模式为前向渲染基础通道
            Tags {"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            // 声明顶点和片段着色器函数
            #pragma vertex vert
            #pragma fragment frag
            
            // 包含Unity内置光照相关函数和变量
            #include "Lighting.cginc"
            
            // 声明Properties中定义的变量
            fixed4 _Diffuse;
            
            // 定义从应用阶段到顶点着色器的输入结构
            struct a2v
            {
                // 顶点位置（模型空间）
                float4 vertex : POSITION;
                // 顶点法线（模型空间）
                float3 normal : NORMAL;
            };

            // 定义从顶点着色器到片段着色器的输出结构
            struct v2f
            {
                // 裁剪空间中的顶点位置
                float4 pos : SV_POSITION;
                // 计算好的颜色值
                fixed3 color : COLOR;
            };

            // 顶点着色器函数
            v2f vert(a2v v)
            {
                v2f o;
                
                // 1. 顶点位置变换：模型空间 -> 裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 2. 获取环境光分量
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 3. 法线变换：模型空间 -> 世界空间
                // 注意：法线是方向向量，需要使用逆转置矩阵来正确变换
                // unity_WorldToObject是模型到世界的变换矩阵的逆矩阵
                fixed3 world_normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                
                // 4. 获取世界空间中的光照方向
                // _WorldSpaceLightPos0是主平行光的方向（已归一化）
                fixed3 world_light = normalize(_WorldSpaceLightPos0.xyz);
                
                // 5. 计算漫反射光照
                // 公式: 漫反射颜色 = 光颜色 × 材质漫反射颜色 × max(0, 法线·光照方向)
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(world_normal, world_light));
                
                // 6. 合并环境光和漫反射光
                o.color = ambient + diffuse;
                
                return o;
            }

            // 片段着色器函数
            fixed4 frag(v2f i) : SV_Target
            {
                // 直接输出顶点着色器计算好的颜色，alpha值设为1
                return fixed4(i.color, 1.0);
            }
            
            ENDCG
        }
    }
    
    // 后备着色器（当主着色器不支持时使用）
    FallBack "Diffuse"
}