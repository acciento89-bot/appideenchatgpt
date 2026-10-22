class_name ResponsiveGeometry
extends RefCounted

# All rectangles use the same reported screen coordinate system. A window that
# already lies inside the safe rectangle needs no fullscreen device padding.
static func insets(window: Rect2i, safe: Rect2i, logical: Vector2) -> Vector4:
	if not window.has_area() or not safe.has_area() or not is_finite(logical.x) or not is_finite(logical.y) or logical.x <= 0.0 or logical.y <= 0.0:
		return Vector4.ZERO
	var visible := window.intersection(safe)
	if not visible.has_area(): return Vector4.ZERO
	var scale_x := logical.x / float(window.size.x)
	var scale_y := logical.y / float(window.size.y)
	return Vector4(
		maxf(0.0, float(visible.position.x - window.position.x) * scale_x),
		maxf(0.0, float(visible.position.y - window.position.y) * scale_y),
		maxf(0.0, float(window.end.x - visible.end.x) * scale_x),
		maxf(0.0, float(window.end.y - visible.end.y) * scale_y))
