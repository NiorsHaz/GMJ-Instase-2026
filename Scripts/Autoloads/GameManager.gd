# res://Scripts/Autoloads/GameManager.gd
extends Node

# --- SIGNAUX ---
# L'UI écoutera ces signaux pour se mettre à jour automatiquement
signal money_changed(new_amount: int)
signal inventory_changed
signal purchase_success(item: ShopItem)
signal purchase_failed(reason: String)

# --- DONNÉES DU JOUEUR ---
var player_money: int = 999999999 # Comme sur ton dessin !
var inventory: Dictionary = {}    # Format: { "NomObjet": Quantité }

# --- LOGIQUE D'ACHAT ---
func buy_item(item: ShopItem) -> bool:
	if item == null:
		purchase_failed.emit("Aucun objet sélectionné.")
		return false
		
	if player_money < item.price:
		purchase_failed.emit("Fonds insuffisants !")
		print("❌ Achat refusé : Fonds insuffisants pour ", item.item_name)
		return false
		
	# Déduction de l'argent
	player_money -= item.price
	
	# Ajout à l'inventaire
	if inventory.has(item.item_name):
		inventory[item.item_name] += 1
	else:
		inventory[item.item_name] = 1
		
	# Notification de l'UI
	money_changed.emit(player_money)
	inventory_changed.emit()
	purchase_success.emit(item)
	
	print("✅ Achat réussi : ", item.item_name, " pour ", item.price, "$. Reste : ", player_money, "$")
	return true

# --- FONCTION DE DEBUG (pour voir l'inventaire) ---
func print_inventory() -> void:
	print("🎒 Inventaire : ", inventory)
