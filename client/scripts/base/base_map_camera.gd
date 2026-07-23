extends Camera2D
## Pan (drag) + zoom (wheel/pinch) for the BaseMap world. Bounds are set by
## BaseMap via limit_left/right/top/bottom (world size), so this script never
## needs to know the map's dimensions itself.

const ZOOM_MIN := 0.4
const ZOOM_MAX := 1.5
const ZOOM_STEP := 0.1

var _dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_camera := Vector2.ZERO

func _ready() -> void:
	zoom = Vector2(0.8, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if event.pressed:
				_drag_start_mouse = event.position
				_drag_start_camera = position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-ZOOM_STEP)
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = (event.position - _drag_start_mouse) / zoom.x
		position = _drag_start_camera - delta
	elif event is InputEventScreenDrag:
		position -= event.relative / zoom.x
	elif event is InputEventMagnifyGesture:
		_apply_zoom(event.factor - 1.0)

func _apply_zoom(delta: float) -> void:
	var new_zoom: float = clamp(zoom.x + delta, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(new_zoom, new_zoom)
