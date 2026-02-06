extends Node2D

## TEMPORARY TEST SCRIPT FOR MOOD BAR
## Attach this to a test scene to verify MoodBar works independently

@onready var mood_bar = $MoodBar  # Assumes MoodBar is a child of this node

func _ready():
	print("\n" + "=".repeat(60))
	print("[TEST] MoodBar Test Script Started")
	print("[TEST] Testing MoodBar in isolation...")
	print("=".repeat(60) + "\n")
	
	# Wait for everything to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Test 1: Check if MoodBar is in scene tree
	if mood_bar:
		print("[TEST] ✅ MoodBar found in scene tree")
		print("[TEST]    Path: ", mood_bar.get_path())
		print("[TEST]    Visible: ", mood_bar.visible)
	else:
		print("[TEST] ❌ MoodBar NOT found!")
		return
	
	# Test 2: Check GameState signal
	var connections = GameState.mood_changed.get_connections()
	print("\n[TEST] GameState.mood_changed has ", connections.size(), " connection(s):")
	for conn in connections:
		print("[TEST]    -> ", conn.callable)
	
	# Test 3: Trigger mood change manually
	print("\n[TEST] 🧪 Test 1: Setting mood to 75 in 2 seconds...")
	await get_tree().create_timer(2.0).timeout
	GameState.set_mood(75)
	
	# Test 4: Another mood change
	print("\n[TEST] 🧪 Test 2: Setting mood to 30 in 3 seconds...")
	await get_tree().create_timer(3.0).timeout
	GameState.set_mood(30)
	
	# Test 5: Win threshold
	print("\n[TEST] 🧪 Test 3: Setting mood to 100 in 3 seconds...")
	await get_tree().create_timer(3.0).timeout
	GameState.set_mood(100)
	
	print("\n[TEST] All tests completed! Watch the mood bar for smooth animations.")
	print("[TEST] If bar filled smoothly from 50→75→30→100, it's working! ✅")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("[TEST] Manual test: Setting mood to 0")
				GameState.set_mood(0)
			KEY_2:
				print("[TEST] Manual test: Setting mood to 25")
				GameState.set_mood(25)
			KEY_3:
				print("[TEST] Manual test: Setting mood to 50")
				GameState.set_mood(50)
			KEY_4:
				print("[TEST] Manual test: Setting mood to 75")
				GameState.set_mood(75)
			KEY_5:
				print("[TEST] Manual test: Setting mood to 100")
				GameState.set_mood(100)
