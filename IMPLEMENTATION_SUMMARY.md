# Angry Girlfriend Game - Implementation Summary

## Overview
A top-down narrative game where the player must win back their angry girlfriend (Olivia/Penny) through dialogue. The game uses Player2AI for LLM-powered NPC responses with mood-aware behavior.

---

## Core Game Loop

```
Player enters house
    → Girlfriend speaks (LLM response)
    → Player types message OR performs action
    → Intent classified → Mood changes
    → System prompt updated if mood tier changed
    → LLM receives world_status context
    → Girlfriend responds based on mood
    → Repeat until Win (mood >= 80) or Lose (mood <= 0)
```

---

## Mood System

### Configuration
- **Range**: 0-100
- **Starting mood**: 50
- **Win threshold**: 80
- **Lose threshold**: 0

### Mood Deltas (defined in `autoload/game_state.gd`)
| Intent | Delta |
|--------|-------|
| apology | +10 |
| empathy | +15 |
| explanation | +5 |
| do_dishes | +15 |
| clean | +10 |
| give_food | +20 |
| lie | -10 |
| insult | -15 |
| gaslight | -20 |
| nonsense | -5 |

### Flags
Tracked actions that provide context to the LLM:
- `apologized`
- `did_dishes`
- `cleaned`
- `ordered_food`
- `gave_food`

---

## LLM Integration (Player2AI)

### Two-Pronged Mood-Aware System

#### 1. World Status (Every Message)
Injected via `ai_npc.notify()` before each chat. Contains:
- Current emotional state description (no numbers)
- Status of completed actions

Example:
```
"Your current emotional state: You're angry and hurt, demanding real effort. | So far: received an apology, they did the dishes"
```

#### 2. Dynamic System Prompt (On Tier Change)
21 mood tiers (every 5 points). System prompt updates when crossing thresholds.

| Tier | Mood Range | Personality |
|------|------------|-------------|
| 0 | 0-4 | Furious, about to leave |
| 4 | 20-24 | Upset and defensive |
| 6 | 30-34 | Guarded but present |
| 10 | 50-54 | Softening |
| 14 | 70-74 | Forgiving |
| 20 | 100 | Blissfully happy |

---

## File Structure

### Core Game Files
```
autoload/
  game_state.gd          # Mood, flags, win/lose signals

Scenes/
  main/
    main.tscn            # Main game scene
    main.gd              # Wires signals, player freeze

  npc/
    girlfriend.gd        # NPC brain, mood-aware LLM calls

  Girlfriend.tscn        # NPC scene with Player2AINPC

  player/
    Player.tscn          # Player scene
    player.gd            # Movement, interaction detection

  ui/
    dialogue_ui.tscn     # Chat UI
    dialogue_ui.gd       # Input handling, message display

  testing/
    npc_chat_test.gd     # Console-based test system
```

### Key Autoloads (project.godot)
- `GameState` - Game state singleton
- `Player2API` - Player2 API access
- `Player2AuthHelper` - Authentication
- `IntentClassifier` - Message intent detection

---

## Signal Flow

```
Player presses interact (ui_accept)
    → player.gd: _interact_with_closest()
    → girlfriend.gd: interact()
    → girlfriend.gd: interaction_requested signal
    → main.gd: _on_girlfriend_interaction()
    → dialogue_ui.gd: open_dialogue()
    → dialogue_ui.gd: dialogue_opened signal
    → main.gd: freezes player

Player sends message
    → dialogue_ui.gd: _send_message()
    → girlfriend.gd: receive_player_message()
    → IntentClassifier.classify() → intent
    → GameState.apply_intent() → mood change
    → girlfriend.gd: _update_system_prompt_for_mood()
    → girlfriend.gd: ai_npc.notify() (world_status)
    → girlfriend.gd: ai_npc.chat()
    → Player2AINPC → LLM API call
    → girlfriend.gd: _on_chat_received()
    → girlfriend.gd: npc_reply signal
    → dialogue_ui.gd: _on_npc_reply() → displays text

Mood reaches threshold
    → GameState: game_won or game_lost signal
    → main.gd: _on_game_won() or _on_game_lost()
```

---

## Debug Controls

| Key | Action |
|-----|--------|
| TAB | Reset conversation history |
| WASD/Arrows | Move player |
| Enter/Space | Interact with NPC |
| Esc | Close dialogue |

Console commands (test scene only):
- `mood` - Show current mood
- `flags` - Show flags
- `status` - Full game state
- `clear` - Reset game

---

## Player2AI Configuration

### In Girlfriend.tscn (Player2AINPC node)
- `character_name`: "Penny"
- `character_description`: Base personality
- `character_system_message`: Dynamic (updated by girlfriend.gd)
- `auto_store_conversation_history`: true (can be reset with TAB)

### TTS Configuration
- Voice ID configured in Character Config
- `tts_speed`: 1.1
- `tts_default_gender`: female

---

## To Disable Power HUD
Edit `addons/player2/api_config.tres`:
- Remove or clear the `ui_power_hud` line (line 25)

Or in Godot Editor:
1. Open `res://addons/player2/api_config.tres`
2. Clear the "Ui Power Hud" field in Inspector

---

## Merge Checklist

- [ ] All files saved
- [ ] Test player movement
- [ ] Test NPC interaction (walk up, press Enter)
- [ ] Test dialogue sends/receives
- [ ] Test mood changes appear in console
- [ ] Test mood tier prompt updates
- [ ] Test win condition (mood >= 80)
- [ ] Test lose condition (mood <= 0)
- [ ] Test conversation reset (TAB key)
- [ ] Verify TTS works (if enabled)

---

## Known Issues / TODOs

1. `IntentClassifier` autoload may need implementation - currently referenced but not seen
2. Win/lose screens not implemented (just prints to console)
3. Power HUD still displays - needs manual config change to hide
4. Conversation history persists between sessions (by design, can reset with TAB)
