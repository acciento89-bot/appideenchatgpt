extends SceneTree

# Regression for the actual native Duo portrait strip in a wider window.
# Test the engine's rendered viewport transform, not a source-text setting.
func _init() -> void: call_deferred("run")
func run() -> void:
 var failures := 0
 for dimensions in [Vector2i(1398,2034), Vector2i(2007,2853), Vector2i(2853,2007)]:
  root.size = dimensions
  await process_frame
  await process_frame
  var logical := root.get_visible_rect()
  var rendered := root.get_final_transform() * logical
  var target := Rect2(Vector2.ZERO, Vector2(root.size))
  print("FOLD_VIEWPORT window=", root.size, " logical=",logical," rendered=",rendered)
  if not rendered.position.is_equal_approx(target.position) or not rendered.size.is_equal_approx(target.size):
   failures += 1
   printerr("FAIL: native fold viewport leaves unused bars at %s" % dimensions)
 if failures: quit(1)
 else:
  print("PASS: full-window rendered viewport across three fold proportions")
  quit(0)
