// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter_5.2.4/Simple Shader"
{
    Properties
    {
        // 声明一个 Color 类型的属性，初始值为 (1.0, 1.0, 1.0, 1.0) 白色
        _Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //定义一个与属性名称和类型都匹配的变量，便于在 CG 代码中访问属性
            fixed4 _Color;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };
            
            struct v2f
            {
                // SV_POSITION 告诉 Unity pos 包含了顶点在裁剪空间中的位置信息
                float4 pos : SV_POSITION;
                // COLOR0 语义用于存储颜色信息
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                
                o.pos = UnityObjectToClipPos(v.vertex);
                // v.normal 包含顶点的法线方向，其分量范围在[-1.0, 1.0]
                //将法线分量范围映射到[0.0, 1.0]，并存储到 o.color 中传递给片元着色器
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            float frag(v2f i) : SV_Target
            {
                fixed3 c = i.color;
                // 使用 _Color 属性控制输出颜色
                c *= _Color.rgb;
                return fixed4(c, 1.0);
            }
            //顶点着色器是逐顶点调用的，片元着色器是逐片元调用的。片元着色器中的输入实际是将顶点着色器的输出进行插值后得到的结果。
            ENDCG
        }
    }
}
