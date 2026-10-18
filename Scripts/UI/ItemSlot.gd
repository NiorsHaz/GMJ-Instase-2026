extends Button

signal slot_clicked(word: WordStats)

@export var icon_rect: TextureRect
@export var price_label: Label

var word: WordStats = null

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(new_word: WordStats) -> void:
	word = new_word
	if icon_rect:
		icon_rect.texture = word.icon
	if price_label:
		price_label.text = str(word.buying_price) + "$"

func _on_pressed() -> void:
	slot_clicked.emit(word)
