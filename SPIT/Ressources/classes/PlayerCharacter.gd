class_name  PlayerCharacters extends Character

@export_category("player_info")
@export var id : String
@export var role : String

@export_group("players_inventory")
@export var gold : int
@export var book : BookStats
