# ChatGPT Mood Analysis System - Complete Guide

## Overview

This system integrates OpenAI's ChatGPT to analyze your AI girlfriend's emotional state in real-time during gameplay. It provides visual feedback with mood categories, relationship scores, and color-coded indicators.

---

## ✨ Features

- **7 Mood Categories**: Happy, Soft Smile, Neutral, Sad, Crying, Angry, Furious
- **Relationship Scoring**: -100 to +100 scale
- **Real-time Analysis**: Analyzes each response as it happens
- **Visual Feedback**: Color-coded text and emojis
- **Non-blocking**: Async API calls don't freeze gameplay
- **Cost-effective**: Uses GPT-3.5-turbo (~$0.0005 per analysis)

---

## 📋 Prerequisites

1. **OpenAI Account**: https://platform.openai.com
2. **API Key**: Get from https://platform.openai.com/api-keys
3. **Credits**: Add payment method and credits ($5 minimum)
4. **Internet Connection**: Required for API calls

---

## 🚀 Installation & Setup

### Method 1: Environment Variable (Recommended)

**Windows PowerShell:**
```powershell
# Set for current session
$env:OPENAI_API_KEY="sk-your-api-key-here"

# Or set permanently
[System.Environment]::SetEnvironmentVariable('OPENAI_API_KEY', 'sk-your-api-key-here', 'User')
```

**Windows CMD:**
```cmd
setx OPENAI_API_KEY "sk-your-api-key-here"
```

**Linux/Mac Bash:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export OPENAI_API_KEY="sk-your-api-key-here"

# Then reload
source ~/.bashrc
```

**Important**: Restart Godot after setting environment variables!

### Method 2: Direct in Scene

1. Open `Scenes/Girlfriend.tscn` in Godot Editor
2. Select the `MoodAnalyzer` node
3. In Inspector, set `Api Key` property
4. Save the scene

**⚠️ Warning**: Don't commit API keys to version control!

---

## 🎮 Usage

### Automatic Operation

Once configured, the system works automatically:

1. Player talks to girlfriend
2. Girlfriend responds
3. Mood is analyzed by ChatGPT
4. UI updates with mood & score

No additional code or interaction needed!

### Reading the Display

**Format**: `[Emoji] Mood: [Category] (Score: [Number])`

**Example**: `😊 Mood: Happy (Score: 75)`

---

## 🎨 Mood Categories

| Mood | Emoji | Color | Score Range | Description |
|------|-------|-------|-------------|-------------|
| Happy | 😊 | Bright Green | +50 to +100 | Joyful, excited, enthusiastic |
| Soft Smile | 🙂 | Light Green | +20 to +60 | Content, gentle, warm |
| Neutral | 😐 | Gray | -10 to +20 | Calm, matter-of-fact |
| Sad | 😔 | Light Blue | -20 to -50 | Disappointed, hurt |
| Crying | 😢 | Blue | -50 to -80 | Deeply upset, heartbroken |
| Angry | 😠 | Orange | -20 to -50 | Irritated, frustrated |
| Furious | 😡 | Red | -50 to -100 | Extremely angry, enraged |

---

## 📊 Score Interpretation

### Positive Relationship (+1 to +100)
- **+80 to +100**: Very happy, loving relationship
- **+50 to +79**: Happy, pleased with you
- **+20 to +49**: Content, generally positive
- **0 to +19**: Slightly positive, neutral-positive

### Negative Relationship (-1 to -100)
- **-1 to -19**: Slightly negative, disappointed
- **-20 to -49**: Upset, angry with you
- **-50 to -79**: Very angry, deeply hurt
- **-80 to -100**: Furious, relationship at risk

---

## 🔧 Configuration

### Change AI Model

In `MoodAnalyzer` node Inspector:

| Model | Speed | Cost | Accuracy |
|-------|-------|------|----------|
| gpt-3.5-turbo | Fast | $ | Good (default) |
| gpt-4 | Slow | $$$ | Excellent |
| gpt-4-turbo | Medium | $$ | Very Good |

### Adjust Temperature

In `systems/mood_analyzer.gd`, line 96:
```gdscript
"temperature": 0.3,  # Lower = more consistent, Higher = more varied
```

### Modify Max Tokens

In `systems/mood_analyzer.gd`, line 97:
```gdscript
"max_tokens": 100,  # Increase if responses are cut off
```

---

## 💰 Cost & Performance

### Estimated Costs (GPT-3.5-turbo)
- Per analysis: ~$0.0005
- Per 100 messages: ~$0.05
- Per 1000 messages: ~$0.50
- Per hour of gameplay: ~$0.10-$0.30

### Performance Metrics
- API Response Time: 0.5-2 seconds
- Token Usage: ~100-150 tokens per request
- Rate Limit: 3500 requests/minute (plenty for gameplay)

---

## 🛠️ Technical Architecture

### Components

1. **MoodAnalyzer** (`systems/mood_analyzer.gd`)
   - Handles ChatGPT API communication
   - Parses mood analysis responses
   - Emits signals with mood data

2. **Girlfriend** (`Scenes/npc/girlfriend.gd`)
   - Integrates mood analyzer
   - Triggers analysis on responses
   - Broadcasts mood updates

3. **DialogueUI** (`Scenes/ui/dialogue_ui.gd`)
   - Displays mood information
   - Updates colors and emojis
   - Handles visual feedback

### Data Flow

```
Player Message
    ↓
Girlfriend AI Response
    ↓
MoodAnalyzer.analyze_dialogue()
    ↓
ChatGPT API Call
    ↓
Parse JSON Response
    ↓
Emit mood_analyzed signal
    ↓
Girlfriend.mood_updated signal
    ↓
DialogueUI updates display
```

---

## 🐛 Troubleshooting

### "No API key set!" Error
**Cause**: OPENAI_API_KEY not configured
**Solution**: 
1. Set environment variable
2. Restart Godot
3. Or set directly in MoodAnalyzer node

### API Error 401 (Unauthorized)
**Cause**: Invalid API key
**Solution**: 
1. Verify key is correct (starts with "sk-")
2. Generate new key at OpenAI dashboard
3. Check for extra spaces in key

### API Error 429 (Rate Limit)
**Cause**: Too many requests
**Solution**: 
1. Wait 1 minute
2. Reduce request frequency
3. Upgrade OpenAI plan

### API Error 403 (Forbidden)
**Cause**: No credits or billing not set up
**Solution**: 
1. Go to https://platform.openai.com/account/billing
2. Add payment method
3. Add credits ($5 minimum)

### Mood Label Not Visible
**Cause**: Node not found or scene not saved
**Solution**: 
1. Open `Scenes/ui/dialogue_ui.tscn`
2. Verify `MoodLabel` node exists under `Panel/VBox`
3. Re-save scene

### Analysis Not Working
**Cause**: Multiple possible issues
**Debug Steps**:
1. Check Godot Output console (F12)
2. Look for "[MoodAnalyzer]" log messages
3. Verify internet connection
4. Test API key with curl:
```bash
curl https://api.openai.com/v1/models -H "Authorization: Bearer YOUR_API_KEY"
```

### Slow Response
**Cause**: Network latency or OpenAI load
**Solutions**:
- Normal: 0.5-2 seconds is expected
- If slower: Check internet connection
- Consider using gpt-3.5-turbo-16k for faster responses

---

## 🔒 Security Best Practices

### Protecting Your API Key

1. **Never commit to Git**:
```bash
# Add to .gitignore
.env
*.env
```

2. **Use environment variables**:
- Keeps keys out of code
- Easy to rotate
- Safe for deployment

3. **Rotate keys regularly**:
- Generate new key monthly
- Revoke old keys
- Monitor usage

4. **Set usage limits**:
- OpenAI Dashboard → Usage limits
- Set monthly maximum
- Get email alerts

---

## 📁 File Structure

```
xhacks2026/
├── systems/
│   └── mood_analyzer.gd          # Core mood analysis system
├── Scenes/
│   ├── npc/
│   │   └── girlfriend.gd         # Integrated mood analysis
│   ├── ui/
│   │   ├── dialogue_ui.gd        # Mood display logic
│   │   └── dialogue_ui.tscn      # UI with MoodLabel
│   └── Girlfriend.tscn           # Scene with MoodAnalyzer node
├── QUICKSTART_MOOD.md            # Quick start guide
├── CHATGPT_MOOD_SETUP.md         # Detailed setup guide
├── MOOD_ANALYSIS_IMPLEMENTATION.md  # Technical documentation
└── .env.example                  # Configuration template
```

---

## 🔮 Future Enhancements

### Planned Features
- [ ] Mood history tracking
- [ ] Emotion transition animations
- [ ] Mood-based facial expressions
- [ ] Analytics dashboard
- [ ] Achievement system
- [ ] Mood trend graphs

### Possible Improvements
- [ ] Local AI model option (no API needed)
- [ ] Response caching
- [ ] Batch analysis
- [ ] Sentiment pattern recognition
- [ ] Personalized tips

---

## 📚 Additional Resources

### Documentation
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [GPT-3.5 Guide](https://platform.openai.com/docs/guides/gpt)
- [Rate Limits](https://platform.openai.com/docs/guides/rate-limits)

### Support
- OpenAI Help: https://help.openai.com
- API Status: https://status.openai.com
- Community Forum: https://community.openai.com

---

## ✅ Verification Checklist

Before playing, verify:
- [ ] OpenAI API key obtained
- [ ] Environment variable set OR scene property configured
- [ ] Godot restarted after setting env var
- [ ] MoodAnalyzer node exists in Girlfriend.tscn
- [ ] MoodLabel exists in dialogue_ui.tscn
- [ ] Internet connection active
- [ ] OpenAI account has credits
- [ ] No errors in Godot console

---

## 🎉 You're All Set!

The ChatGPT mood analysis system is now fully integrated and ready to use. Just start the game, talk to your girlfriend, and watch her mood change in real-time!

**Pro Tip**: Try different conversation styles and see how the mood responds. Apologize sincerely, be empathetic, or make her laugh!

Enjoy your enhanced AI girlfriend experience! 💕
