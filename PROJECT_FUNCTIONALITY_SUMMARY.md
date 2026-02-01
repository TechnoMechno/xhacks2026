# 🎮 AI Girlfriend Game - Functionality Summary for UI Integration

## 📋 Project Overview
This is an AI-powered girlfriend dialogue game where the player must convince an angry girlfriend through conversation. The game uses **ChatGPT for mood analysis** and **Player2 API for girlfriend dialogue generation**.

---

## 🎯 Core Game Mechanics

### **Objective**
- **Starting State**: Girlfriend is angry (Score: 50, Mood: Furious)
- **Goal**: Reach Score 100 (Mood: Happy) to win
- Player convinces girlfriend through dialogue choices

### **Two Ways to Win**
1. **Positive Compounding**: Build trust through consecutive genuine responses
2. **Winning Sentences**: Say 4 specific sentences in sequence for instant win

---

## 📊 Mood System Architecture

### **Mood Score Range**: 0-100
- **0-9**: Furious (worst)
- **10-19**: Angry
- **20-29**: Crying
- **30-39**: Sad
- **40-49**: Neutral
- **50-69**: Conflicted/Calming
- **70-89**: Soft Smile
- **90-100**: Happy (win condition)

### **Current Mood Display Location**
- Top of screen: `Mood: [Emoji] [Category] (Score: XX)`
- Example: `😢 Mood: Crying (Score: 30)`

---

## 🤖 AI Integration Details

### **System Flow**
```
Player Input → Winning Sentence Check → ChatGPT Mood Analysis → Player2 Dialogue Generation → UI Update
```

### **ChatGPT Mood Analyzer** (`systems/mood_analyzer.gd`)
**Purpose**: Analyzes player's dialogue to determine girlfriend's emotional response

**Input**:
- Player's message text
- Current mood score
- Current mood state (Furious, Angry, etc.)
- Last 2 interactions history

**Output** (JSON):
```json
{
  "mood": "Crying",
  "score": 30,
  "interaction_type": "genuine_positive",
  "positive_streak": 2,
  "antagonistic_streak": 0
}
```

**Interaction Types**:
- `genuine_positive`: Sincere, truthful, empathetic
- `neutral`: Neither good nor bad
- `excuse_lie`: Making excuses (she detects lies)
- `antagonistic`: Deliberately upsetting

### **Player2 NPC** (`Scenes/npc/girlfriend.gd`)
**Purpose**: Generates girlfriend's dialogue responses using LLM

**Personality Tiers**: 11 different personality prompts based on mood (0-100)
- Each tier adjusts tone from "furious" to "loving"
- Example Tier 0: "You're furious and questioning this relationship"
- Example Tier 100: "You're happy and the fight is behind you"

---

## 🎲 Scoring System

### **Positive Compounding** (NEW!)
Consecutive genuine positive responses = escalating bonuses:
- 1st genuine_positive: +8 to +12
- 2nd consecutive: +12 to +18
- 3rd consecutive: +18 to +25
- 4th+ consecutive: +25 to +35

### **Negative Scoring**
- `excuse_lie`: -3 to -15 (depending on mood)
- `antagonistic`: -10 to -15 (COMPOUNDS!)
  - 2nd consecutive: -15 to -25
  - 3rd consecutive: Score drops to 0

### **Streak Breaking**
- Any non-positive response breaks positive streak
- Any non-antagonistic response breaks antagonistic streak

---

## 🏆 Winning Sentences System

### **Instant Win Cheat Code**
Say these 4 sentences **sequentially** (in order) = Instant Score 100:

1. "I'm so sorry I made you worry, that was completely my fault"
2. "You deserve so much better than how I treated you today"
3. "I promise I'll always call you first if something comes up"
4. "You're the most important person in my life and I love you"

**Implementation**:
- Checked BEFORE ChatGPT analysis
- Supports fuzzy matching (2/3 key phrases required)
- Console shows progress: "🏆 WINNING SENTENCE DETECTED! Sequence: 3/4"
- Bypasses all AI logic on completion

---

## 📡 Key Signals & Events

### **Signals Emitted by Girlfriend**
```gdscript
signal npc_reply(text: String)              # Girlfriend's dialogue response
signal npc_thinking                          # Girlfriend is processing
signal mood_updated(mood_name: String, score: int)  # Mood changed
signal interaction_requested                 # Player wants to talk
```

### **Game State** (`autoload/game_state.gd`)
```gdscript
var mood: int = 50  # Current mood score (0-100)
# Accessible globally via GameState.mood
```

---

## 🎨 UI Integration Guide for Teammate

### **Current UI Elements to Replace/Enhance**
1. **Mood Display** (Top of screen)
   - Currently: Text label with emoji
   - **NEW DESIGN**: Character portrait with animated expressions
   
2. **Score Display**
   - Currently: Text "(Score: XX)"
   - **NEW DESIGN**: Visual mood meter/bar

3. **Dialogue Box**
   - Currently: Basic text display
   - **NEW DESIGN**: Stardew Valley-style dialogue box with character portrait

### **Required UI Components**

#### **1. Character Portrait (Right Side)**
**Purpose**: Visual representation of girlfriend's mood

**States to Handle** (7 mood categories):
- `Happy`: Joyful expression, bright colors
- `Soft Smile`: Content, warm expression
- `Neutral`: Calm, matter-of-fact
- `Sad`: Disappointed, dejected
- `Crying`: Deeply upset, tears
- `Angry`: Irritated, frowning
- `Furious`: Extremely angry, explosive

**Animation Trigger**:
```gdscript
# Connect to girlfriend's signal
girlfriend.mood_updated.connect(_on_mood_updated)

func _on_mood_updated(mood_name: String, score: int):
    # Update portrait animation based on mood_name
    character_portrait.play_mood(mood_name)
    mood_meter.set_value(score)
```

#### **2. Mood Meter/Bar**
**Purpose**: Visual representation of score (0-100)

**Requirements**:
- Display current score value
- Color-coded by mood tier:
  - Red (0-29): Furious/Angry/Crying
  - Yellow (30-69): Sad/Neutral/Conflicted
  - Green (70-100): Soft Smile/Happy
- Smooth transitions when score changes

#### **3. Dialogue Box**
**Purpose**: Display girlfriend's responses

**Requirements**:
- Shows girlfriend's text
- Integrates with character portrait
- Player input field at bottom
- "Send" button to submit messages

**Signal Connection**:
```gdscript
girlfriend.npc_reply.connect(_display_dialogue)
girlfriend.npc_thinking.connect(_show_thinking_indicator)
```

---

## 🔧 Key Files for UI Integration

### **Files to Connect To**
1. `Scenes/npc/girlfriend.gd` - Main girlfriend logic
   - Signals: `npc_reply`, `mood_updated`, `npc_thinking`
   
2. `autoload/game_state.gd` - Global state
   - Variable: `GameState.mood` (0-100)
   
3. `systems/mood_analyzer.gd` - ChatGPT analysis (background, no UI needed)

### **Files to Create/Modify**
1. **NEW**: `Scenes/ui/character_portrait.gd` - Animated portrait controller
2. **NEW**: `Scenes/ui/mood_meter.gd` - Score visualization
3. **MODIFY**: `Scenes/ui/dialogue_ui.gd` - Enhance with new design
4. **NEW**: `Scenes/ui/dialogue_ui.tscn` - New UI layout scene

---

## 📝 Reference Design Mapping

### **Stardew Valley Style → Our Game**

| Reference Element | Our Implementation |
|-------------------|-------------------|
| Character portrait (right) | Girlfriend portrait with 7 mood expressions |
| Dialogue text box (left) | Girlfriend's AI-generated responses |
| Player name display | "YOU:" prefix on player messages |
| Input box at bottom | Text input for player dialogue |
| Character expression changes | Triggered by `mood_updated` signal |
| Mood indicator | Score meter (0-100) with color coding |

---

## 🎮 Player Experience Flow

1. **Game Starts**: Girlfriend appears, Mood: Furious (50)
2. **Player Types Message**: "hello" → submits
3. **Processing**:
   - Check for winning sentence (no match)
   - ChatGPT analyzes: "neutral" interaction
   - Player2 generates response based on Furious tier
4. **Girlfriend Responds**: "I'm waiting for an explanation..."
5. **Mood Updates**: Score drops to 25, Mood: Crying
6. **UI Updates**: Portrait changes to crying expression, meter drops
7. **Repeat** until Score 100 or 0

---

## 🔌 API Configuration

### **Required API Keys** (Set via environment or Inspector)
1. **OpenAI API Key** - For mood analysis
   - Environment variable: `OPENAI_API_KEY`
   - Or set in `MoodAnalyzer` node Inspector

2. **Player2 API Key** - For girlfriend dialogue
   - Set in `addons/player2/api_config.tres`

---

## 🐛 Debug Output

### **Console Logging** (Helps with UI testing)
- `[Girlfriend] 💬 Player said: [text]`
- `[MoodAnalyzer] 🔍 ANALYZING GIRLFRIEND DIALOGUE`
- `[MoodAnalyzer] 📊 MOOD ANALYSIS RESULT:`
  - Mood Category
  - Relationship Score
  - Interaction Type
  - Positive/Antagonistic Streak
- `[Girlfriend] 🏆 WINNING SENTENCE DETECTED! Sequence: X/4`
- `[Girlfriend] ✅ Win condition triggered! Mood = 100`

---

## ✅ Integration Checklist for Teammate

- [ ] Create character portrait with 7 mood expression animations
- [ ] Create mood meter/bar that displays 0-100 score
- [ ] Connect `girlfriend.mood_updated` signal to update portrait + meter
- [ ] Create dialogue box UI matching reference design
- [ ] Connect `girlfriend.npc_reply` signal to display dialogue
- [ ] Add thinking indicator when `girlfriend.npc_thinking` emits
- [ ] Position portrait on right, dialogue box on left
- [ ] Add player input field and Send button at bottom
- [ ] Test mood transitions: type messages and watch mood change
- [ ] Test winning sentences: verify instant win at sequence 4/4

---

## 📞 Questions for Discussion

1. **Portrait Style**: 2D sprites or animated assets? (we have pixel art girlfriend)
2. **Mood Meter Design**: Horizontal bar, vertical bar, or custom shape?
3. **Transition Animations**: Fade, slide, or instant changes?
4. **Winning State**: Special animation when score reaches 100?
5. **Mobile Support**: Touch-friendly UI layout needed?

---

## 🎯 Success Criteria

Your UI is ready when:
✅ All 7 mood expressions display correctly
✅ Mood meter smoothly updates when score changes
✅ Dialogue appears in styled box with character portrait
✅ Player can type and send messages
✅ Winning sentences trigger visible celebration (score 100)
✅ Console logs confirm signal connections are working

---

**Branch**: `gameplay`
**Last Updated**: February 1, 2026
**Contact**: @TechnoMechno (GitHub)
