# ChatGPT Mood Analysis Integration

This project now includes a ChatGPT-powered mood analyzer that analyzes the girlfriend's dialogue in real-time to determine her emotional state.

## Features

- **Real-time Mood Detection**: Analyzes each girlfriend response using ChatGPT
- **7 Mood Categories**: Happy, Soft Smile, Neutral, Sad, Crying, Angry, Furious
- **Relationship Score**: -100 to +100 scale showing relationship health
- **Visual Feedback**: Color-coded mood display with emojis in the dialogue UI

## Setup Instructions

### 1. Get Your OpenAI API Key

1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the API key (starts with `sk-`)

### 2. Configure the API Key

You have two options:

#### Option A: Set Environment Variable (Recommended)
Set the `OPENAI_API_KEY` environment variable before running Godot:

**Windows:**
```bash
setx OPENAI_API_KEY "sk-your-api-key-here"
```

**Linux/Mac:**
```bash
export OPENAI_API_KEY="sk-your-api-key-here"
```

#### Option B: Set in Godot Scene
1. Open `Scenes/Girlfriend.tscn` in Godot
2. Select the `MoodAnalyzer` node
3. In the Inspector, set the `Api Key` property to your OpenAI API key

### 3. Add MoodAnalyzer Node to Girlfriend Scene

1. Open `Scenes/Girlfriend.tscn` in Godot
2. Select the `Girlfriend` (CharacterBody2D) node
3. Right-click and select "Add Child Node"
4. Search for "Node" and add it
5. Rename it to `MoodAnalyzer`
6. In the Inspector, set its script to `res://systems/mood_analyzer.gd`
7. (Optional) Configure the `Model` property (default: `gpt-3.5-turbo`)

### 4. Add Mood Label to Dialogue UI

1. Open `Scenes/ui/dialogue_ui.tscn` (or your dialogue UI scene)
2. Under the `Panel/VBox` node, add a new `Label` node
3. Rename it to `MoodLabel`
4. Position it where you want the mood display to appear (e.g., above the chat history)
5. Configure its appearance:
   - Font size: 16-20
   - Align: Center
   - Size Flags: Expand Fill

## How It Works

1. **Player sends message** → Girlfriend generates response
2. **Girlfriend responds** → Response is sent to ChatGPT for mood analysis
3. **ChatGPT analyzes** → Returns mood category and relationship score
4. **UI updates** → Mood label updates with color-coded display

## Mood Categories & Colors

- 😊 **Happy** (Bright Green): Joyful, excited, enthusiastic
- 🙂 **Soft Smile** (Light Green): Content, gentle, warm
- 😐 **Neutral** (Gray): Calm, matter-of-fact
- 😔 **Sad** (Light Blue): Disappointed, hurt
- 😢 **Crying** (Blue): Deeply upset, heartbroken
- 😠 **Angry** (Orange): Irritated, frustrated
- 😡 **Furious** (Red): Extremely angry, enraged

## Score Interpretation

- **+80 to +100**: Very happy, loving
- **+50 to +79**: Happy, pleased
- **+20 to +49**: Content, positive
- **0 to +19**: Slightly positive
- **-1 to -19**: Slightly negative
- **-20 to -49**: Upset, angry
- **-50 to -79**: Very angry, hurt
- **-80 to -100**: Furious, devastated

## API Costs

- Uses OpenAI's GPT-3.5-turbo model (cheapest option)
- Approximately $0.0005 per analysis (very cheap)
- ~2000 analyses per $1

## Troubleshooting

### No Mood Display
- Check that `MoodAnalyzer` node is added to Girlfriend scene
- Check that `MoodLabel` exists in your dialogue UI
- Look for errors in Godot's Output console

### API Errors
- Verify your API key is correct
- Check you have credits in your OpenAI account
- Check your internet connection
- Look for error messages in the console

### Slow Response
- Mood analysis happens in the background
- Typical response time: 1-2 seconds
- Does not block gameplay or dialogue

## Advanced Configuration

### Change AI Model
In the `MoodAnalyzer` node inspector:
- `gpt-3.5-turbo`: Fastest, cheapest (default)
- `gpt-4`: More accurate, slower, more expensive
- `gpt-4-turbo`: Good balance

### Disable Mood Analysis
If you want to disable the feature temporarily:
1. Select the `MoodAnalyzer` node in Girlfriend scene
2. Uncheck "Active" or delete the node

## Files Added/Modified

### New Files
- `systems/mood_analyzer.gd` - ChatGPT mood analysis system

### Modified Files
- `Scenes/npc/girlfriend.gd` - Added mood analysis integration
- `Scenes/ui/dialogue_ui.gd` - Added mood display functionality

## Future Enhancements

Potential improvements:
- Visual mood indicators (facial expressions, animations)
- Mood history tracking
- Mood-based music/sound effects
- Achievement system based on maintaining positive moods
- Mood trend graphs
