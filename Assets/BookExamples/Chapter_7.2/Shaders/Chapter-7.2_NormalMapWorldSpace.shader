Shader"Book Examples/Chapter_7.2/Normal Map In World Space"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {} //没有提供法线纹理时，bump 对应模型自带的法线信息
        _BumpScale ("Bump Scale", Float) = 1.0  //控制凹凸程度，为0时法线纹理不会影响光照
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; // 将顶点的切线方向填充到 tangent 变量中。tangent.w 分量决定切线空间中的副切线方向。  
                float4 texcoord : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;

                //依次存储从切线空间到世界空间变换矩阵的每一行。一个插值寄存器最多只能存储 float4 变量
                float4 tangentToWorld0 : TEXCOORD1;
                float4 tangentToWorld1 : TEXCOORD2;
                float4 tangentToWorld2 : TEXCOORD3;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                // Compute the matrix that transform directions from tangent space to world sapce
                // Put the world position in w component for optimization
                o.tangentToWorld0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x , worldPos.x);
                o.tangentToWorld1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y , worldPos.y);
                o.tangentToWorld2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z , worldPos.z);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Get the position in world space
                float3 worldPos = float3(i.tangentToWorld0.w , i.tangentToWorld1.w, i.tangentToWorld2.w);

                // Compute the light and view dir in world space
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                // Get the normal in tangent sapce
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

                // Transform the normal from tangent space to world sapce
                bump = normalize(half3(dot(i.tangentToWorld0.xyz, bump),dot(i.tangentToWorld1.xyz, bump),dot(i.tangentToWorld2.xyz, bump)));
                
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump,lightDir));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump,halfDir)),_Gloss);
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Specular"
}
