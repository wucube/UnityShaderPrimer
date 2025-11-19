Shader "Book ReImplementations/Chapter_7.4/Mask Texture"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white" {}
        _BumpMap("Bump Map",2D) = "bump" {}
        _BumpScale("Bump Scale",Float) = 1.0
        _SpecularMask("Specular Mask Tex",2D) = "white" {}
        _SpecularScale("Specular Scale",Float) = 1.0
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
            #include "Lighting.cginc"

            fixed4 _Color;
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
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos :SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);

                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex));

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 tangentLightDir = normalize(i.lightDir);
                float3 tangentViewDir = normalize(i.viewDir);

                float3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal,tangentLightDir));

                fixed specularMaskColor = tex2D(_SpecularMask,i.uv).r * _SpecularScale;
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb *pow(saturate(dot(tangentNormal,halfDir)),_Gloss) * specularMaskColor;

                return fixed4(ambient + diffuse + specular,1.0);
            }
            
            ENDCG
        }
    }

    FallBack "Specular"
    
}
