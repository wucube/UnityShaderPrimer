// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter_5.2.3/Simple Shader"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // 定义顶点着色器输入的数据结构
            // a2v 命名的含义：a 表示应用(application)，v 表示顶点着色器(vertex shader)，a2v 即表示将数据从应用阶段传递到顶点着色器中
            struct a2v
            {
                // 下列语义中的数据由材质的 Mesh Render 组件提供。
                // 每帧调用 Draw Call 的时候， Mesh Render 组件会将自身渲染的模型数据发送给 Unity Shader
                // 模型通常包含一组三角面片，每个三角面片由三个顶点构成，每个顶点包含顶点位置、法线、切线、纹理坐标、顶点颜色等数据
                
                // POSITION 语义指定 Unity 用模型空间的顶点坐标填充 vertex 变量
                float4 vertex : POSITION;
                // NORMAL 语义指定 Unity 用模型空间的法线方向填充 normal 变量
                float3 normal : NORMAL;
                // TEXCOORD0 语义指定 Unity 用模型的第一套纹理坐标填充 texcoord 变量
                float4 texcoord : TEXCOORD0;
            };

            // 定义顶点着色器的输出。
            // 用于将顶点着色器的信息传递给片元着色器。
            // 顶点着色器的输出结构必须包含一个变量，并且语义为 SV_POSITION，否则渲染器无法得到裁剪空间中的顶点坐标，也就无法将顶点渲染到屏幕上。
            struct v2f
            {
                // SV_POSITION 告诉 Unity pos 包含顶点在裁剪空间中的位置信息
                float4 pos : SV_POSITION;
                // COLOR0 语义用于存储颜色信息
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                //声明输出结构
                v2f o;
                
                //将顶点坐标从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // v.normal 包含顶点的法线方向，其分量范围在[-1.0, 1.0]
                //将法线分量范围映射到[0.0, 1.0]，并存储到 o.color 中传递给片元着色器
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            float frag(v2f i) : SV_Target
            {
                //将插值后的 i.color 显示到屏幕上
                return fixed4(i.color, 1.0);

                //顶点着色器是逐顶点调用的，片元着色器是逐片元调用的。片元着色器中的输入实际是将顶点着色器的输出进行插值后得到的结果。
            }
            ENDCG
        }
    }
}
