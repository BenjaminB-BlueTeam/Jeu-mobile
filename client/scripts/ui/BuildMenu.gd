extends PopupPanel
## Lists constructible buildings. Cost/time are NOT computed here -- the
## player just picks a type, the server validates and prices it.

const BUILDING_TYPES := [
	"headquarters", "steel_mine", "component_workshop", "fuel_refinery",
	"power_plant", "storage_depot_steel", "storage_depot_components", "storage_depot_fuel",
]

signal build_selected(building_type: String)

@onready var _list: VBoxContainer = $VBoxContainer

func _ready() -> void:
	for building_type in BUILDING_TYPES:
		var btn := Button.new()
		btn.text = I18n.t("building_" + building_type)
		btn.pressed.connect(func() -> void: _on_building_chosen(building_type))
		_list.add_child(btn)

func _on_building_chosen(building_type: String) -> void:
	build_selected.emit(building_type)
	hide()
