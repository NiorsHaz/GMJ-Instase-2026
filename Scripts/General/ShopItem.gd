# res://Scripts/General/ShopItem.gd
class_name ShopItem
extends Resource

@export var item_name: String = "Nouvel Objet"
@export var price: int = 100
@export var description: String = ""
@export var icon: Texture2D # On le remplira plus tard

# Tu pourras ajouter d'autres propriétés plus tard (dégâts, rareté...)
