# Homecoming — Godot Project Structure

```
project_root/
│
├── project.godot                          # Engine config. Registers the GameState autoload + input map.
│
├── addons/
│   └── player2/                           # Player2 plugin. Drag-drop from their repo. Never edit.
│                                          # Provides: Player2AINPC, Player2TTS, Player2AIChatCompletion nodes.
│                                          # Auth + TTS handled automatically once client_id is set in
│                                          # Project Settings → Player2 → Game Key.
│
├── autoload/
│   └── game_state.gd                      # THE single source of truth. Owns mood (int 0-100), all flags,
│                                          # and emits mood_changed / game_won / game_lost signals.
│                                          # Everything reads and writes state through here. Nothing else owns state.
│
├── systems/
│   └── intent_classifier.gd               # Pure static class. No scene, no state.
│                                          # classify(text) → returns an intent key string
│                                          # (e.g. "apology", "insult", "nonsense").
│                                          # Keyword/rule-based. Mood logic stays in game code, never the LLM.
│
├── scenes/
│   │
│   ├── main/
│   │   ├── main.tscn                      # The single scene that runs the game. Instantiates everything else.
│   │   └── main.gd                        # Wires GameState signals → UI updates. Connects win/lose → end_screen.
│   │
│   ├── player/
│   │   ├── player.tscn                    # CharacterBody2D + Sprite2D + CollisionShape2D + DetectArea (Area2D).
│   │   └── player.gd                      # WASD movement. Tracks nearby interactables via Area2D overlap.
│   │                                      # On E press: calls interact() on the closest one in range.
│   │
│   ├── npc/
│   │   ├── girlfriend.tscn                # The talking NPC. Contains Player2AINPC child node.
│   │   └── girlfriend.gd                  # "Brain" script. Runs the dialogue loop:
│   │                                      #   1. Receive player text
│   │                                      #   2. Classify intent (calls systems/intent_classifier)
│   │                                      #   3. Apply mood delta via GameState
│   │                                      #   4. Call Player2AINPC.chat(text)  ← LLM call
│   │                                      #   5. On chat_received signal → emit npc_reply for UI
│   │                                      # TTS plays automatically via Player2's Character Config.
│   │                                      # Emits: npc_reply(text), npc_thinking
│   │                                      # The LLM prompt (angry girlfriend personality) is set in the
│   │                                      # Player2AINPC node's Description field in the editor.
│   │
│   ├── interactables/
│   │   ├── interactable.gd                # Base class. Owns an Area2D "Hitbox" for detection.
│   │   │                                  # Subclasses override interact().
│   │   ├── sink.tscn                      # Sprite2D + CollisionShape2D + Area2D (Hitbox) + script
│   │   ├── sink.gd                        # interact() → GameState.apply_intent("do_dishes") + set_flag
│   │   ├── broom.tscn
│   │   ├── broom.gd                       # interact() → GameState.apply_intent("clean") + set_flag
│   │   ├── girlfriend_marker.tscn         # Invisible Area2D marker placed next to the girlfriend sprite.
│   │   └── girlfriend_marker.gd           # interact() → checks ordered_food flag → apply_intent("give_food")
│   │                                      # Separated from npc/ because "talk to girlfriend" and
│   │                                      # "give food to girlfriend" are different interaction systems.
│   │
│   └── ui/
│       ├── dialogue.tscn                  # The chat panel. RichTextLabel (history) + LineEdit + Send button.
│       ├── dialogue.gd                    # Listens to girlfriend's npc_reply + npc_thinking signals.
│                                          # On send: calls girlfriend.receive_player_message(text).
│       ├── mood_bar.tscn                  # ProgressBar (or TextureProgressBar). Listens to GameState.mood_changed.
│       ├── mood_bar.gd                    # Updates fill color/value reactively. No polling.
│       ├── phone.tscn                     # Phone overlay panel. Shows "100 missed calls" + Order Food button.
│       ├── phone.gd                       # Order Food → GameState.set_flag("ordered_food"). Close button.
│       ├── end_screen.tscn                # Full-screen overlay for win or lose.
│       └── end_screen.gd                  # Takes a "won: bool" param. Shows win or lose text + restart button.
│
└── assets/
    ├── sprites/
    │   ├── player/
    │   │   └── player_placeholder.png     # 1-frame top-down placeholder (swap for spritesheet later)
    │   ├── girlfriend/
    │   │   ├── neutral.png                # Expression sprites mapped to mood ranges (see mood_bar or main)
    │   │   ├── angry.png
    │   │   ├── very_angry.png
    │   │   ├── slightly_calm.png
    │   │   └── happy.png
    │   └── interactables/
    │       ├── sink_placeholder.png
    │       └── broom_placeholder.png
    ├── tileset/
    │   └── room_placeholder.png           # Single-room tileset or static background image
    └── audio/
        ├── ui_click.wav                   # Optional click SFX
        └── lose.wav                       # Optional lose SFX
```

---

## Why this layout, not another

**Scripts live next to their scene, not in a separate `scripts/` folder.** Godot's node-and-scene model is built around co-location. When you move or rename a scene, the script moves with it. A flat `scripts/` folder breaks that and forces you to manually keep paths in sync.

**One autoload, not three.** `GameState` is the only autoload. Mood, flags, and lifecycle signals all live in one place. If you split mood into one autoload and flags into another, every system that needs both has to reference two globals. One is enough for this game's scope.

**`systems/` holds logic with no scene.** The intent classifier is pure input→output. It doesn't render anything, it doesn't own state, it doesn't need a node in the tree. Putting it in its own folder makes that obvious. If you later add a server manager or a save system that's also stateless logic, it goes here too.

**UI scenes are independent, instantiated into main.** `dialogue.tscn`, `mood_bar.tscn`, `phone.tscn`, and `end_screen.tscn` are each their own scene. Main instantiates them. This means you can rearrange the layout, swap one panel for another, or test a UI panel in isolation without touching main. They're not baked into main's scene tree.

**`girlfriend_marker` is in `interactables/`, not in `npc/`.** The girlfriend NPC is the thing you *talk* to. The marker is the thing you *give food* to. Those are two separate interaction systems. If you put the marker inside `npc/`, you're coupling the talking system to the action system for no reason.

**`assets/` is sorted by type, not by scene.** This is the standard Godot convention and it matters for art pipelines. When an artist swaps out all the sprites, they go to one folder. When you swap the tileset, it's one folder. Scattering assets next to each scene means hunting across the tree every time art changes.

**`addons/player2/` is untouched.** It's a drop-in plugin. You configure it via Project Settings (client_id) and the inspector (description, voice, chat config). No code changes inside it ever.

---

## Build order (maps directly to the folder structure)

1. `player/` — movement works, collision works
2. `ui/mood_bar` — GameState.mood_changed updates the bar
3. `ui/dialogue` — text input and history render (no LLM yet, just echo)
4. `systems/intent_classifier` — classify text locally, apply mood delta
5. `npc/girlfriend` — wire Player2AINPC, LLM reply flows back to dialogue
6. TTS — already handled by Player2 Character Config once step 5 works
7. `ui/phone` — open/close, order food sets flag
8. `interactables/` — sink, broom, girlfriend_marker, each wired to GameState
