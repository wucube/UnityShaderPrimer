Shader "Book ReImplementations/Chapter_8.3/Alpha Test"
{
    Properties
    {
        _Color("Main Tint",Color) = (1,1,1,1)
        _MainTex("Main Texture",2D) = "white" {}
        //调用 clip 函数进行透明度测试时使用的判断条件。
        _Cutoff("Alpha Cutoff",Range(0,1)) = 0.5
    }
    
    SubShader
    {
        Tags {"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}
        
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //_Cutoff 范围在 [O, I], 可以 fixed 精度来存储。
            fixed _Cutoff;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return  o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex,i.uv);
                //texColor.a 小于材质参数 _Cutoff 时，就舍弃该片元的输出，即该片元会产生完全透明的效果。
                clip(texColor.a - _Cutoff);
                // Equal to
                // if (texColor.a - _Cutoff < 0.0)
                // {
                //     discard; // discard 指令显式剔除该片元
                // }

                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLightDir));
                return fixed4(ambient + diffuse,1.0);
            }
            
            ENDCG
        }
    }

    Fallback "Transparent/Cutout/VertexLit"
}
