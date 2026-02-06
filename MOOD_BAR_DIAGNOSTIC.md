# Mood Bar Diagnostic Guide

## ✅ Good News: The Fix Has Already Been Applied!

Your files show the correct structure:
- `mood_bar.gd` extends Control ✓
- Script is attached to parent MoodBar node ✓
- Script references child $HealthBar ✓
- Signal connection is present ✓

## 🔍 Runtime Debugging Steps

Run your game and check the console output. You should see these logs in sequence:

### Step 1: Check MoodBar Initialization
Look for these logs when the game starts:
```
[MoodBar] ========== MOOD BAR READY ==========
[MoodBar] _ready() called, visible = true
[MoodBar] Node path: <path>
[MoodBar] Initializing with mood: 50
[MoodBar] ✅ Connected to GameState.mood_changed signal
[MoodBar] mood_changed signal has 2 connection(s)
```

**Problem if you see:**
- No `[MoodBar]` logs → MoodBar scene not instantiated in HUD
- `visible = false` → MoodBar is hidden
- `has 0 connection(s)` → Signal not connected
- `has 1 connection(s)` → Only main.gd connected, MoodBar missing

---

### Step 2: Check API Key Configuration
Look for these logs:
```
[MoodAnalyzer] 🔑 API Key Status:
[MoodAnalyzer] ✅ API Key loaded: sk-proj...xxxx
[MoodAnalyzer] Using model: gpt-3.5-turbo
```

**Problem if you see:**
```
[MoodAnalyzer] ❌ NO API KEY FOUND!
```

**Solution**: Set your OpenAI API key in one of these ways:
1. **Option A**: Open `Scenes/npc/Girlfriend.tscn` in Godot → Select `MoodAnalyzer` node → Inspector panel → Set `api_key` property
2. **Option B**: Create a `.env` file in project root:
   ```
   OPENAI_API_KEY=sk-proj-your-key-here
   ```

---

### Step 3: Check Mood Analysis Flow
When you send a message to the girlfriend, look for this sequence:

```
[Girlfriend] 💬 Player said: <your message>
[Girlfriend] Triggering mood analysis on player message: <your message>

[MoodAnalyzer] 🔍 ANALYZING PLAYER MESSAGE
[MoodAnalyzer] Player said: <your message>
[MoodAnalyzer] Current Score: 50
[MoodAnalyzer] Sending to ChatGPT API...

[MoodAnalyzer] ✅ ChatGPT Response Received:
[MoodAnalyzer] 📊 MOOD ANALYSIS RESULT:
[MoodAnalyzer]   Relationship Score: 65

[Girlfriend] 🎯 MOOD ANALYSIS RECEIVED:
[Girlfriend]   Score: 65

[GameState] ====== EMITTING mood_changed signal ======
[GameState] New mood value: 65
[GameState] Signal has 2 listener(s)

[MoodBar] >>>>>> SIGNAL RECEIVED: _on_mood_changed with value: 65
[MoodBar] Animating from 50 to 65
[MoodBar] Tween started successfully
```

---

## 🐛 Common Issues & Solutions

### Issue 1: MoodBar logs never appear
**Diagnosis**: MoodBar scene not instantiated or not in scene tree

**Solution**: Check [Scenes/hud/hud.tscn](Scenes/hud/hud.tscn) - should contain:
```
[node name="MoodBar" parent="." instance=ExtResource("1_p5wc4")]
```

---

### Issue 2: Signal emitted but MoodBar doesn't receive it
**Diagnosis**: Look for this in console:
```
[GameState] Signal has 2 listener(s)
[GameState]   -> Callable(...)
```

If you see 2 listeners but no `[MoodBar] >>>>>> SIGNAL RECEIVED`, the MoodBar connection failed.

**Solution**: 
1. Open [Scenes/ui/mood_bar.gd](Scenes/ui/mood_bar.gd)
2. In `_ready()` function, verify line 35:
   ```gdscript
   GameState.mood_changed.connect(_on_mood_changed)
   ```
3. Make sure `_on_mood_changed` function exists (around line 51)

---

### Issue 3: Signal received but bar doesn't animate
**Diagnosis**: You see:
```
[MoodBar] >>>>>> SIGNAL RECEIVED: _on_mood_changed with value: 65
[MoodBar] animate_to() called with: 65
[MoodBar] ERROR: Failed to create tween!
```

**Solution**: Check if the MoodBar node is in the scene tree and active. Tweens can't be created on nodes that aren't properly initialized.

---

### Issue 4: Health bar child node not found
**Diagnosis**: You see an error like:
```
ERROR: Cannot get property 'min_value' on a null value.
```

**Solution**: 
1. Open [Scenes/ui/mood_bar.tscn](Scenes/ui/mood_bar.tscn) in Godot
2. Verify child node structure:
   ```
   MoodBar (Control) [script attached here]
   └── HealthBar (TextureProgressBar) [NO script]
       └── MaxHealth (Label)
   ```
3. If "HealthBar" is named differently, update line 6 in mood_bar.gd:
   ```gdscript
   @onready var health_bar: TextureProgressBar = $HealthBar  # Match actual node name
   ```

---

## 🧪 Quick Test

Press these keys during gameplay to manually test mood changes:

- **Press `=` (equals key)**: Set mood to 80 (win threshold)
- **Press `-` (minus key)**: Set mood to 0 (lose threshold)

If the bar animates when you press these keys, the MoodBar is working! The problem is with the ChatGPT → GameState flow.

If the bar does NOT animate:
1. Check that you see `[MoodBar]` initialization logs
2. Check that `[GameState] Signal has 2 listener(s)` appears
3. Check that `[MoodBar] >>>>>> SIGNAL RECEIVED` appears after pressing `=` or `-`

---

## 📊 Expected Visual Behavior

When ChatGPT returns a score:
1. The red heart sprite should **smoothly fill** from current value to new value
2. Animation takes **2 seconds** (cubic ease-out)
3. The number label should **count up/down** during animation

If you see:
- ❌ Bar stays empty → Check initialization and visibility
- ❌ Bar jumps instantly → Animation not working, but value updates
- ❌ Bar doesn't change at all → Signal not reaching MoodBar

---

## 🎯 Next Steps

1. **Run the game** and copy ALL console output to a text file
2. **Send a message** to the girlfriend (e.g., "I'm sorry")
3. **Search the console output** for:
   - `[MoodBar]` logs
   - `[GameState] EMITTING mood_changed`
   - `[MoodAnalyzer]` logs
4. **Share the relevant logs** to identify exactly where the flow breaks

---

## 💡 Additional Debug Option

If you want even MORE detailed logging, add this to [mood_bar.gd](Scenes/ui/mood_bar.gd) in the `animate_to()` function, after line 75:

```gdscript
animation_tween.finished.connect(func():
	print("[MoodBar] 🎬 Animation completed! Final value: ", health_bar.value)
)
```

This will confirm when the animation finishes.
