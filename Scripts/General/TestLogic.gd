# res://Scripts/General/TestLogic.gd
extends Node

# On glisse nos fichiers .tres ici depuis le FileSystem
@export var word_item: ShopItem
@export var potion_item: ShopItem

func _ready():
	print("--- 🧪 DÉBUT DU TEST DE LOGIQUE ---")
	
	# Connexion aux signaux pour voir les réactions (comme le fera l'UI plus tard)
	GameManager.purchase_failed.connect(func(reason): print("🚨 Erreur UI : ", reason))
	GameManager.purchase_success.connect(func(item): print("🛒 UI : Achat de ", item.item_name))
	
	# Test 1 : Achat réussi
	print("\n🛒 Test 1 : Achat de WORD")
	GameManager.buy_item(word_item)
	
	# Test 2 : Achat d'un deuxième objet
	print("\n🛒 Test 2 : Achat d'une Potion")
	GameManager.buy_item(potion_item)
	
	# Test 3 : Achat du même objet (test de l'inventaire)
	print("\n🛒 Test 3 : Achat d'un autre WORD")
	GameManager.buy_item(word_item)
	
	# Affichage final
	print("\n--- 📊 ÉTAT FINAL ---")
	GameManager.print_inventory()
	print("Argent restant : ", GameManager.player_money, " $")
