using UnityEditor;
using UnityEngine;

public class Texture3DBaker : TextureBakerBase
{
    protected override string DefaultFileName => "Hatch_Tex3D.asset";
    protected override string BakeButtonText => "烘焙 3D 纹理 (Bake 3D Texture)";
    protected override string SuccessMessage => "3D纹理烘焙成功！";

    [MenuItem("Tools/Texture3D Baker For TAM")]
    public static void ShowWindow()
    {
        GetWindow<Texture3DBaker>("Texture3D Baker");
    }

    protected override Object CreateTextureAsset(Texture2D[] sourceTextures, int width, int height)
    {
        // 3D 纹理的 depth 对应 hatch 层数：z = 0 是最亮的 Hatch0，最后一层是最暗
        int depth = sourceTextures.Length;

        // 不生成 mipmap，避免 z 方向跨层 mip 混合导致不同 hatch 层互相污染
        Texture3D tex3D = new Texture3D(width, height, depth, TextureFormat.RGBA32, false);
        // x/y 方向保持 Repeat，让素描线条可以按 UV 平铺
        tex3D.wrapModeU = TextureWrapMode.Repeat;
        tex3D.wrapModeV = TextureWrapMode.Repeat;
        // z 方向必须 Clamp，避免采样到 0 或 1 边界时从最暗层循环回最亮层
        tex3D.wrapModeW = TextureWrapMode.Clamp;
        // 3D 采样依赖 z 方向插值，Trilinear 可以在相邻 hatch 层之间连续过渡
        tex3D.filterMode = FilterMode.Trilinear;

        // Texture3D.SetPixels 需要一次性传入 width * height * depth 的连续数组
        // 数据顺序为：先放完第 0 层所有像素，再放第 1 层，依次类推
        Color[] finalPixels = new Color[width * height * depth];
        for (int z = 0; z < depth; z++)
        {
            // 每张 2D hatch 纹理写入 3D 纹理的一个 z 切片
            Color[] pixels = sourceTextures[z].GetPixels();
            for (int i = 0; i < pixels.Length; i++)
            {
                // 当前层偏移量 = z * 单层像素数量
                finalPixels[z * width * height + i] = pixels[i];
            }
        }

        // 把整理好的所有切片写入 3D 纹理并上传到 GPU
        tex3D.SetPixels(finalPixels);
        tex3D.Apply();
        return tex3D;
    }
}