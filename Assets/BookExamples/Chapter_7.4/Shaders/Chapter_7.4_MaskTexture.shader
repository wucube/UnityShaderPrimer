Shader "Book Examples/Chapter_7.4/Mask Texture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white" {}
        _BumpMap("Normal Map",2D) = "bump" {}
        _BumpScale("Bump Scale",Float) = 1.0
        _SpecularMask("Specular Mask",2D) = "white" {}
        _SpecularScale("Specular Scale",Float) = 1.0
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            /*主纹理 _MainTex、法线纹理 _BumpMap 和遮罩纹理 _SpecularMask 共同使用纹理属性变量 _MainTex_ST。
            因此修改主纹理的平铺系数和偏移系数会同时影响该 3 个纹理的采样
            节省需要存储的纹理坐标数目，避免快速占满顶点着色器中可使用的插值寄存器*/
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord :TEXCOORD0;
            };

            struct v2f
            {
                float4 pos :SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir :TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                //将光照方向和视角方向从模型空间变换到切线空间中，以便在片元着色器中与法线进行光照运算 
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;

                return  o;
            }

            //在片元着色器中使用遮罩纹理来控制模型表面的高光反射强度
            fixed4 frag(v2f i) :SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal,tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                //Get thd mask value
                fixed specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;
                //Compute specular term with the specular mask
                //遮罩纹理的每个纹素值表明该点对应的高光反射强度。这里选择用 r 分量计算掩码值，然后用得到的掩码值和_SpecularScale 相乘，一起控制高光反射的强度。
                //这里使用的遮罩纹理的每个颜色通道的 rgb 分量都相同，实际浪费了很多存储空间。实际游戏的制作中，会充分利用遮罩纹理中的每个颜色通道来存储不同的表面属性。
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal,halfDir)),_Gloss) * specularMask;

                return fixed4(ambient + diffuse + specular,1.0);
            }
            ENDCG
        }
    }

    Fallback "Specular"
}
