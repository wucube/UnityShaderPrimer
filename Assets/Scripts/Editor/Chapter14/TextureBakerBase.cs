using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public abstract class TextureBakerBase : EditorWindow
{
    // 所有子类共用同一套输入纹理列表；拖入多张纹理时会按路径排序后整体替换
    [SerializeField]
    private List<Texture2D> _sourceTextures = new List<Texture2D>();
    // 最终生成的 Texture3D / Texture2DArray 资产保存路径
    [SerializeField]
    private string _savePath;

    // 子类只需要提供默认文件名、按钮文案和具体的纹理资产创建逻辑
    protected abstract string DefaultFileName { get; }
    protected abstract string BakeButtonText { get; }
    protected abstract string SuccessMessage { get; }

    protected virtual void OnEnable()
    {
        if (string.IsNullOrEmpty(_savePath))
        {
            _savePath = "Assets/" + DefaultFileName;
        }

        if (_sourceTextures.Count == 0)
        {
            // 默认初始化 6 个纹理层，UI 中仍允许手动调整数量
            for (int i = 0; i < 6; i++)
            {
                _sourceTextures.Add(null);
            }
        }
    }

    protected virtual void OnGUI()
    {
        GUILayout.Label("源纹理列表（按层顺序）", EditorStyles.boldLabel);
        EditorGUILayout.HelpBox("请按目标 shader 约定的层顺序设置纹理：Layer 0 会写入数组第 0 层，编号越大层索引越靠后。", MessageType.Info);
        GUILayout.Space(10);

        // 根据输入数量动态调整列表长度，便于烘焙不同层数的纹理数组
        int textureCount = Mathf.Max(1, EditorGUILayout.IntField("纹理层数", _sourceTextures.Count));
        ResizeSourceTextureList(textureCount);

        for (int i = 0; i < _sourceTextures.Count; i++)
        {
            _sourceTextures[i] = (Texture2D)EditorGUILayout.ObjectField(CreateTextureSlotLabel(i), _sourceTextures[i], typeof(Texture2D), false);
        }

        GUILayout.Space(20);
        _savePath = EditorGUILayout.TextField("保存路径", _savePath);
        GUILayout.Space(20);

        EditorGUILayout.BeginHorizontal();
        DrawTextureDropArea();
        GUILayout.Space(8);
        DrawFolderDropArea();
        EditorGUILayout.EndHorizontal();

        GUILayout.Space(20);

        if (GUILayout.Button(BakeButtonText, GUILayout.Height(45)))
        {
            Bake();
        }
    }

    private void DrawTextureDropArea()
    {
        Rect dropArea = GUILayoutUtility.GetRect(0.0f, 70.0f, GUILayout.ExpandWidth(true));
        GUI.Box(dropArea, "拖入源纹理\n按资源路径排序后填入列表", CreateDropBoxStyle());

        Event currentEvent = Event.current;
        if (!IsDragEventInArea(currentEvent, dropArea))
        {
            return;
        }

        DragAndDrop.visualMode = DragAndDropVisualMode.Copy;

        if (currentEvent.type == EventType.DragPerform)
        {
            DragAndDrop.AcceptDrag();
            // 只处理 Texture2D，不改变保存目录
            HandleTextureDrop();
            GUI.changed = true;
        }

        currentEvent.Use();
    }

    private void DrawFolderDropArea()
    {
        Rect dropArea = GUILayoutUtility.GetRect(0.0f, 70.0f, GUILayout.ExpandWidth(true));
        GUI.Box(dropArea, "拖入保存目录\n只修改资产保存路径", CreateDropBoxStyle());

        Event currentEvent = Event.current;
        if (!IsDragEventInArea(currentEvent, dropArea))
        {
            return;
        }

        DragAndDrop.visualMode = DragAndDropVisualMode.Copy;

        if (currentEvent.type == EventType.DragPerform)
        {
            DragAndDrop.AcceptDrag();
            // 只处理目录，不改变已经拖入的纹理列表
            HandleFolderDrop();
            GUI.changed = true;
        }

        currentEvent.Use();
    }

    private GUIStyle CreateDropBoxStyle()
    {
        GUIStyle dropBoxStyle = new GUIStyle(GUI.skin.box);
        dropBoxStyle.alignment = TextAnchor.MiddleCenter;
        dropBoxStyle.fontSize = 14;
        dropBoxStyle.normal.textColor = Color.gray;
        return dropBoxStyle;
    }

    private GUIContent CreateTextureSlotLabel(int index)
    {
        if (_sourceTextures.Count == 1)
        {
            return new GUIContent("Layer 0（单层）", "只有一层时，生成的纹理资产只包含这一张源纹理。");
        }

        if (index == 0)
        {
            return new GUIContent("Layer 0（第一层）", "写入 Texture3D / Texture2DArray 的第 0 层。");
        }

        if (index == _sourceTextures.Count - 1)
        {
            return new GUIContent($"Layer {index}（最后一层）", "写入 Texture3D / Texture2DArray 的最后一层。");
        }

        return new GUIContent($"Layer {index}", "写入 Texture3D / Texture2DArray 的对应层索引。");
    }

    private bool IsDragEventInArea(Event currentEvent, Rect dropArea)
    {
        if (currentEvent.type != EventType.DragUpdated && currentEvent.type != EventType.DragPerform)
        {
            return false;
        }

        return dropArea.Contains(currentEvent.mousePosition);
    }

    private void HandleTextureDrop()
    {
        List<Texture2D> droppedTextures = new List<Texture2D>();
        foreach (Object objectReference in DragAndDrop.objectReferences)
        {
            if (objectReference is Texture2D texture)
            {
                droppedTextures.Add(texture);
            }
        }

        if (droppedTextures.Count == 0)
        {
            return;
        }

        // 多选拖入时按资源路径排序，保证写入纹理数组的层级顺序稳定
        droppedTextures.Sort((left, right) => string.Compare(AssetDatabase.GetAssetPath(left), AssetDatabase.GetAssetPath(right), System.StringComparison.OrdinalIgnoreCase));
        _sourceTextures = droppedTextures;
    }

    private void HandleFolderDrop()
    {
        foreach (string path in DragAndDrop.paths)
        {
            if (!AssetDatabase.IsValidFolder(path))
            {
                continue;
            }

            string fileName = System.IO.Path.GetFileName(_savePath);
            _savePath = path + "/" + fileName;
            break;
        }
    }

    private void ResizeSourceTextureList(int textureCount)
    {
        while (_sourceTextures.Count < textureCount)
        {
            _sourceTextures.Add(null);
        }

        while (_sourceTextures.Count > textureCount)
        {
            _sourceTextures.RemoveAt(_sourceTextures.Count - 1);
        }
    }

    private void Bake()
    {
        if (!ValidateSourceTextures(out int width, out int height))
        {
            return;
        }

        List<string> restoredReadablePaths = new List<string>();

        try
        {
            // GetPixels 需要源纹理可读；这里只临时打开原本未开启 Read/Write 的纹理
            EnableReadWriteIfNeeded(restoredReadablePaths);
            Texture2D[] sourceTextures = _sourceTextures.ToArray();
            Object textureAsset = CreateTextureAsset(sourceTextures, width, height);

            // 允许重复烘焙同一路径：先删除旧资产，再创建新资产
            Object existingAsset = AssetDatabase.LoadAssetAtPath<Object>(_savePath);
            if (existingAsset != null)
            {
                AssetDatabase.DeleteAsset(_savePath);
            }

            AssetDatabase.CreateAsset(textureAsset, _savePath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log($"<color=green>{SuccessMessage}</color> 保存路径: {_savePath}");
        }
        finally
        {
            // 即使烘焙失败，也要恢复临时开启的 Read/Write 状态
            RestoreReadWrite(restoredReadablePaths);
        }
    }

    private bool ValidateSourceTextures(out int width, out int height)
    {
        width = 0;
        height = 0;

        if (_sourceTextures.Count == 0 || _sourceTextures[0] == null)
        {
            Debug.LogError("请至少赋予第一张贴图，用于确定分辨率！");
            return false;
        }

        width = _sourceTextures[0].width;
        height = _sourceTextures[0].height;

        for (int i = 0; i < _sourceTextures.Count; i++)
        {
            Texture2D sourceTexture = _sourceTextures[i];

            if (sourceTexture == null)
            {
                Debug.LogError($"第 {i} 张贴图为空！烘焙中止。");
                return false;
            }

            if (sourceTexture.width != width || sourceTexture.height != height)
            {
                Debug.LogError($"第 {i} 张贴图分辨率({sourceTexture.width}x{sourceTexture.height})与第一张({width}x{height})不匹配！");
                return false;
            }
        }

        return true;
    }

    private void EnableReadWriteIfNeeded(List<string> restoredReadablePaths)
    {
        for (int i = 0; i < _sourceTextures.Count; i++)
        {
            string assetPath = AssetDatabase.GetAssetPath(_sourceTextures[i]);
            TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;

            if (importer == null || importer.isReadable)
            {
                continue;
            }

            // 只记录原本不可读的贴图；原本已开启 Read/Write 的贴图不做恢复处理
            importer.isReadable = true;
            importer.SaveAndReimport();

            if (!restoredReadablePaths.Contains(assetPath))
            {
                restoredReadablePaths.Add(assetPath);
            }

            // 重新导入后刷新引用，确保后续 GetPixels 使用的是可读版本
            _sourceTextures[i] = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
        }
    }

    private void RestoreReadWrite(List<string> restoredReadablePaths)
    {
        foreach (string assetPath in restoredReadablePaths)
        {
            TextureImporter importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
            if (importer == null)
            {
                continue;
            }

            importer.isReadable = false;
            importer.SaveAndReimport();
        }
    }

    // 具体烘焙格式由子类决定：Texture3DBaker 负责把纹理堆叠成 Texture3D，
    // Texture2DBaker 负责把纹理写入 Texture2DArray 的各个 layer。
    protected abstract Object CreateTextureAsset(Texture2D[] sourceTextures, int width, int height);
}
