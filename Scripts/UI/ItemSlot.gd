# res://Scripts/UI/ItemSlot.gd
extends Button

# On stocke l'objet que ce slot représente
var item_data: ShopItem = null

# Références aux enfants (à lier dans l'inspecteur)
@export var icon_rect: TextureRect
@export var price_label: Label

# Signal émis quand le joueur clique sur ce slot
signal slot_clicked(item: ShopItem)

func _ready():
	# On connecte le clic du bouton à notre fonction
	pressed.connect(_on_pressed)

# Fonction pour remplir le slot avec les données d'un objet
func setup(item: ShopItem):
	item_data = item
	if item:
		price_label.text = str(item.price) + "$"
		if item.icon:
			icon_rect.texture = item.icon
		else:
			# Si pas d'icône, on met un carré de couleur temporaire
			icon_rect.modulate = Color(0.5, 0.5, 0.5) 

func _on_pressed():
	if item_data:
		# On prévient le ShopUI qu'on a cliqué sur cet objet
		slot_clicked.emit(item_data)
