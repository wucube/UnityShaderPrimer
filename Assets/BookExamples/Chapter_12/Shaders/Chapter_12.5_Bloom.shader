Shader "Book Examples/Chapter_12.5/Bloom"
{
    Properties
    {
    	// 输入的渲染纹理
        _MainTex ("Base (RGB)", 2D) = "white" {}
    	// 高斯模糊后较亮的区域
		_Bloom ("Bloom (RGB)", 2D) = "black" {}
    	// 提取较亮区域的阀值
		_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		_BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
		};	
		
		v2f vertExtractBright(appdata_img v) {
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}
		
		fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}
		
		fixed4 fragExtractBright(v2f i) : SV_Target {
			// 使用 half4 容纳 HDR 颜色
			half4 c = tex2D(_MainTex, i.uv);
			//直接减去阈值并限制下限为 0，绝不限制上限，保留真实的物理发光能量 (如亮度为 5.0 的霓虹灯)
			half brightness = max(0.0, luminance(c) - _LuminanceThreshold);
			
			return c * brightness;
		}
		
		struct v2fBloom {
			float4 pos : SV_POSITION; 
			half4 uv : TEXCOORD0; // xy 存 _MainTex 的 UV，zw 存 _Bloom 的 UV
		};
		
		v2fBloom vertBloom(appdata_img v) {
			v2fBloom o;
			
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv.xy = v.texcoord;		
			o.uv.zw = v.texcoord;
			
			// 宏拦截：如果平台纹理从顶部开始计算，且主纹理被引擎翻转
			#if UNITY_UV_STARTS_AT_TOP			
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w; // 强行翻转 _Bloom 的 V 轴以对齐原图
			#endif
				        	
			return o; 
		}
		
		fixed4 fragBloom(v2fBloom i) : SV_Target {
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
		} 
		
		ENDCG
		
		ZTest Always Cull Off ZWrite Off
		
		Pass {  
			CGPROGRAM
			
			#pragma vertex vertExtractBright  
			#pragma fragment fragExtractBright  
			
			ENDCG  
		}
		
		UsePass "Book Examples/Chapter_12.4/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"
		
		UsePass "Book Examples/Chapter_12.4/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"
		
		Pass {  
			CGPROGRAM
			
			#pragma vertex vertBloom  
			#pragma fragment fragBloom  
			
			ENDCG  
		}
	}
	FallBack "Diffuse"
}
