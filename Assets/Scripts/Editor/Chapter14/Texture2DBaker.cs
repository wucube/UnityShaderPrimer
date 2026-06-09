using UnityEditor;
using UnityEngine;

public class Texture2DBaker : TextureBakerBase
{
    protected override string DefaultFileName => "Hatch_Tex2DArray.asset";
    protected override string BakeButtonText => "烘焙 2DArray 纹理 (Bake Texture2DArray)";
    protected override string SuccessMessage => "Texture2DArray 烘焙成功！";

    [MenuItem("Tools/Texture2DArray Baker For TAM")]
    public static void ShowWindow()
    {
        GetWindow<Texture2DBaker>("Texture2DArray Baker");
    }

    protected override Object CreateTextureAsset(Texture2D[] sourceTextures, int width, int height)
    {
        // Texture2DArray 的 depth 对应数组层数：layer = 0 是最亮的 Hatch0，最后一层是最暗
        int depth = sourceTextures.Length;

        // 不生成 mipmap，避免不同缩放级别下线条被额外模糊，方便和原始 hatch 纹理对照
        Texture2DArray textureArray = new Texture2DArray(width, height, depth, TextureFormat.RGBA32, false);
        // 2DArray 没有 z 方向连续采样问题，只需要让每层纹理在 x/y 方向按 UV 重复平铺
        textureArray.wrapModeU = TextureWrapMode.Repeat;
        textureArray.wrapModeV = TextureWrapMode.Repeat;
        // 每层内部做普通双线性过滤；层与层之间由 shader 手动采样相邻两层并 lerp
        textureArray.filterMode = FilterMode.Bilinear;

        for (int layer = 0; layer < depth; layer++)
        {
            // 每张 2D hatch 纹理写入 Texture2DArray 的一个独立 layer
            // 与 3D 纹理不同，Texture2DArray 的层之间不会被硬件自动混合
            textureArray.SetPixels(sourceTextures[layer].GetPixels(), layer);
        }

        // Apply 后 Texture2DArray 才会真正更新并可作为资产保存、供 shader 采样
        textureArray.Apply();
        return textureArray;
    }
}
