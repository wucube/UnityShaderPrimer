
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectBase : MonoBehaviour
{
    protected virtual void OnEnable()
    {
        if (CheckResources()) return;
        
        enabled = false;
        Debug.LogWarning($"[PostEffectBase] {GetType().Name} 缺乏硬件支持或资源，已自动禁用。");
    }
    
    protected virtual bool CheckResources()
    {
        return true;
    }
    
    // Called when need to create the material used by this effect
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        // 拦截无效或当前硬件不支持的 Shader
        if (shader == null || !shader.isSupported) return null;

        // 如果材质已经准备就绪，直接复用，避免产生 GC (垃圾回收)
        if (material != null && material.shader == shader) return material;
        
        // 重新生成材质并设置为 DontSave，防止在编辑器模式下产生内存泄漏
        Material newMaterial = new Material(shader)
        {
            hideFlags = HideFlags.DontSave
        };
        
        return newMaterial;
    }
}
