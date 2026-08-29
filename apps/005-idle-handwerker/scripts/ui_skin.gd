class_name UiSkin
extends RefCounted

const PANEL := preload("res://assets/ui/panel_inlay.svg")
const HERO := preload("res://assets/ui/hero_panel.svg")
const BUTTON := preload("res://assets/ui/button_primary.svg")
const BUTTON_PRESSED := preload("res://assets/ui/button_pressed.svg")
const BUTTON_DARK := preload("res://assets/ui/button_dark.svg")
const NAV_ACTIVE := preload("res://assets/ui/nav_active.svg")
const MEDALLION := preload("res://assets/ui/medallion.svg")


static func panel() -> StyleBoxTexture:
	return _nine_patch(PANEL, 24.0, 18.0)


static func hero() -> StyleBoxTexture:
	return _nine_patch(HERO, 32.0, 23.0)


static func primary_button() -> StyleBoxTexture:
	return _nine_patch(BUTTON, 20.0, 12.0)


static func pressed_button() -> StyleBoxTexture:
	return _nine_patch(BUTTON_PRESSED, 20.0, 12.0)


static func dark_button() -> StyleBoxTexture:
	return _nine_patch(BUTTON_DARK, 20.0, 12.0)


static func active_nav() -> StyleBoxTexture:
	return _nine_patch(NAV_ACTIVE, 22.0, 11.0)


static func medallion() -> StyleBoxTexture:
	return _nine_patch(MEDALLION, 20.0, 9.0)


static func _nine_patch(texture: Texture2D, texture_margin: float, content_margin: float) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = texture_margin
	box.texture_margin_top = texture_margin
	box.texture_margin_right = texture_margin
	box.texture_margin_bottom = texture_margin
	box.content_margin_left = content_margin
	box.content_margin_top = content_margin
	box.content_margin_right = content_margin
	box.content_margin_bottom = content_margin
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return box

