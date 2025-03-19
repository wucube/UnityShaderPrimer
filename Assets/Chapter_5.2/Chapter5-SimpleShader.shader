// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 5/Simple Shader"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert // #pragma vertex name 编译指令会指定包含顶点着色器的函数，name 是指定的函数名
            #pragma fragment frag // #pragma fragment name 编译指令会指定包含片元着色器的函数，name 是指定的函数名

            // POSITION 与 SV_POSITION 都是 CG/HLSL 的语义，用于指定输入与输出的数据，避免得到错误的效果
            // POSITION 在这里指定 Unity 将模型顶点坐标填充到输入参数 v 中
            // SV_POSITION 在这里指定 Unity 输出裁剪空间中的顶点坐标
            float4 vert(float4 v : POSITION) : SV_POSITION
            {
                //将顶点坐标从模型空间转换到裁剪空间
                return UnityObjectToClipPos(v);
            }

            // SV_Target 语义指定渲染器将输出的颜色存储到渲染目标(render target)中，此处输出到默认的帧缓存中
            // 片元着色器输出的颜色的每个分量范围在 [0,1] , 其中(0,0,0)表示黑色，(1,1,1)表示白色
            fixed4 frag(): SV_Target
            {
                return fixed4(1.0, 1.0, 1.0, 1.0);
            }

            ENDCG
        }
    }
}