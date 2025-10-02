@tool
extends EditorPlugin
# 编辑器设置
var editor_settings = EditorInterface.get_editor_settings()
var switch := Button.new()

func _enter_tree():
	# 添加按钮
	switch.toggled.connect(_button_toggled)
	switch.toggle_mode = true
	# 初始化
	if editor_settings.get_setting("text_editor/external/use_external_editor"):
		switch.text = "外部编辑器"
		switch.button_pressed = true
	else:
		switch.text = "内部编辑器"
		switch.button_pressed = false
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, switch)

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, switch)

# 更改配置
func _button_toggled(toggled):
	if toggled:
		switch.text = "外部编辑器"
		editor_settings.set_setting("text_editor/external/use_external_editor", true)
	else :
		switch.text = "内部编辑器"
		editor_settings.set_setting("text_editor/external/use_external_editor", false)
