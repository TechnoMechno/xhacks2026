# 🔀 Merge Guide: Gameplay Functionality → Dialogue UI Branch

## 🎯 Objective
Merge all ChatGPT mood analysis and AI girlfriend functionality from `gameplay` branch into `dialogue_ui` branch while **preserving** the Stardew Valley-style UI design.

---

## 📋 Pre-Merge Checklist

**Current Branch**: `dialogue_ui` ✅ (UI is already here)
**Target Branch**: `gameplay` (has all the AI functionality)

**What to Keep from `dialogue_ui`**:
- ✅ `Scenes/ui/dialogue_ui.tscn` - Stardew Valley-style dialogue box
- ✅ All UI components: character portrait, mood meter, dialogue box layout
- ✅ Visual design and styling

**What to Import from `gameplay`**:
- ✅ `systems/mood_analyzer.gd` - ChatGPT mood analysis system
- ✅ `Scenes/npc/girlfriend.gd` - AI girlfriend logic with winning sentences
- ✅ `autoload/game_state.gd` - Mood scoring system
- ✅ Mood compounding and winning sentences functionality

---

## 🚀 Step-by-Step Merge Process

### **Step 1: Commit Current Work**
```bash
# Save your current dialogue_ui work
git add .
git commit -m "Save dialogue_ui design before merge"
```

### **Step 2: Merge Gameplay Branch**
```bash
# Merge gameplay functionality into dialogue_ui
git merge gameplay
```

### **Step 3: Handle Merge Conflicts**

You will likely have conflicts in these files:
1. ❗ `Scenes/ui/dialogue_ui.gd` - Both branches modified this
2. ❗ `Scenes/ui/dialogue_ui.tscn` - UI structure differences
3. ❗ `Scenes/npc/girlfriend.gd` - AI logic vs UI connections
4. ❗ `autoload/game_state.gd` - State management

**Conflict Resolution Strategy**:
- **For `.tscn` files**: Keep `dialogue_ui` version (your UI design)
- **For `.gd` files**: Merge functionality (combine both)

```bash
# If dialogue_ui.tscn has conflicts, keep your version:
git checkout --ours Scenes/ui/dialogue_ui.tscn
git add Scenes/ui/dialogue_ui.tscn

# For .gd files, manually merge both versions
```

---

## 🎨 UI Component Mapping

### **Reference Design (Stardew Valley Style) → Current Implementation**

| UI Element | Expected Design (Image 1) | Current Implementation (Image 2) | Required Changes |
|------------|---------------------------|----------------------------------|------------------|
| **Girlfriend Portrait** | Character portrait on RIGHT with expression | Blue mood text at top | Replace text with animated portrait |
| **Mood Display** | Character facial expression | Text: "Mood: Crying (Score: 25)" | Use girlfriend sprite with 7 expressions |
| **Score Meter** | Not visible in reference | Shown as score number | Add visual HUD mood meter bar |
| **Dialogue Box** | Wooden box on LEFT with tan background | Gray box with white text | Apply Stardew Valley wooden frame style |
| **NPC Text** | Displayed in dialogue box | White text on gray background | Style text to match tan dialogue box |
| **Player Input** | "Type your response..." at bottom | Same location | Keep existing input field |
| **Send Button** | Blue "Send" button | Same button | Keep existing button |

---

## 🔧 Code Integration Guide

### **File: `Scenes/ui/dialogue_ui.gd`**

**What to Add from `gameplay` branch:**

```gdscript
extends Control

# ADD THESE SIGNALS (from gameplay)
signal message_sent(text: String)

# EXISTING UI REFERENCES (keep from dialogue_ui)
@onready var dialogue_label: Label = $DialogueBox/DialogueLabel
@onready var input_field: LineEdit = $InputField
@onready var send_button: Button = $SendButton
@onready var mood_label: Label = $MoodLabel  # This becomes the portrait
@onready var mood_meter: ProgressBar = $HUD/MoodMeter  # Add this node

# ADD THIS (from gameplay - girlfriend reference)
var girlfriend: Node = null

func _ready():
	# KEEP YOUR EXISTING SETUP
	send_button.pressed.connect(_on_send_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	
	# ADD THIS (from gameplay - connect to girlfriend)
	girlfriend = get_tree().get_first_node_in_group("girlfriend")
	if girlfriend:
		girlfriend.npc_reply.connect(_display_dialogue)
		girlfriend.mood_updated.connect(_on_mood_updated)
		girlfriend.npc_thinking.connect(_show_thinking_indicator)

# KEEP THIS (your existing send logic)
func _on_send_pressed():
	var message = input_field.text.strip_edges()
	if message.is_empty():
		return
	message_sent.emit(message)
	input_field.clear()

# ADD THIS (from gameplay - display girlfriend's response)
func _display_dialogue(text: String):
	dialogue_label.text = text  # Use your existing dialogue box
	# Remove thinking indicator
	_hide_thinking_indicator()

# ADD THIS (from gameplay - show thinking state)
func _show_thinking_indicator():
	dialogue_label.text = "..."  # Or use your custom animation

func _hide_thinking_indicator():
	pass  # Your logic here

# ADD THIS (from gameplay - update mood display)
func _on_mood_updated(mood_name: String, score: int):
	# REPLACE text label with portrait animation
	_update_girlfriend_portrait(mood_name)
	_update_mood_meter(score)

# NEW FUNCTION - Update girlfriend portrait based on mood
func _update_girlfriend_portrait(mood_name: String):
	# Map mood_name to your girlfriend sprite animation
	# You have 7 mood states: Happy, Soft Smile, Neutral, Sad, Crying, Angry, Furious
	match mood_name:
		"Happy":
			$GirlfriendPortrait.play("happy")
		"Soft Smile":
			$GirlfriendPortrait.play("soft_smile")
		"Neutral":
			$GirlfriendPortrait.play("neutral")
		"Sad":
			$GirlfriendPortrait.play("sad")
		"Crying":
			$GirlfriendPortrait.play("crying")
		"Angry":
			$GirlfriendPortrait.play("angry")
		"Furious":
			$GirlfriendPortrait.play("furious")

# NEW FUNCTION - Update mood meter HUD
func _update_mood_meter(score: int):
	if mood_meter:
		mood_meter.value = score  # 0-100
		# Color-code the meter
		var color = _get_mood_color(score)
		mood_meter.modulate = color

func _get_mood_color(score: int) -> Color:
	if score >= 70:
		return Color.GREEN  # Happy moods
	elif score >= 30:
		return Color.YELLOW  # Neutral/sad moods
	else:
		return Color.RED  # Angry/crying moods
```

---

## 🎨 Scene Structure Updates

### **File: `Scenes/ui/dialogue_ui.tscn`**

**Current Structure** (Keep this layout):
```
DialogueUI (Control)
├── DialogueBox (Panel)
│   └── DialogueLabel (Label) - Girlfriend's text goes here
├── GirlfriendPortrait (AnimatedSprite2D) - ADD THIS
├── InputField (LineEdit)
├── SendButton (Button)
└── HUD (Control) - ADD THIS
    └── MoodMeter (ProgressBar) - ADD THIS
```

**Steps to Update Scene**:

1. **Add Girlfriend Portrait Node**:
   - Right-click `DialogueUI` → Add Child Node → `AnimatedSprite2D`
   - Name it: `GirlfriendPortrait`
   - Position: Right side of screen (matching Stardew Valley reference)
   - Add 7 animations: happy, soft_smile, neutral, sad, crying, angry, furious

2. **Add Mood Meter Node**:
   - Right-click `DialogueUI` → Add Child Node → `Control` (name it "HUD")
   - Right-click `HUD` → Add Child Node → `ProgressBar` (name it "MoodMeter")
   - Set ProgressBar properties:
     - `min_value`: 0
     - `max_value`: 100
     - `value`: 50 (starting mood)
   - Position: Top-right corner or above girlfriend portrait

3. **Keep Existing Nodes**:
   - ✅ DialogueBox (your Stardew Valley styled box)
   - ✅ DialogueLabel (displays girlfriend's responses)
   - ✅ InputField (player types here)
   - ✅ SendButton (submits message)

---

## 🔗 Connection Points

### **How Data Flows** (Gameplay → UI)

```
Player types message
    ↓
InputField → message_sent signal
    ↓
Girlfriend.receive_player_message()
    ↓
├── Check winning sentences (instant win)
├── ChatGPT analyzes mood
└── Player2 generates response
    ↓
girlfriend.npc_reply signal
    ↓
DialogueUI._display_dialogue()
    ↓
Update DialogueLabel with response
    ↓
girlfriend.mood_updated signal
    ↓
DialogueUI._on_mood_updated()
    ↓
├── Update GirlfriendPortrait animation
└── Update MoodMeter progress bar
```

---

## ✅ Testing Checklist After Merge

### **1. Girlfriend Response Display**
- [ ] Type a message and click Send
- [ ] Girlfriend's response appears in DialogueBox
- [ ] Text is readable in Stardew Valley-styled box

### **2. Mood Portrait Animation**
- [ ] Start game: Portrait shows "Furious" expression
- [ ] Say something nice: Portrait changes to happier expression
- [ ] Say something mean: Portrait changes to sad/angry expression
- [ ] All 7 expressions work correctly

### **3. Mood Meter Display**
- [ ] Meter starts at 50 (middle)
- [ ] Meter goes up when girlfriend is happy
- [ ] Meter goes down when girlfriend is upset
- [ ] Color changes: Red (0-29), Yellow (30-69), Green (70-100)

### **4. Winning Sentences**
- [ ] Say sentence 1: "I'm so sorry I made you worry, that was completely my fault"
- [ ] Console shows: "🏆 WINNING SENTENCE DETECTED! Sequence: 1/4"
- [ ] Say sentence 2: "You deserve so much better than how I treated you today"
- [ ] Console shows: "Sequence: 2/4"
- [ ] Say sentence 3: "I promise I'll always call you first if something comes up"
- [ ] Console shows: "Sequence: 3/4"
- [ ] Say sentence 4: "You're the most important person in my life and I love you"
- [ ] Console shows: "🎉🎉🎉 ALL 4 WINNING SENTENCES! INSTANT WIN!"
- [ ] Mood instantly becomes 100, portrait shows "Happy"

### **5. Positive Compounding**
- [ ] Say multiple sincere positive messages in a row
- [ ] Mood increases faster with each consecutive positive response
- [ ] Console logs show positive_streak count

### **6. Console Logs**
- [ ] `[Girlfriend] 💬 Player said: [your message]`
- [ ] `[MoodAnalyzer] 📊 MOOD ANALYSIS RESULT`
- [ ] `[Girlfriend] 🏆 WINNING SENTENCE DETECTED!` (when applicable)

---

## 🐛 Common Issues & Fixes

### **Issue 1: Girlfriend not responding**
**Cause**: girlfriend variable not connected
**Fix**: Ensure girlfriend is in "girlfriend" group
```gdscript
# In girlfriend.gd _ready():
add_to_group("girlfriend")
```

### **Issue 2: Mood meter not updating**
**Cause**: MoodMeter node not found
**Fix**: Check node path in dialogue_ui.tscn
```gdscript
@onready var mood_meter: ProgressBar = $HUD/MoodMeter
```

### **Issue 3: Portrait not changing**
**Cause**: Animation names don't match mood names
**Fix**: Ensure animations match exactly:
- "Happy", "Soft Smile", "Neutral", "Sad", "Crying", "Angry", "Furious"

### **Issue 4: Merge conflict in .tscn file**
**Cause**: Both branches modified scene structure
**Fix**: Use visual diff tool or keep dialogue_ui version:
```bash
git checkout --ours Scenes/ui/dialogue_ui.tscn
# Then manually re-add nodes from gameplay if needed
```

### **Issue 5: ChatGPT not analyzing**
**Cause**: MoodAnalyzer node missing or API key not set
**Fix**: 
1. Ensure `Girlfriend.tscn` has `MoodAnalyzer` child node
2. Set API key: `export OPENAI_API_KEY="your-key-here"`
3. Restart Godot

---

## 📦 Files Modified After Merge

**Files from `gameplay` (bring over completely)**:
- ✅ `systems/mood_analyzer.gd`
- ✅ `WINNING_SENTENCES.txt`
- ✅ `CHATGPT_PROMPT_BACKUP.txt`
- ✅ `PROJECT_FUNCTIONALITY_SUMMARY.md`

**Files to Merge (combine both branches)**:
- 🔀 `Scenes/npc/girlfriend.gd` - Add winning sentences + mood tracking
- 🔀 `Scenes/ui/dialogue_ui.gd` - Add mood display functions
- 🔀 `autoload/game_state.gd` - Keep gameplay's mood system

**Files to Keep from `dialogue_ui` (your UI)**:
- ✅ `Scenes/ui/dialogue_ui.tscn` - Your Stardew Valley UI design
- ✅ Any custom UI assets/sprites

---

## 🎯 Expected Result

**After successful merge, you should have**:

✅ **Stardew Valley-style UI** (from dialogue_ui branch)
- Wooden dialogue box with tan background
- Player input at bottom
- Send button styled correctly

✅ **ChatGPT Mood Analysis** (from gameplay branch)
- Analyzes every player message
- Detects interaction type (genuine_positive, excuse_lie, etc.)
- Compounding positive and negative responses

✅ **Girlfriend Portrait with Expressions** (NEW integration)
- 7 animated expressions based on mood
- Changes dynamically as mood updates
- Positioned on right side (Stardew Valley style)

✅ **Visual Mood Meter** (NEW integration)
- HUD bar showing 0-100 score
- Color-coded by mood tier
- Smooth transitions

✅ **Winning Sentences System** (from gameplay branch)
- 4 magic sentences for instant win
- Progress tracking in console
- Bypasses all AI when completed

---

## 🚨 Emergency Rollback

If merge breaks everything:
```bash
# Abort the merge
git merge --abort

# Go back to before merge
git reset --hard HEAD

# You're back to safe dialogue_ui branch
```

---

## 📞 Final Checklist Before Declaring Merge Complete

- [ ] Game runs without errors
- [ ] Can type messages and send them
- [ ] Girlfriend responds with dialogue
- [ ] Dialogue appears in your styled UI box
- [ ] Girlfriend portrait shows correct expression for mood
- [ ] Mood meter updates when mood changes
- [ ] Winning sentences trigger instant win (test all 4 in sequence)
- [ ] Console logs show detailed mood analysis
- [ ] UI looks like Stardew Valley reference image
- [ ] All 7 mood expressions display correctly

---

## 🎉 Success!

When all checkboxes are complete:
1. Commit the merged result:
   ```bash
   git add .
   git commit -m "Merge gameplay functionality into dialogue_ui - ChatGPT mood system + Stardew Valley UI"
   ```

2. Push to remote:
   ```bash
   git push origin dialogue_ui
   ```

3. Optional: Create pull request to merge back into main

---

**Author**: AI Assistant
**Date**: February 1, 2026
**Purpose**: Safe merge of gameplay AI functionality into dialogue_ui design branch
