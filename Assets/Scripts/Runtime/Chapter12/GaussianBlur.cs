using UnityEngine;

public class GaussianBlur : PostEffectBase
{
    public Shader GaussianBlurShader;
	private Material _gaussianBlurMaterial = null;

	private Material GaussianBlurMaterial {  
		get {
			_gaussianBlurMaterial = CheckShaderAndCreateMaterial(GaussianBlurShader, _gaussianBlurMaterial);
			return _gaussianBlurMaterial;
		}  
	}

	// Blur iterations - larger number means more blur.
	[Range(0, 4)]
	public int Iterations = 3;
	
	// Blur spread for each iteration - larger value means more blur
	[Range(0.2f, 3.0f)]
	public float BlurSpread = 0.6f;
	
	[Range(1, 8)]
	public int DownSample = 2;
	
	/// 1st edition: just apply blur
//	void OnRenderImage(RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width;
//			int rtH = src.height;
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	} 

	/// 2nd edition: scale the render texture
//	void OnRenderImage (RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width/downSample;
//			int rtH = src.height/downSample;
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//			buffer.filterMode = FilterMode.Bilinear;
//
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	}

	private static readonly int s_BlurSizeId = Shader.PropertyToID("_BlurSize");

	/// 3rd edition: use iterations for larger blur
	private void OnRenderImage (RenderTexture source, RenderTexture destination) {
		Material mat = GaussianBlurMaterial;
		if (mat != null)
		{
			// 1. 计算降采样后的分辨率
			int rtW = source.width / DownSample;
			int rtH = source.height / DownSample;

			// 2. 申请第一块临时显存 (Buffer0) 兼容原图格式
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear; // 必须开启双线性插值

			// 将原图拷贝并缩小入 Buffer0
			Graphics.Blit(source, buffer0);

			// 3. Ping-Pong 迭代循环
			for (int i = 0; i < Iterations; i++) {
				// 动态增大采样距离
				mat.SetFloat(s_BlurSizeId, 1.0f + i * BlurSpread);

				// 申请第二块临时显存 (Buffer1)
				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);

				// 执行竖直方向 Pass (0): 从 Buffer0 画到 Buffer1
				Graphics.Blit(buffer0, buffer1, mat, 0);
				RenderTexture.ReleaseTemporary(buffer0);// 立刻释放旧显存
				buffer0 = buffer1; // 指针交换
				
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);

				// 执行水平方向 Pass (1): 从 Buffer0 画到 Buffer1
				Graphics.Blit(buffer0, buffer1, mat, 1);
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			// 4. 将最终结果输出到屏幕并释放最后一块内存
			Graphics.Blit(buffer0, destination);
			RenderTexture.ReleaseTemporary(buffer0);
		} 
		else 
		{
			Graphics.Blit(source, destination);
		}
	}
}
