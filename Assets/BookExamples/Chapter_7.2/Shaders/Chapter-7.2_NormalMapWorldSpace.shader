Shader"Book Examples/Chapter_7.2/Normal Map In World Space"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        //法线纹理。没有提供法线纹理时，bump 对应模型自带的法线信息
        _BumpMap ("Normal Map", 2D) = "bump" {}
        //凹凸程度，为 0 时 表示法线纹理不会影响光照
        _BumpScale ("Bump Scale", Float) = 1.0 
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
            //纹理属性(缩放、偏移))
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            //纹理属性(缩放、偏移))
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                // 将顶点的切线方向填充到 tangent 变量中。tangent.w 分量决定切线空间中的副切线方向。  
                float4 tangent : TANGENT; 
                float4 texcoord : TEXCOORD0;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                 //xy 分量为主纹理的 uv 坐标
                //zw 分量为法线纹理的 uv 坐标
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
                // 按列摆放得到从切线空间到世界空间的变换矩阵，世界空间下的顶点位置 xyz 分量存储到 float4 的 w 分量中，充分利用插值寄存器的存储空间
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

                // Get the normal in tangent space
                fixed3 bump;
                // If the texture is not marked as "Normal Map"，and disenable sRGB flag
                // bump.xy = (tex2D(_BumpMap, i.uv.zw).xy * 2 - 1) * _BumpScale;
                // bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

                // Or mark the texture as "Normal Map", and use the built-in function
                bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                
                //Transform the normal from tangent space to world sapce
                bump = normalize(half3(dot(i.tangentToWorld0.xyz, bump),dot(i.tangentToWorld1.xyz, bump), dot(i.tangentToWorld2.xyz, bump)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump,lightDir));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump,halfDir)),_Gloss);

                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }
    }

    Fallback "Specular"
}
