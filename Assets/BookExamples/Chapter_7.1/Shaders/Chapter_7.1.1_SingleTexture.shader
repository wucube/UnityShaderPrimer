Shader "Book Examples/Chapter_7.1.1/Single Texture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include  "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

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
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = v.texcoord.xy * _MainTex_ST.xy  + _MainTex_ST.zw;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 使用 Blinn-Phong 光照模型来计算光照
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                //纹理采样结果(纹素值)和颜色属性的乘积来作为材质的反射率(albedo)
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //环境光照与材质的反射率相乘得到环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //光源的颜色、材质反射率、光源方向与法线方向的夹角余弦值的乘积得到漫反射光照
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                //光源颜色、材质高光反射颜色、高光强度的乘积得到高光反射结果
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);

                return fixed4(ambient + diffuse +specular, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Specular"
}
