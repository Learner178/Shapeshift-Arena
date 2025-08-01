# CoinManager.gd
extends Node

var coins: int = 0  # Default starting coins

func add_coins(amount: int):
	coins += amount

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		return true
	return false
