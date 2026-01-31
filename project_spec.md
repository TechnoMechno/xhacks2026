# Homecoming — Project Specification for Claude Code

## Overview
**Type**: Top-down narrative game  
**Engine**: Godot 4.5  
**Core Loop**: Talk + physical actions → mood changes → LLM responds → win/lose  
**Tech**: Player2 AI NPC Plugin (https://github.com/elefant-ai/player2-ai-npc-godot)

---

## System Architecture

### Core Principle: Single Source of Truth
- **GameState autoload** owns ALL game state (mood int 0-100, flags dict)
- Everything else is **reactive** (reads from GameState, writes to GameState, listens to signals)
- No other script holds state
- Mood logic controlled by game code, **never by LLM**

### Data Flow
```
Player types/acts → Intent Classifier (local) → GameState.apply_intent() 
→ mood changes → signal fires → UI updates
→ text sent to Player2AINPC (LLM) → chat_received signal → UI displays reply
→ TTS plays automatically
```

---

## File Structure

```
project_root/
├── project.godot                          # Input map + autoload config
├── addons/player2/                        # Player2 plugin (external, drag-drop)
├── autoload/
│   └── game_state.gd                      # Global state singleton
├── systems/
│   └── intent_classifier.gd               # Stateless classifier (extends RefCounted)
├── scenes/
│   ├── main/
│   │   ├── main.tscn                      # Root scene, wires everything
│   │   └── main.gd
│   ├── player/
│   │   ├── player.tscn                    # CharacterBody2D + DetectArea (Area2D)
│   │   └── player.gd
│   ├── npc/
│   │   ├── girlfriend.tscn                # Node with Player2AINPC child
│   │   └── girlfriend.gd                  # NPC brain (dialogue loop orchestrator)
│   ├── interactables/
│   │   ├── interactable.gd                # Base class (extends Node2D)
│   │   ├── sink.tscn / sink.gd
│   │   ├── broom.tscn / broom.gd
│   │   └── girlfriend_marker.tscn / girlfriend_marker.gd
│   └── ui/
│       ├── dialogue.tscn / dialogue.gd    # Chat panel
│       ├── mood_bar.tscn / mood_bar.gd
│       ├── phone.tscn / phone.gd
│       └── end_screen.tscn / end_screen.gd
└── assets/
    ├── sprites/
    ├── tileset/
    └── audio/
```

---

## Component Specs

### 1. GameState (`autoload/game_state.gd`)

**Extends**: Node  
**Purpose**: Global state singleton, registered as autoload in project.godot

**State:**
```gdscript
var mood: int = 40  # 0-100, win at 70, lose at 0
var flags: Dictionary = {
    "apologized": false,
    "did_dishes": false,
    "cleaned": false,
    "ordered_food": false,
    "gave_food": false
}
```

**Constants:**
```gdscript
const MOOD_MIN = 0
const MOOD_MAX = 100
const MOOD_START = 40
const MOOD_WIN = 70

const MOOD_DELTAS = {
    "apology": 10,
    "empathy": 12,
    "explanation": 5,
    "do_dishes": 10,
    "clean": 10,
    "give_food": 15,
    "lie": -15,
    "gaslight": -25,
    "insult": -20,
    "nonsense": -10,
    "neutral": 0
}
```

**Signals:**
```gdscript
signal mood_changed(new_mood: int)
signal game_won
signal game_lost
signal flag_changed(flag_name: String, value: bool)
```

**Methods:**
```gdscript
func apply_intent(intent: String) -> int:
    # Get base delta from MOOD_DELTAS
    # If delta > 0: add +3 bonus per active flag
    # Clamp mood to [0, 100]
    # Emit mood_changed
    # Check win/lose conditions, emit signals
    # Return actual delta applied

func set_flag(flag_name: String) -> void:
    # Set flag to true if not already
    # Emit flag_changed if it flipped
```

---

### 2. IntentClassifier (`systems/intent_classifier.gd`)

**Extends**: RefCounted  
**Purpose**: Pure stateless classifier, no dependencies

**Method:**
```gdscript
static func classify(text: String) -> String:
    # Convert to lowercase, strip edges
    # Check keyword lists in priority order:
    # 1. gaslight: "didn't happen", "you're crazy", "imagined", "never said", "overreacting"
    # 2. insult: "stupid", "idiot", "shut up", "dumb", "hate you", "worthless"
    # 3. lie: "i was at work", "nothing happened", "i forgot", "i didn't"
    # 4. apology: "sorry", "apologize", "my bad", "forgive me"
    # 5. empathy: "i understand", "you're right", "i hear you", "that must"
    # 6. explanation: "because", "the reason", "let me explain", "i was"
    # Return first match or "nonsense" as fallback
```

---

### 3. Player (`scenes/player/player.gd`)

**Extends**: CharacterBody2D

**Children:**
- Sprite2D (visual)
- CollisionShape2D (physics body)
- DetectArea (Area2D + CollisionShape2D for interaction range ~40px radius)

**Exports:**
```gdscript
@export var speed: float = 200.0
```

**Input (defined in project.godot):**
- move_left/right/up/down (WASD + arrows)
- interact (E)

**Behavior:**
- `_physics_process`: 8-way movement via Input.get_vector(), move_and_slide()
- `_input`: On "interact" pressed → call interact() on closest nearby interactable
- Track nearby via DetectArea.area_entered/exited signals (stores Array of interactables)
- Interactables must have `interact()` method

---

### 4. NPC Brain (`scenes/npc/girlfriend.gd`)

**Extends**: Node (attached to girlfriend scene)

**Children:**
- Player2AINPC (from plugin, configured in inspector)

**Player2AINPC Inspector Config:**
- **Description**: "You are an angry girlfriend confronting your partner who came home late at 2 AM with 100 missed calls. You are emotional, sarcastic, and reactive. You respond with realistic human dialogue. Never mention game mechanics or mood numbers. Stay in character."
- **Character Config > Voice ID**: (user chooses from Player2 voice list)
- **Chat Config > Remember History**: true
- **Chat Config > Greet On Start**: true

**Signals:**
```gdscript
signal npc_reply(text: String)
signal npc_thinking
```

**Methods:**
```gdscript
func receive_player_message(text: String) -> void:
    # 1. Classify intent: var intent = IntentClassifier.classify(text)
    # 2. Apply mood: GameState.apply_intent(intent)
    # 3. Emit npc_thinking
    # 4. Call Player2AINPC.chat(text) → sends to LLM

func _on_chat_received(reply: String) -> void:
    # Connected to Player2AINPC.chat_received signal
    # Emit npc_reply(reply)
    # TTS plays automatically via Player2
```

---

### 5. Dialogue UI (`scenes/ui/dialogue.gd`)

**Extends**: Control

**Children:**
- History (RichTextLabel) — auto-scroll, bbcode enabled
- InputRow (HBoxContainer)
  - TextInput (LineEdit)
  - SendButton (Button)
- ThinkingLabel (Label) — "..." indicator

**Properties:**
```gdscript
var npc_brain: Node  # Set by main.gd after instantiation
```

**Behavior:**
- On Send button / TextInput.text_submitted:
  1. Append "[You]: {text}" to History
  2. Clear TextInput
  3. Call npc_brain.receive_player_message(text)
- On npc_brain.npc_thinking: show ThinkingLabel
- On npc_brain.npc_reply(text):
  1. Hide ThinkingLabel
  2. Append "[Her]: {text}" to History
  3. Scroll to bottom

---

### 6. Mood Bar (`scenes/ui/mood_bar.gd`)

**Extends**: Control

**Children:**
- ProgressBar (min=0, max=100, value=40)

**Behavior:**
- On GameState.mood_changed(new_mood):
  - Update ProgressBar.value
  - (Optional) Change color by range

---

### 7. Phone UI (`scenes/ui/phone.gd`)

**Extends**: Control (Panel overlay)

**Children:**
- MissedCallsLabel (Label: "100 Missed Calls")
- OrderFoodButton (Button)
- CloseButton (Button)

**Behavior:**
- Initially hidden (visible=false)
- On OrderFoodButton pressed:
  - GameState.set_flag("ordered_food")
  - Disable button, change text to "Ordered!"
- On CloseButton pressed: hide self

---

### 8. End Screen (`scenes/ui/end_screen.gd`)

**Extends**: Control (full-screen overlay)

**Children:**
- ResultLabel (Label)
- RestartButton (Button)

**Methods:**
```gdscript
func show_result(won: bool) -> void:
    # Set ResultLabel text based on won bool
    # Make visible

func _on_restart_pressed() -> void:
    get_tree().reload_current_scene()
```

---

### 9. Interactables Base (`scenes/interactables/interactable.gd`)

**Extends**: Node2D

**Children (each interactable):**
- Sprite2D
- Area2D (named "Hitbox") + CollisionShape2D

**Base class:**
```gdscript
extends Node2D
@export var label: String = "Object"
func interact() -> void:
    push_warning("No interact() implementation")
```

**Sink (`sink.gd`):**
```gdscript
extends "res://scenes/interactables/interactable.gd"
func interact() -> void:
    GameState.apply_intent("do_dishes")
    GameState.set_flag("did_dishes")
```

**Broom (`broom.gd`):**
```gdscript
extends "res://scenes/interactables/interactable.gd"
func interact() -> void:
    GameState.apply_intent("clean")
    GameState.set_flag("cleaned")
```

**Girlfriend Marker (`girlfriend_marker.gd`):**
```gdscript
extends "res://scenes/interactables/interactable.gd"
func interact() -> void:
    if not GameState.flags["ordered_food"]:
        return
    if GameState.flags["gave_food"]:
        return
    GameState.apply_intent("give_food")
    GameState.set_flag("gave_food")
```

---

### 10. Main Scene (`scenes/main/main.gd`)

**Extends**: Node2D

**Children (instantiated):**
- TileMap or StaticBackground (Sprite2D)
- Player
- Girlfriend
- Sink, Broom, GirlfriendMarker (positioned around room)
- UI Layer (CanvasLayer)
  - DialogueUI
  - MoodBar
  - PhoneButton (Button)
  - PhoneUI (hidden by default)
  - EndScreen (hidden by default)

**Responsibilities:**
```gdscript
func _ready() -> void:
    # Wire signals
    GameState.game_won.connect(func(): end_screen.show_result(true))
    GameState.game_lost.connect(func(): end_screen.show_result(false))
    phone_button.pressed.connect(func(): phone_ui.visible = true)
    
    # Set references
    dialogue_ui.npc_brain = girlfriend
```

---

## Player2 Plugin Setup

**Required setup steps** (user does this once):
1. Download plugin from https://github.com/elefant-ai/player2-ai-npc-godot
2. Drag `addons/player2/` into project root
3. Enable plugin: Project → Project Settings → Plugins → Player2 (check enabled)
4. Get client_id from https://player2.game/profile/developer
5. Set client_id: Project → Project Settings → Player2 → Game Key

**In girlfriend.tscn:**
- Add Player2AINPC node as child
- Configure in inspector (description, voice, chat config)

**TTS is automatic** — no code needed, handled by Player2 when Character Config is set.

---

## Asset Requirements

### Sprites (placeholders OK)
- Player: 32x32px top-down
- Girlfriend: 32x32px top-down idle
- Girlfriend expressions: 5x 64x64px face sprites (very angry, angry, neutral, calm, happy)
- Sink: 32x32px
- Broom: 16x32px
- Tileset: 16x16px tiles OR single 640x480px room background

### UI (placeholders OK)
- Dialogue panel background
- Buttons (normal/pressed states)
- Mood bar frame + fill
- Phone overlay panel

### Audio
- TTS: handled by Player2 (no asset)
- UI click SFX (optional)
- Lose SFX (optional)

---

## Testing Checklist (MVP)

- [ ] Player moves with WASD
- [ ] Player interacts with objects (E key)
- [ ] Typing messages changes mood based on intent
- [ ] NPC responds with LLM-generated text
- [ ] TTS plays for NPC responses
- [ ] Mood bar updates in real-time
- [ ] Phone opens, order food button works
- [ ] Can give food to girlfriend (requires ordering first)
- [ ] Win screen shows at mood 70
- [ ] Lose screen shows at mood 0
