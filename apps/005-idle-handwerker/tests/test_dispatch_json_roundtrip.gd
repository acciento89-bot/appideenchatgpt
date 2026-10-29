extends SceneTree
const Board = preload("res://scripts/dispatch_board.gd")
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: " + message)
func _init() -> void:
 for order in Board.ORDERS:
  for staff in Board.STAFF:
   for pace in Board.PACES:
    for specialty in Board.SPECIALIZATIONS:
     var board = Board.new()
     board.set_specialization(staff, specialty)
     board.assign(order.id, staff, pace, {"azubi":1,"monteur":1,"meisterin":1}, 10)
     board.advance(0.137)
     # Exercise the actual JSON text codec used by save_game, not an in-memory copy.
     var decoded: Dictionary = JSON.parse_string(JSON.stringify(board.to_payload()))
     var restored = Board.from_payload(decoded)
     check(restored != null, "JSON reload preserves %s/%s/%s/%s" % [order.id,staff,pace,specialty])
     if restored != null:
      restored.advance(28800.0)
      var receipt: Dictionary = restored.collect(restored.tasks[0].id)
      check(not receipt.is_empty(), "reloaded task collectible exactly once")
      check(Board.from_payload(JSON.parse_string(JSON.stringify(restored.to_payload()))) != null, "completed receipt survives JSON reload")
      check(restored.collect(receipt.id).is_empty(), "duplicate collect grants nothing")
     var tampered: Dictionary = decoded.duplicate(true)
     tampered.tasks[0].duration += 0.000001
     check(Board.from_payload(tampered) == null, "noncanonical duration still rejected")
 print("DISPATCH JSON ROUNDTRIP ", checks," checks, failures=",failures)
 quit(1 if failures else 0)
