# res://Scripts/UI/ShopUI.gd
extends Control

# --- RÉFÉRENCES UI ---
@export var item_grid: GridContainer
@export var money_label: Label
@export var large_icon: TextureRect
@export var item_name_label: Label
@export var item_price_label: Label
@export var buy_button: Button

# NOUVEAU : Références pour l'inventaire
@export var owned_count_label: Label
@export var small_item_icon: TextureRect

# --- SCÈNES & DONNÉES ---
@export var item_slot_scene: PackedScene
@export var items_for_sale: Array[ShopItem] = []

var selected_item: ShopItem = null

func _ready():
	# Connexions au GameManager
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed) # NOUVEAU
	
	# Connexion au bouton
	buy_button.pressed.connect(_on_buy_pressed)
	buy_button.disabled = true
	
	update_money_display(GameManager.player_money)
	populate_grid()

func populate_grid():
	for child in item_grid.get_children():
		child.queue_free()
		
	for item in items_for_sale:
		var slot = item_slot_scene.instantiate()
		item_grid.add_child(slot)
		slot.setup(item)
		slot.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(item: ShopItem):
	selected_item = item
	
	# Mise à jour du panneau de droite
	item_name_label.text = item.item_name
	item_price_label.text = str(item.price) + "$"
	large_icon.texture = item.icon
	small_item_icon.texture = item.icon # NOUVEAU : On met la même icône pour le petit parchemin
	
	# NOUVEAU : Mise à jour du compteur d'inventaire
	update_inventory_display()
	
	buy_button.disabled = false

# NOUVEAU : Quand on clique sur BUY
func _on_buy_pressed():
	if selected_item:
		GameManager.buy_item(selected_item)
		# L'inventaire se mettra à jour tout seul grâce au signal inventory_changed

# NOUVEAU : Quand l'inventaire change
func _on_inventory_changed():
	update_inventory_display()

# NOUVEAU : Fonction pour afficher la quantité possédée
func update_inventory_display():
	if selected_item:
		var count = 0
		if GameManager.inventory.has(selected_item.item_name):
			count = GameManager.inventory[selected_item.item_name]
		
		owned_count_label.text = str(count)

func _on_money_changed(new_amount: int):
	update_money_display(new_amount)

func update_money_display(amount: int):
	money_label.text = str(amount) + " $"
