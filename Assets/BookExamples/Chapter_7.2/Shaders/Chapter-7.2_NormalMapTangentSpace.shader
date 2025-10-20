Shader"Book Examples/Chapter_7.2/Normal Map In Tangent Space"
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
            float4 _MainTex_ST;//纹理属性(缩放、偏移))
            sampler2D _BumpMap;
            float4 _BumpMap_ST;//纹理属性(缩放、偏移))
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
                //存储切线空间下的光照与视角方向
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // Compute the binnormal
                //和切线与法线方向都垂直的方向有两个 ，叉积结果 * tangnet.w 决定选择其中的某个方向。
                float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz)) * v.tangent.w;
                // Construct a matrix which transform vectors from object space to tangent sapce
                // 模型空间下切线方向、副切线方向和法线方向按行排列得到从模型空间到切线空间的变换矩阵
                float3x3 rotation =  float3x3(v.tangent.xyz, binormal,v.normal);
                
                //直接使用内置宏得到模型空间到切线空间的变换矩阵
                //TANGENT_SPACE_ROTATION;

                // Transform the light direction form object space to tangent sapce
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                // Transform the view direction form object sapce to stangent space
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangnetViewDir = normalize(i.viewDir);

                // Get the texel in the normal map
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
                fixed3 tangentNormal;

                // If the texture is not marked as "Normal Map"
                //tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                //tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // Or mark the texture as "Normal map", and use the built-in function
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal,tangentLightDir));
                fixed3 halfDir = normalize(tangentLightDir + tangnetViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal,halfDir)),_Gloss);
                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }

    Fallback "Specular"
}
