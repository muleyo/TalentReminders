local _, TR = ...
local UI, C = TR.UI, TR.UI.colors

local ROWS, ROW_H = 8, 34
local win, offset = nil, 0

local function Rows()
    local id = win.selectedID
    if not id then return {} end
    local rows = {}
    local _, class = UnitClass("player")
    local c = TR.db.custom[id]
    if c then
        for _, e in ipairs(c.entries) do
            if e.class == class then rows[#rows + 1] = { spell = e.spell, note = e.note } end
        end
    end
    return rows, id
end

function TR:RefreshConfig()
    if not win then return end
    for _, c in ipairs(win.checks) do c:SetChecked(TR.db[c.key]) end
    local rows, id = Rows()
    offset = math.min(offset, math.max(0, #rows - ROWS))
    for i = 1, ROWS do
        local r, d = win.rows[i], rows[i + offset]
        if d then
            local name, icon = TR.SpellInfo(d.spell)
            r.icon:SetTexture(icon or 134400)
            r.name:SetText(name or "Unknown spell")
            r.note:SetText(((d.note and d.note ~= "") and (d.note .. "  ") or "") .. "|cff55555a" .. d.spell .. "|r")
            r.spell, r.id = d.spell, id
            r.bg:SetAlpha((i + offset) % 2 == 0 and 0.5 or 0)
            r:Show()
        else
            r:Hide()
        end
    end
    if id then
        win.header:SetText(TR:InstanceName(id))
        win.count:SetText(#rows .. " talent" .. (#rows == 1 and "" or "s") .. " for your class")
    else
        win.header:SetText("No instance selected")
        win.count:SetText("Pick one from the dropdown above")
    end
    win.empty:SetShown(id and #rows == 0)
end

local function Build()
    win = UI.Window("TalentRemindersConfig", "Talent Reminders", 440, 520)
    win:SetPoint("CENTER")
    win:Hide()
    tinsert(UISpecialFrames, "TalentRemindersConfig")

    win.dropdown = UI.Dropdown(win, 408, "INSTANCE")
    win.dropdown:SetPoint("TOPLEFT", 16, -64)
    win.dropdown.placeholder = "Select an instance..."
    win.dropdown.onSelect = function(id) win.selectedID = id; offset = 0; TR:RefreshConfig() end
    win.dropdown:SetItems(TR:BuildInstanceItems())

    win.spell = UI.Dropdown(win, 408, "TALENT (CURRENT SPECIALIZATION)")
    win.spell:SetPoint("TOPLEFT", 16, -112)
    win.spell.placeholder = "Select a talent..."
    win.spell.getItems = function() return TR:BuildTalentItems() end
    win.spell.onSelect = function(id) win.spellID = id end

    win.note = UI.Edit(win, 290, "NOTE (OPTIONAL)")
    win.note:SetPoint("TOPLEFT", 16, -160)
    win.note:SetMaxLetters(80)

    local add = UI.Button(win, "+ Add talent", 110, 26, C.good)
    add:SetPoint("LEFT", win.note, "RIGHT", 8, 0)
    add:SetOnClick(function()
        local id = win.selectedID
        local spell = win.spellID
        if not id then TR.Print("Select an instance first.") return end
        if not spell then TR.Print("Select a talent first.") return end
        TR:AddEntry(id, spell, win.note:GetText())
        win.spellID = nil
        win.spell:SetSelected(nil)
        win.note:SetText("")
        TR:RefreshConfig()
    end)

    -- List panel
    local list = UI.Box(win, C.panel, C.border)
    list:SetPoint("TOPLEFT", 16, -196)
    list:SetPoint("TOPRIGHT", -16, -196)
    list:SetHeight(46 + ROWS * ROW_H)
    win.header = UI.Text(list, 13, C.text)
    win.header:SetPoint("TOPLEFT", 12, -9)
    win.count = UI.Text(list, 10, C.dim, "RIGHT")
    win.count:SetPoint("TOPRIGHT", -12, -11)
    local sep = list:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    sep:SetVertexColor(unpack(C.border))
    sep:SetPoint("TOPLEFT", 1, -32)
    sep:SetPoint("TOPRIGHT", -1, -32)
    sep:SetHeight(1)

    win.empty = UI.Text(list, 11, C.dim, "CENTER")
    win.empty:SetPoint("CENTER", 0, -12)
    win.empty:SetText("No talents yet - add one above.")

    win.rows = {}
    for i = 1, ROWS do
        local r = CreateFrame("Frame", nil, list)
        r:SetPoint("TOPLEFT", 1, -33 - (i - 1) * ROW_H)
        r:SetPoint("TOPRIGHT", -1, -33 - (i - 1) * ROW_H)
        r:SetHeight(ROW_H)
        r.bg = r:CreateTexture(nil, "BACKGROUND")
        r.bg:SetAllPoints()
        r.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        r.bg:SetVertexColor(0.07, 0.07, 0.09)
        r.iconBox = UI.Box(r, C.bg, C.border)
        r.iconBox:SetSize(26, 26)
        r.iconBox:SetPoint("LEFT", 10, 0)
        r.icon = r.iconBox:CreateTexture(nil, "ARTWORK")
        r.icon:SetPoint("TOPLEFT", 1, -1)
        r.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.name = UI.Text(r, 12, C.text)
        r.name:SetPoint("TOPLEFT", r.iconBox, "TOPRIGHT", 8, -1)
        r.note = UI.Text(r, 10, C.dim)
        r.note:SetPoint("BOTTOMLEFT", r.iconBox, "BOTTOMRIGHT", 8, 1)
        r.tag = UI.Text(r, 9, C.dim, "RIGHT")
        r.tag:SetPoint("RIGHT", -12, 0)
        r.del = UI.Button(r, "Remove", 62, 22, C.bad)
        r.del:SetPoint("RIGHT", -8, 0)
        r.del:SetOnClick(function()
            TR:RemoveEntry(r.id, r.spell)
            TR:RefreshConfig()
        end)
        win.rows[i] = r
    end
    win:EnableMouseWheel(true)
    win:SetScript("OnMouseWheel", function(_, d)
        offset = math.max(0, offset - d)
        TR:RefreshConfig()
    end)

    -- Options
    local function toggle(key) return function(self) TR.db[key] = self:GetChecked(); TR:CheckZone() end end
    local o1 = UI.Check(win, "Hide when all active", toggle("autoHide"))
    o1:SetPoint("BOTTOMLEFT", 16, 38)
    local o2 = UI.Check(win, "Chat alert", toggle("announce"))
    o2:SetPoint("LEFT", o1, "RIGHT", 150, 0)
    local o3 = UI.Check(win, "TTS alert", toggle("tts"))
    o3:SetPoint("LEFT", o2, "RIGHT", 100, 0)
    o1.key, o2.key, o3.key = "autoHide", "announce", "tts"
    win.checks = { o1, o2, o3 }

    local tip = UI.Text(win, 10, C.dim)
    tip:SetPoint("BOTTOMLEFT", 16, 14)
    tip:SetText("/tr id  prints the current instance ID   |   /tr show  previews the reminder")
end

function TR:OpenConfig()
    if not win then Build() end
    if win:IsShown() then win:Hide() return end
    local _, _, _, _, _, _, _, id = GetInstanceInfo()
    win.dropdown:SetItems(TR:BuildInstanceItems())
    if TR.missingCurrent and #TR.missingCurrent > 0 and not TR.warnedMissing then
        TR.warnedMissing = true
        TR.Print("Not found in the Encounter Journal yet: " .. table.concat(TR.missingCurrent, ", "))
    end
    if not win.selectedID and id and id > 0 then win.selectedID = id end
    win.dropdown:SetSelected(win.selectedID)
    win.spell:SetItems(TR:BuildTalentItems())
    win.spell:SetSelected(win.spellID)
    win:Show()
    self:RefreshConfig()
end
