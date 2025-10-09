@tool
extends EditorPlugin

## 编辑器设置：使用外部编辑器
const USE_EXTERNAL_SETTING := "text_editor/external/use_external_editor"
## 编辑器设置：可执行文件路径
const EXEC_PATH_SETTING := "text_editor/external/exec_path"
## 编辑器设置：执行参数
const EXEC_FLAGS_SETTING := "text_editor/external/exec_flags"
## 输入映射名称
const INPUT_ACTION := "external_code_editor_open"

## EditorSettings 引用缓存
var editor_settings: EditorSettings
## 内外编辑器切换按钮
var toggle_button: Button
## 打开快捷按钮
var shortcut_proxy_button: Button
## 快捷键
var open_shortcut: Shortcut
## 当前快捷是否来自输入映射
var using_input_map := false

func _enter_tree() -> void:
	# 仅在编辑器模式下启用插件逻辑
	if not Engine.is_editor_hint():
		return

	editor_settings = EditorInterface.get_editor_settings()
	ProjectSettings.settings_changed.connect(_refresh_open_shortcut)
	_create_toggle_button()
	_create_shortcut_proxy()

func _exit_tree() -> void:
	# 清理工具栏按钮
	if toggle_button and toggle_button.get_parent():
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toggle_button)
		toggle_button.queue_free()
		toggle_button = null

	# 清理隐藏的快捷键代理按钮
	if shortcut_proxy_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, shortcut_proxy_button)
		shortcut_proxy_button.queue_free()
		shortcut_proxy_button = null

	ProjectSettings.settings_changed.disconnect(_refresh_open_shortcut)
	editor_settings = null
	open_shortcut = null
	using_input_map = false

## 构造切换按钮
func _create_toggle_button() -> void:
	toggle_button = Button.new()
	toggle_button.toggle_mode = true
	toggle_button.toggled.connect(_on_toggle_button_toggled)
	_update_toggle_from_settings()
	toggle_button.tooltip_text = "是使用内部还是外部编辑器进行脚本处理。"
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toggle_button)

## 构造跳转按钮，用于外部打开脚本
func _create_shortcut_proxy() -> void:
	shortcut_proxy_button = Button.new()
	shortcut_proxy_button.focus_mode = Control.FOCUS_NONE
	shortcut_proxy_button.text = "外部跳转"
	shortcut_proxy_button.pressed.connect(_open_current_script_externally)
	_refresh_open_shortcut()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, shortcut_proxy_button)

## 根据输入映射或默认方案刷新快捷键
func _refresh_open_shortcut() -> void:
	var input_shortcut := _build_input_map_shortcut()
	if input_shortcut:
		open_shortcut = input_shortcut
		using_input_map = true
	else:
		if open_shortcut == null or using_input_map:
			open_shortcut = _build_default_shortcut()
		using_input_map = false
	_apply_shortcut_to_button()

## 将当前快捷键应用到按钮并更新提示
func _apply_shortcut_to_button() -> void:
	if shortcut_proxy_button == null:
		return

	shortcut_proxy_button.shortcut = open_shortcut
	var tooltip := "可直接在外部编辑器中打开当前脚本"
	var combo := _describe_shortcut(open_shortcut)
	tooltip += "\n快捷键：" + combo + "，可直接在外部编辑器中打开当前脚本。"
	shortcut_proxy_button.tooltip_text = tooltip

## 优先从 InputMap 构造快捷键
func _build_input_map_shortcut() -> Shortcut:
	var key := "input/%s" % INPUT_ACTION
	if not ProjectSettings.has_setting(key):
		return null
	var events := ProjectSettings.get_setting(key)
	if events.is_empty():
		return null
	var shortcut := Shortcut.new()
	shortcut.events = events["events"].duplicate()
	shortcut.resource_name = "使用外部编辑器打开脚本"
	return shortcut

## 构造默认快捷键对象，默认快捷键（Ctrl+Alt+E）
func _build_default_shortcut() -> Shortcut:
	var shortcut := Shortcut.new()
	var key_event := InputEventKey.new()
	key_event.ctrl_pressed = true
	key_event.alt_pressed = true
	key_event.keycode = Key.KEY_E
	shortcut.events = [key_event]
	shortcut.resource_name = "使用外部编辑器打开脚本"
	return shortcut

## 将快捷键信息转为可读文本
func _describe_shortcut(shortcut: Shortcut) -> String:
	if shortcut == null or shortcut.events.is_empty():
		return ""

	var event: InputEvent = shortcut.events[0]
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var parts := PackedStringArray()
		if key_event.ctrl_pressed:
			parts.append("Ctrl")
		if key_event.alt_pressed:
			parts.append("Alt")
		if key_event.shift_pressed:
			parts.append("Shift")
		if key_event.meta_pressed:
			parts.append("Meta")
		if key_event.keycode:
			parts.append(OS.get_keycode_string(key_event.keycode))
		elif key_event.physical_keycode:
			parts.append(OS.get_keycode_string(key_event.physical_keycode))
		return " + ".join(parts)
	return ""

## 按钮设置执行
func _on_toggle_button_toggled(toggled: bool) -> void:
	editor_settings.set_setting(USE_EXTERNAL_SETTING, toggled)
	_update_toggle_caption(toggled)

## 初次加载时根据设置更新按钮状态
func _update_toggle_from_settings() -> void:
	var use_external := false
	if editor_settings.has_setting(USE_EXTERNAL_SETTING):
		use_external = editor_settings.get_setting(USE_EXTERNAL_SETTING)
	toggle_button.button_pressed = use_external
	_update_toggle_caption(use_external)

## 按钮更新文本显示当前模式
func _update_toggle_caption(use_external: bool) -> void:
	toggle_button.text = "外部编辑器" if use_external else "内部编辑器"

## 快捷键回调：尝试在外部编辑器中打开当前脚本
func _open_current_script_externally() -> void:
	if not Engine.is_editor_hint():
		return

	# 脚本路径
	var exec_path := ""
	if editor_settings.has_setting(EXEC_PATH_SETTING):
		exec_path = editor_settings.get_setting(EXEC_PATH_SETTING)
	if exec_path.is_empty():
		push_warning("未找到外部编辑器路径，请在 Editor Settings → Text Editor → External 中完成配置。")
		return
	# 脚本编辑器节点
	var script_editor := EditorInterface.get_script_editor()
	if script_editor == null:
		push_warning("无法访问脚本编辑器，请确认 Godot 编辑器状态正常。")
		return
	# 当前编辑的脚本
	var script: Script = script_editor.get_current_script()
	if script == null:
		push_warning("当前没有聚焦的脚本，无法跳转到外部编辑器。")
		return
	# 脚本路径
	var resource_path := script.resource_path
	if resource_path == "":
		push_warning("脚本尚未保存到磁盘，请先保存后再尝试外部打开。")
		return
	# 光标行列
	var caret := _get_caret_position(script_editor)
	var exec_flags := "{project} --goto {file}:{line}:{col}"
	if editor_settings.get_setting(EXEC_FLAGS_SETTING) != "":
		exec_flags = editor_settings.get_setting(EXEC_FLAGS_SETTING)
	# 绝对路径
	var absolute_script_path := ProjectSettings.globalize_path(resource_path)
	var args_info := _build_process_arguments(exec_flags, absolute_script_path, caret["line"], caret["column"])
	var args := args_info["args"] as PackedStringArray
	var has_file_flag := args_info["has_file"] as bool
	if not has_file_flag:
		args.append(absolute_script_path)

	var err := OS.create_process(exec_path, args)
	if err == -1:
		push_error("外部编辑器启动失败：%s（错误码 %d），请检查配置。" % [exec_path, err])
	else:
		print("外部编辑器启动成功，进程 ID：%s。" % [err])

## 查询当前脚本编辑器的光标位置，若无法获取则返回 0,0
func _get_caret_position(script_editor: ScriptEditor) -> Dictionary:
	var line := 0
	var column := 0
	var editor_base := script_editor.get_current_editor()
	if editor_base:
		var control:TextEdit = editor_base.get_base_editor()
		if control and control.has_method("get_caret_line"):
			line = control.get_caret_line()
		if control and control.has_method("get_caret_column"):
			column = control.get_caret_column()
	return {"line": line + 1, "column": column + 1}

## 解析外部编辑器参数模板，并替换 {project}/{file}/{line}/{col}
func _build_process_arguments(flags: String, script_path: String, line: int, column: int) -> Dictionary:
	# 数组解析
	var parts: Array[String] = []
	var current := ""
	var inside_quotes := false
	var escape_next := false
	var trimmed := flags.strip_edges()
	for i in range(trimmed.length()):
		var char := trimmed.substr(i, 1)
		if escape_next:
			current += char
			escape_next = false
			continue
		if char == "\\":
			escape_next = true
			continue
		if char == "\"":
			inside_quotes = not inside_quotes
			continue
		if char == " " and not inside_quotes:
			if current.length() > 0:
				parts.append(current)
				current = ""
			continue
		current += char

	if escape_next:
		current += "\\"
	if current.length() > 0:
		parts.append(current)

	# 替换 {project}/{file}/{line}/{col}
	var project_path := ProjectSettings.globalize_path("res://")
	var safe_line := max(line, 0)
	var safe_column := max(column, 0)
	var resolved := PackedStringArray()
	var has_file_flag := false
	for part in parts:
		var replaced := part
		if replaced.find("{file}") != -1:
			has_file_flag = true
		replaced = replaced.replace("{project}", project_path)
		replaced = replaced.replace("{file}", script_path)
		replaced = replaced.replace("{line}", str(safe_line))
		replaced = replaced.replace("{col}", str(safe_column))
		resolved.append(replaced)

	return {
		"args": resolved,
		"has_file": has_file_flag,
	}
