# 🎯 Talent Reminders

Ever zoned into a dungeon and realized, three pulls in, that you're still running your open-world talents? Yeah, me too. This addon fixes that.

You tell it which talents you want for a given dungeon or raid, and when you zone in it pops up a small window showing which ones are active and which ones you still need to swap. Once everything's set, it gets out of your way.

## ✨ What it does

- 🗺️ **Per-instance talent lists.** Pick a dungeon or raid, pick the talents you want there, done.
- ✅ **Clear status at a glance.** Each talent shows up as an icon with a green border if it's active, or a red one if you need to swap.
- 💬 **Notes.** Add a short note to any talent ("single target only", "for the interrupt on boss 2") and it shows in the tooltip.
- 🙈 **Auto-hides** once all your talents are in place (you can turn this off).
- 🔔 **Optional alerts.** Get a chat message and/or a text-to-speech callout when talents are missing.
- 🧙 **Class-aware.** Your entries are saved per class, so your mage's list won't clutter your warrior's.
- 🖱️ **Draggable window.** Put the reminder wherever you like; it remembers.

## 📦 Installation

1. Download or clone this repo.
2. Drop the `TalentReminders` folder into:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
3. Restart the game (or `/reload`) and make sure the addon is enabled at the character select screen.

Built for retail, interface versions `120100` and `120105`.

## 🚀 Getting started

1. Type `/tr` to open the settings window.
2. Choose an instance from the dropdown (it's populated from the Encounter Journal).
3. Choose a talent from your current specialization.
4. Optionally add a note, then hit **+ Add talent**.
5. Repeat for as many talents as you want, then zone in and see it work.

Want to check how it looks without actually going anywhere? Use `/tr show`.

## ⌨️ Slash commands

| Command | What it does |
| --- | --- |
| `/tr` | Open or close the settings window |
| `/tr id` | Print the current instance's name and ID |
| `/tr add <instanceID> <spellID or spell link> [note]` | Add a talent to an instance |
| `/tr remove <instanceID> <spellID or spell link>` | Remove a talent from an instance |
| `/tr show [instanceID]` | Preview the reminder window |
| `/tr help` | List the commands |

`/talentreminders` works too if you're feeling formal.

## ⚙️ Options

All of these live at the bottom of the settings window:

- **Hide when all active**: closes the reminder when nothing needs swapping.
- **Chat alert**: also prints a message in chat when talents are missing.
- **TTS alert**: says "Talents missing" out loud via the game's text-to-speech.

By default the reminder shows for dungeons, raids and scenarios.

## 🗂️ Project layout

```
TalentReminders.toc   addon manifest
GUI.lua               small custom UI toolkit (windows, buttons, dropdowns)
Instances.lua         builds the instance list from the Encounter Journal
Talents.lua           lists talents for your current spec
Core.lua              zone detection, reminder window, slash commands
Config.lua            the settings window
```

Your lists are stored in the `TalentRemindersDB` saved variable.

## 🐛 Issues & ideas

Found a bug or want a feature? Open an issue, or send a PR. Small project, so it's all very informal.

## 📄 License

GPL-3.0. See [LICENSE](LICENSE) for the full text.
