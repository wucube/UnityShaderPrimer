// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter_5.2/Simple Shader 02"
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

            float4 vert(a2v v) : SV_POSITION
            {
                // 使用 v.vertex 访问模型空间的顶点坐标
                return UnityObjectToClipPos(v.vertex);
            }

            fixed4 frag() : SV_Target
            {
                return fixed4(1.0, 1.0, 1.0, 1.0);
            }
            ENDCG
        }
    }
}
