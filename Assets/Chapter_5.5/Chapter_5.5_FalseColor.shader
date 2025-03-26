// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter_5.5/False Color"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragmetn frag

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR0;
            };

            v2f vert(appdata_full v)
            {
                //将计算得到的假彩色存储到顶点着色器的输出结构体 v2f 中的 color 变量里
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //可视化法线方向
                o.color = fixed4(v.normal * 0.5 + fixed3(0.5,0.5,0.5),1.0);

                //可视化副切线方向
                fixed3 binormal = cross(v.normal,v.tangent.xyz) * v.tangent.w;
                o.color = fixed4(binormal * 0.5 + fixed3(0.5,0.5,0.5), 1.0);

                //可视化第一组纹理坐标
                o.color = fixed4(v.texcoord.xy, 0.0, 1.0);
                
                //可视化第二组纹理坐标
                o.color = fixed4(v.texcoord1.xy, 0.0, 1.0);

                //可视化第一组纹理坐标的小数部分
                o.color = frac(v.texcoord);
                if(any(saturate(v.texcoord)-v.texcoord))
                {
                    o.color.b = 0.5;
                }
                o.color.a = 1.0;

                o.color = frac(v.texcoord1);
                if(any(saturate(v.texcoord1)) - v.texcoord1)
                {
                    o.color.b = 0.5;
                }
                o.color.a = 1.0;

                //可视化顶点颜色
                //o.color = v.color;

                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target{
                return i.color;
            }
            ENDCG
        }
    }
}
