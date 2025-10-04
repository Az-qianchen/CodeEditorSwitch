# Code Editor Switch
<div align="center">
<img width="256" height="256" alt="CodeEditorSwitch" src="https://github.com/user-attachments/assets/434a7923-fa61-43d7-bb35-806aa0796a00" />
</div>

### 开发原因

当前 ai 已成为了一个重要的开发工具

然而 godot 内部的编辑器对 ai 的支持十分有限

完全使用外部编辑器又不得不抛弃很多内部编辑器特有的便捷小功能

作为一个成年人，当然是我全都要

于是开发了这个小插件，以实现内外编辑器的快速切换

### 功能介绍
1. 使用快捷键 Ctrl + Alt + E 或按钮，实现外部编辑器的快速跳转

2. 点击按钮实现内外编辑器的快速切换

按钮显示“内部编辑器”时，点击脚本使用内部编辑器打开

按钮显示“外部编辑器”时，点击脚本使用所配置的外部编辑器打开

<img width="1913" height="1082" alt="image" src="https://github.com/user-attachments/assets/29c3e0ef-e84e-4295-8d06-291d6f0c3b0c" />

### 使用方法

1. 安装插件
2. 在编辑器设置中配置外部编辑器路径
3. 执行参数配置为 {project} --goto {file}:{line}:{col}
4. 点击按钮进行切换

<img width="1354" height="1097" alt="image" src="https://github.com/user-attachments/assets/7a5c6994-7852-4a4a-b805-34f115924dd7" />

4. 如果想要实现快捷键的自定义，在输入映射中添加一个名为“external_code_editor_open”的动作即可

<img width="1804" height="1097" alt="image" src="https://github.com/user-attachments/assets/80030562-3cd7-42be-a1ed-3911f8e8db8a" />

### 实现原理

只是暴露了编辑器设置中。隐藏较深的一个按钮到了外部
