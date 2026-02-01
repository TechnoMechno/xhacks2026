# Quick Start: ChatGPT Mood Analysis

## 🚀 Getting Started in 3 Steps

### Step 1: Get Your API Key (2 minutes)
1. Go to https://platform.openai.com/api-keys
2. Sign in (or create a free account)
3. Click "Create new secret key"
4. **Copy the key** (starts with `sk-`)

### Step 2: Set Your API Key (30 seconds)

**Windows (PowerShell):**
```powershell
$env:OPENAI_API_KEY="sk-your-api-key-here"
```

**Windows (CMD):**
```cmd
setx OPENAI_API_KEY "sk-your-api-key-here"
```

**Linux/Mac:**
```bash
export OPENAI_API_KEY="sk-your-api-key-here"
```

### Step 3: Run the Game! ✅

That's it! The mood analysis is now integrated and will work automatically.

---

## 💡 What You'll See

When playing the game and talking to your girlfriend:
- **Mood Display**: Top of dialogue box shows current mood
- **Color-Coded**: Green (happy), Red (angry), Blue (sad), etc.
- **Emoji Indicator**: Quick visual feedback (😊, 😠, 😢)
- **Score**: -100 to +100 relationship score

### Example Display:
```
😊 Mood: Happy (Score: 75)
```

---

## 🎮 How It Works

1. You send a message to girlfriend
2. She responds with AI-generated dialogue
3. ChatGPT analyzes her response
4. Mood updates in ~1-2 seconds
5. Display shows mood category & score

---

## 💰 Cost

- **Model Used**: GPT-3.5-turbo (cheapest)
- **Cost**: ~$0.0005 per message (~$0.50 for 1000 messages)
- **Very affordable** for gameplay testing!

---

## ❓ Troubleshooting

### Mood Not Showing?
- Check console for errors (F12 in Godot)
- Make sure you set the API key
- Restart Godot after setting environment variable

### "No API key set!" Error
- You need to set the OPENAI_API_KEY environment variable
- Then restart Godot

### API Error (401 Unauthorized)
- Your API key is invalid
- Generate a new key from OpenAI dashboard

### No Credits Error
- Add credits to your OpenAI account
- Go to: https://platform.openai.com/account/billing

---

## 📝 Advanced: Set API Key in Scene (Alternative)

If environment variables don't work:

1. Open `Scenes/Girlfriend.tscn` in Godot
2. Select the `MoodAnalyzer` node
3. In the Inspector panel, find "Api Key"
4. Paste your OpenAI API key there
5. Save the scene

**Note**: Don't commit your API key to git!

---

## 🎯 What's Integrated

✅ Mood analyzer system created
✅ Girlfriend script updated
✅ Dialogue UI enhanced with mood display
✅ Scene files updated with new nodes
✅ Ready to use out of the box!

---

## 📚 More Info

For detailed documentation, see:
- `CHATGPT_MOOD_SETUP.md` - Complete setup guide
- `MOOD_ANALYSIS_IMPLEMENTATION.md` - Technical details
- `.env.example` - Configuration template

---

## 🎉 You're Ready!

Just set your API key and start playing! The mood system will automatically analyze your girlfriend's responses and show her emotional state in real-time.

Have fun! 🎮
