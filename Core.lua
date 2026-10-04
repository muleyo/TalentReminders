local ADDON, TR = ...
local PREFIX = "|cff33ccffTalentReminders:|r "
local ICON = 36
local PER_ROW, ROW_STEP = 6, 72

local defaults = {
    custom = {}, -- [instanceID] = { name = "", entries = { {spell=, class=, note=} } }
    autoHide = true, -- hide the frame once every talent is active
    announce = false, -- also print to chat
    tts = false, -- speak the missing talents
    types = {
        party = true,
        raid = true,
        scenario = true
    }
}

local function Print(msg)
    print(PREFIX .. msg)
end
TR.Print = Print

local function SpellInfo(id)
    if not id then
        return
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(id)
        if info then
            return info.name, info.iconID
        end
        return
    end
    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(id)
        return name, icon
    end
end
TR.SpellInfo = SpellInfo

local function IsActive(spell)
    return IsPlayerSpell(spell) or (IsSpellKnown and IsSpellKnown(spell)) or false
end

-- Merge DB defaults
local function InitDB()
    TalentRemindersDB = TalentRemindersDB or {}
    for k, v in pairs(defaults) do
        if TalentRemindersDB[k] == nil then
            TalentRemindersDB[k] = type(v) == "table" and CopyTable(v) or v
        end
    end
    TR.db = TalentRemindersDB
end

function TR:GetEntries(instanceID)
    local list, seen = {}, {}
    local _, class = UnitClass("player")
    local function add(e, custom)
        if e.class == class and not seen[e.spell] then
            seen[e.spell] = true
            list[#list + 1] = {
                spell = e.spell,
                note = e.note,
                custom = custom
            }
        end
    end
    local c = self.db.custom[instanceID]
    if c then
        for _, e in ipairs(c.entries) do
            add(e, true)
        end
    end
    return list
end

function TR:InstanceName(id)
    local c = self.db.custom[id]
    if c and c.name and c.name ~= "" then
        return c.name
    end
    if self.instanceNames[id] then
        return self.instanceNames[id]
    end
    return "Instance " .. id
end

function TR:Speak(text)
    if not (C_VoiceChat and C_VoiceChat.SpeakText) then
        return
    end
    local voice = C_TTSSettings and C_TTSSettings.GetVoiceOptionID and
                      C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType and Enum.TtsVoiceType.Standard or 0) or 0
    local rate = C_TTSSettings and C_TTSSettings.GetSpeechRate and C_TTSSettings.GetSpeechRate() or 0
    local vol = C_TTSSettings and C_TTSSettings.GetSpeechVolume and C_TTSSettings.GetSpeechVolume() or 100
    local dest = Enum and (Enum.VoiceTtsDestination or Enum.TtsDestination)
    local ok, err
    if dest and dest.LocalPlayback ~= nil then
        ok, err = pcall(C_VoiceChat.SpeakText, voice, text, dest.LocalPlayback, rate, vol)
    else
        ok, err = pcall(C_VoiceChat.SpeakText, voice, text, rate, vol)
    end
    if not ok then
        Print("TTS failed: " .. tostring(err))
    end
end

local UI, C = TR.UI, TR.UI.colors
local frame = UI.Window("TalentRemindersFrame", "Talent Reminders", 220, 120)
frame:SetPoint("TOP", UIParent, "TOP", 0, -180)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    TR.db.pos = {p, rp, x, y}
end)
frame:Hide()

frame.sub = UI.Text(frame, 11, C.dim)
frame.sub:SetPoint("TOP", 0, -40)
frame.sub:SetJustifyH("CENTER")

frame.buttons = {}
local function GetButton(i)
    local b = frame.buttons[i]
    if b then
        return b
    end
    b = UI.Box(frame, C.panel, C.border)
    b:SetSize(ICON + 2, ICON + 2)
    b:EnableMouse(true)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", 1, -1)
    b.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.mark = UI.Text(b, 11, C.good, "CENTER")
    b.mark:SetPoint("BOTTOMRIGHT", -2, 2)
    b.label = UI.Text(b, 10, C.text, "CENTER")
    b.label:SetPoint("TOP", b, "BOTTOM", 0, -4)
    b.label:SetWidth(ICON + 22)
    b.label:SetMaxLines(2)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.spell)
        if self.note and self.note ~= "" then
            GameTooltip:AddLine(self.note, 1, 0.82, 0, true)
        end
        GameTooltip:AddLine(self.active and "|cff4dd973Talent active|r" or "|cffff5959Talent NOT active - swap!|r")
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    frame.buttons[i] = b
    return b
end

local currentID

function TR:Refresh(forceShow)
    if not currentID then
        frame:Hide()
        return
    end
    local list = self:GetEntries(currentID)
    if #list == 0 then
        frame:Hide()
        return
    end

    local missing, missingNames = 0, {}
    local cell = ICON + 24
    local rows = math.ceil(#list / PER_ROW)
    for i, e in ipairs(list) do
        local b = GetButton(i)
        local _, icon = SpellInfo(e.spell)
        b.spell, b.note = e.spell, e.note
        b.active = IsActive(e.spell)
        b.tex:SetTexture(icon or 134400)
        b:SetBackdropBorderColor(unpack(b.active and C.good or C.bad))
        b.mark:SetText(b.active and "OK" or "!")
        b.mark:SetTextColor(unpack(b.active and C.good or C.bad))
        b.label:SetText(SpellInfo(e.spell) or e.spell)
        b:ClearAllPoints()
        local row, col = math.floor((i - 1) / PER_ROW), (i - 1) % PER_ROW
        local inRow = math.min(PER_ROW, #list - row * PER_ROW)
        local x = (col - (inRow - 1) / 2) * cell
        b:SetPoint("TOP", frame, "TOP", x, -64 - row * ROW_STEP)
        b:Show()
        if not b.active then
            missing = missing + 1
            missingNames[#missingNames + 1] = SpellInfo(e.spell) or tostring(e.spell)
        end
    end
    for i = #list + 1, #frame.buttons do
        frame.buttons[i]:Hide()
    end

    if missing == 0 and self.db.autoHide and not forceShow then
        frame:Hide()
        return
    end

    frame:SetSize(math.max(220, 28 + math.min(#list, PER_ROW) * cell), 76 + rows * ROW_STEP)
    frame.title:SetText(self:InstanceName(currentID))
    frame.sub:SetText(missing > 0 and ("|cffff5959" .. missing .. " talent(s) to swap|r") or "|cff4dd973All talents active|r")
    if not frame:IsShown() then
        frame:Show()
        if self.db.announce and missing > 0 then
            Print(("%s: %d talent(s) to swap."):format(self:InstanceName(currentID), missing))
        end
        if self.db.tts and missing > 0 then
            self:Speak("Talents missing")
        end
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("TRAIT_CONFIG_UPDATED")
ev:RegisterEvent("PLAYER_TALENT_UPDATE")
ev:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")

local pending
local function CheckZone()
    local iname, itype, _, _, _, _, _, id = GetInstanceInfo()
    if id and TR.db.types[itype] then
        TR.instanceNames[id] = iname
        if id ~= currentID then
            currentID = id;
            TR:Refresh()
        else
            TR:Refresh()
        end
    else
        currentID = nil
        frame:Hide()
    end
end
TR.CheckZone = CheckZone

ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then
            return
        end
        InitDB()
        if TR.db.pos then
            frame:ClearAllPoints()
            frame:SetPoint(TR.db.pos[1], UIParent, TR.db.pos[2], TR.db.pos[3], TR.db.pos[4])
        end
        if TR.InitConfig then
            TR:InitConfig()
        end
    elseif not TR.db then
        return
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        -- leaving: hide right away; entering: wait, talent data can lag behind loading screens
        local _, itype = GetInstanceInfo()
        if TR.db.types[itype] then
            C_Timer.After(1.5, CheckZone)
        else
            CheckZone()
        end
    else
        if pending then
            return
        end
        pending = true
        C_Timer.After(0.3, function()
            pending = nil;
            if currentID then
                TR:Refresh()
            end
        end)
    end
end)

function TR:Show(id)
    currentID = id or currentID;
    self:Refresh(true)
end

function TR:AddEntry(instanceID, spell, note, name)
    local _, class = UnitClass("player")
    local c = self.db.custom[instanceID]
    if not c then
        c = {
            name = name or "",
            entries = {}
        };
        self.db.custom[instanceID] = c
    end
    if name and name ~= "" then
        c.name = name
    end
    for _, e in ipairs(c.entries) do
        if e.spell == spell and e.class == class then
            e.note = note or e.note
            return
        end
    end
    c.entries[#c.entries + 1] = {
        spell = spell,
        class = class,
        note = note or ""
    }
    if instanceID == currentID then
        self:Refresh()
    end
end

function TR:RemoveEntry(instanceID, spell)
    local c = self.db.custom[instanceID]
    if not c then
        return
    end
    local _, class = UnitClass("player")
    for i = #c.entries, 1, -1 do
        local e = c.entries[i]
        if e.spell == spell and e.class == class then
            table.remove(c.entries, i)
        end
    end
    if #c.entries == 0 then
        self.db.custom[instanceID] = nil
    end
    if instanceID == currentID then
        self:Refresh()
    end
end

function TR.ParseSpell(text)
    if not text then
        return
    end
    local id = tonumber(text) or tonumber(text:match("spell:(%d+)")) or tonumber(text:match("talent:(%d+)"))
    return id
end

SLASH_TALENTREMINDERS1 = "/tr"
SLASH_TALENTREMINDERS2 = "/talentreminders"
SlashCmdList.TALENTREMINDERS = function(msg)
    local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    if cmd == "id" then
        local name, _, _, _, _, _, _, id = GetInstanceInfo()
        Print(("Current: %s - instanceID %s"):format(name or "?", tostring(id)))
    elseif cmd == "add" then
        local i, s, note = rest:match("^(%d+)%s+(%S+)%s*(.*)$")
        local spell = TR.ParseSpell(s)
        if not (i and spell) then
            Print("Usage: /tr add <instanceID> <spellID|spell link> [note]")
            return
        end
        TR:AddEntry(tonumber(i), spell, note)
        Print(("Added %s to instance %s."):format(SpellInfo(spell) or spell, i))
    elseif cmd == "remove" or cmd == "del" then
        local i, s = rest:match("^(%d+)%s+(%S+)")
        local spell = TR.ParseSpell(s)
        if not (i and spell) then
            Print("Usage: /tr remove <instanceID> <spellID|spell link>")
            return
        end
        TR:RemoveEntry(tonumber(i), spell)
        Print("Removed.")
    elseif cmd == "show" then
        TR:Show(tonumber(rest))
    elseif cmd == "help" then
        Print("/tr - options | /tr id | /tr add <instanceID> <spell> [note] | /tr remove <instanceID> <spell> | /tr show [instanceID]")
    else
        if TR.OpenConfig then
            TR:OpenConfig()
        end
    end
end
