extends Control

@export var player_stats: PlayersStats
@export var word_database: WordDatabases

@export var item_grid: GridContainer
@export var money_label: Label
@export var large_icon: TextureRect
@export var item_name_label: Label
@export var item_price_label: Label
@export var buy_button: Button
@export var owned_count_label: Label
@export var small_item_icon: TextureRect
@export var item_slot_scene: PackedScene
@export var hint_label: Label        # optionnel : message d'aide
@export var cancel_button: Button    # optionnel : annuler le remplacement

var replace_mode: bool = false

var selected_word: WordStats = null

func _ready() -> void:
	if player_stats == null or player_stats.book == null or word_database == null:
		push_error("Shop : player_stats, player_stats.book et word_database doivent être assignés.")
		return
	buy_button.pressed.connect(_on_buy_pressed)
	buy_button.disabled = true
	update_money_display()
	update_owned_display()
	populate_grid()
	if cancel_button:
		cancel_button.hide()
		cancel_button.pressed.connect(_cancel_replace)
		
func _on_slot_clicked(word: WordStats) -> void:
	if replace_mode:
		var index = player_stats.book.word_ids.find(word.id)
		if index >= 0:
			_finish_purchase(index)
		return
	selected_word = word
	item_name_label.text = word.name
	item_price_label.text = str(word.buying_price) + "$"
	large_icon.texture = word.icon
	small_item_icon.texture = word.icon
	update_owned_display()
	_refresh_buy_button()

# la limite max_word n'empêche plus l'achat : elle déclenche le remplacement
func _can_buy() -> bool:
	if selected_word == null or _is_owned(selected_word):
		return false
	return player_stats.gold >= selected_word.buying_price

func _is_book_full() -> bool:
	return player_stats.book.word_ids.size() >= player_stats.book.max_word

func populate_grid() -> void:
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	if item_slot_scene == null:
		return
	var words: Array[WordStats] = []
	if replace_mode:
		for id in player_stats.book.word_ids:
			var owned_word = word_database.find_by_id(id)
			if owned_word != null:
				words.append(owned_word)
	else:
		for word in word_database.find_all():
			if not _is_owned(word):
				words.append(word)
	for word in words:
		var slot = item_slot_scene.instantiate()
		item_grid.add_child(slot)
		slot.setup(word)
		slot.slot_clicked.connect(_on_slot_clicked)

func _on_buy_pressed() -> void:
	if not _can_buy():
		return
	if _is_book_full():
		_enter_replace_mode()
	else:
		_finish_purchase(-1)

func _is_owned(word: WordStats) -> bool:
	return word.id in player_stats.book.word_ids

func _enter_replace_mode() -> void:
	replace_mode = true
	buy_button.disabled = true
	_set_hint("Livre plein : choisis le mot à remplacer")
	if cancel_button:
		cancel_button.show()
	populate_grid()

func _exit_replace_mode() -> void:
	replace_mode = false
	_set_hint("")
	if cancel_button:
		cancel_button.hide()

func _cancel_replace() -> void:
	_exit_replace_mode()
	populate_grid()
	_refresh_buy_button()

# replace_index = -1 : simple ajout, sinon remplace le mot à cet index
func _finish_purchase(replace_index: int) -> void:
	player_stats.gold -= selected_word.buying_price
	if replace_index >= 0:
		player_stats.book.word_ids[replace_index] = selected_word.id
	else:
		player_stats.book.word_ids.append(selected_word.id)
	_exit_replace_mode()
	_clear_selection()
	update_money_display()
	update_owned_display()
	populate_grid()

func _set_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text

func _unhandled_input(event: InputEvent) -> void:
	if replace_mode and event.is_action_pressed("ui_cancel"):
		_cancel_replace()

func _clear_selection() -> void:
	selected_word = null
	item_name_label.text = ""
	item_price_label.text = ""
	large_icon.texture = null
	small_item_icon.texture = null
	buy_button.disabled = true

func update_money_display() -> void:
	money_label.text = str(player_stats.gold) + " $"

func update_owned_display() -> void:
	var book = player_stats.book
	owned_count_label.text = "%d / %d" % [book.word_ids.size(), book.max_word]

func _refresh_buy_button() -> void:
	# pendant le choix du mot à remplacer, le bouton reste bloqué
	if replace_mode:
		buy_button.disabled = true
		return
	buy_button.disabled = not _can_buy()
	# optionnel : change le texte quand le livre est plein
	if _is_book_full():
		buy_button.text = "Remplacer"
	else:
		buy_button.text = "Acheter"
