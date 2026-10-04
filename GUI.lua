local _, TR = ...

local UI = {}
TR.UI = UI

local WHITE = "Interface\\Buttons\\WHITE8X8"
UI.colors = {
    bg = {0.07, 0.07, 0.09, 0.96},
    panel = {0.11, 0.11, 0.14, 1},
    border = {0.22, 0.22, 0.27, 1},
    accent = {0.25, 0.62, 1.00, 1},
    good = {0.30, 0.85, 0.45, 1},
    bad = {1.00, 0.35, 0.35, 1},
    text = {0.92, 0.92, 0.95, 1},
    dim = {0.55, 0.55, 0.62, 1}
}
local C = UI.colors
local FONT = "Fonts\\FRIZQT__.TTF"

function UI.Box(parent, bg, border)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1
    })
    f:SetBackdropColor(unpack(bg or C.panel))
    f:SetBackdropBorderColor(unpack(border or C.border))
    return f
end

function UI.Text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size or 12, "")
    fs:SetTextColor(unpack(color or C.text))
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

function UI.Button(parent, text, w, h, color)
    local b = UI.Box(parent, C.panel, C.border)
    b:SetSize(w, h or 24)
    b:EnableMouse(true)
    b.label = UI.Text(b, 12, C.text, "CENTER")
    b.label:SetPoint("CENTER")
    b.label:SetText(text)
    local base = color or C.accent
    b:SetScript("OnEnter", function(s)
        s:SetBackdropColor(base[1] * 0.35, base[2] * 0.35, base[3] * 0.35, 1)
        s:SetBackdropBorderColor(unpack(base))
    end)
    b:SetScript("OnLeave", function(s)
        s:SetBackdropColor(unpack(C.panel))
        s:SetBackdropBorderColor(unpack(C.border))
    end)
    b:SetScript("OnMouseDown", function(s)
        s.label:SetPoint("CENTER", 0, -1)
    end)
    b:SetScript("OnMouseUp", function(s)
        s.label:SetPoint("CENTER")
        if s:IsMouseOver() and s.onClick then
            s.onClick(s)
        end
    end)
    function b:SetOnClick(fn)
        self.onClick = fn
    end
    return b
end

function UI.Edit(parent, w, label, numeric)
    local e = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    e:SetSize(w, 26)
    e:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1
    })
    e:SetBackdropColor(0.04, 0.04, 0.06, 1)
    e:SetBackdropBorderColor(unpack(C.border))
    e:SetFont(FONT, 12, "")
    e:SetTextColor(unpack(C.text))
    e:SetTextInsets(8, 8, 0, 0)
    e:SetAutoFocus(false)
    e:SetNumeric(numeric or false)
    e:SetScript("OnEscapePressed", e.ClearFocus)
    e:SetScript("OnEnterPressed", e.ClearFocus)
    e:SetScript("OnEditFocusGained", function(s)
        s:SetBackdropBorderColor(unpack(C.accent))
    end)
    e:SetScript("OnEditFocusLost", function(s)
        s:SetBackdropBorderColor(unpack(C.border))
    end)
    e.caption = UI.Text(e, 10, C.dim)
    e.caption:SetPoint("BOTTOMLEFT", e, "TOPLEFT", 1, 4)
    e.caption:SetText(label or "")
    return e
end

function UI.Check(parent, text, onToggle)
    local c = CreateFrame("Button", nil, parent)
    c:SetSize(16, 16)
    c.box = UI.Box(c, {0.04, 0.04, 0.06, 1}, C.border)
    c.box:SetAllPoints()
    c.fill = c.box:CreateTexture(nil, "ARTWORK")
    c.fill:SetTexture(WHITE)
    c.fill:SetPoint("TOPLEFT", 3, -3)
    c.fill:SetPoint("BOTTOMRIGHT", -3, 3)
    c.fill:SetVertexColor(unpack(C.accent))
    c.label = UI.Text(c, 11, C.text)
    c.label:SetPoint("LEFT", c, "RIGHT", 6, 0)
    c.label:SetText(text)
    function c:SetChecked(v)
        self.checked = v and true or false;
        self.fill:SetShown(self.checked)
    end
    function c:GetChecked()
        return self.checked
    end
    c:SetScript("OnClick", function(s)
        s:SetChecked(not s.checked);
        if onToggle then
            onToggle(s)
        end
    end)
    c:SetScript("OnEnter", function(s)
        s.box:SetBackdropBorderColor(unpack(C.accent))
    end)
    c:SetScript("OnLeave", function(s)
        s.box:SetBackdropBorderColor(unpack(C.border))
    end)
    c:SetChecked(false)
    return c
end

function UI.Window(name, title, w, h)
    local f = UI.Box(UIParent, C.bg, C.border)
    f:SetSize(w, h)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local bar = f:CreateTexture(nil, "ARTWORK")
    bar:SetTexture(WHITE)
    bar:SetVertexColor(unpack(C.panel))
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(30)
    local line = f:CreateTexture(nil, "OVERLAY")
    line:SetTexture(WHITE)
    line:SetVertexColor(unpack(C.accent))
    line:SetPoint("TOPLEFT", bar, "BOTTOMLEFT")
    line:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT")
    line:SetHeight(1)

    f.title = UI.Text(f, 13, C.text)
    f.title:SetPoint("LEFT", bar, "LEFT", 12, 0)
    f.title:SetText(title)

    f.close = UI.Button(f, "x", 22, 22, C.bad)
    f.close:SetPoint("TOPRIGHT", -5, -5)
    f.close:SetOnClick(function()
        f:Hide()
    end)
    if name then
        _G[name] = f
    end
    return f
end

local DD_ROWS, DD_H, DD_TOP = 14, 22, 32
function UI.Dropdown(parent, w, caption)
    local d = UI.Button(parent, "", w, 26)
    d:SetBackdropColor(0.04, 0.04, 0.06, 1)
    d:SetScript("OnLeave", function(s)
        s:SetBackdropColor(0.04, 0.04, 0.06, 1);
        s:SetBackdropBorderColor(unpack(C.border))
    end)
    d:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(unpack(C.accent))
    end)
    d.icon = d:CreateTexture(nil, "ARTWORK")
    d.icon:SetSize(18, 18)
    d.icon:SetPoint("LEFT", 5, 0)
    d.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    d.icon:Hide()
    d.label:ClearAllPoints()
    d.label:SetPoint("LEFT", 8, 0)
    d.label:SetPoint("RIGHT", -22, 0)
    d.label:SetJustifyH("LEFT")
    d.arrow = UI.Text(d, 10, C.dim, "CENTER")
    d.arrow:SetPoint("RIGHT", -8, 0)
    d.arrow:SetText("v")
    d.caption = UI.Text(d, 10, C.dim)
    d.caption:SetPoint("BOTTOMLEFT", d, "TOPLEFT", 1, 4)
    d.caption:SetText(caption or "")
    d.items, d.view, d.offset = {}, {}, 0

    local pop = UI.Box(UIParent, C.bg, C.accent)
    pop:SetFrameStrata("TOOLTIP")
    pop:SetSize(w, DD_TOP + DD_ROWS * DD_H + 4)
    pop:EnableMouseWheel(true)
    pop:Hide()
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:Hide()
    catcher:SetScript("OnClick", function()
        pop:Hide()
    end)
    pop:SetScript("OnShow", function()
        catcher:Show()
    end)
    pop:SetScript("OnHide", function()
        catcher:Hide()
    end)
    d:SetScript("OnHide", function()
        pop:Hide()
    end)

    local search = UI.Edit(pop, w - 8, "")
    search:ClearAllPoints()
    search:SetPoint("TOPLEFT", 4, -4)
    search:SetHeight(22)
    search.hint = UI.Text(search, 11, C.dim)
    search.hint:SetPoint("LEFT", 8, 0)
    search.hint:SetText("Search...")

    local thumb = pop:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetVertexColor(unpack(C.border))
    thumb:SetWidth(3)

    local function Refresh()
        local view = d.view
        local n = #view
        d.offset = math.max(0, math.min(d.offset, n - DD_ROWS))
        for i = 1, DD_ROWS do
            local r, it = pop.rows[i], view[i + d.offset]
            if it then
                r.item = it
                r.text:SetText(it.header or it.text)
                r.icon:SetTexture(it.icon)
                r.icon:SetShown(it.icon ~= nil)
                r.text:ClearAllPoints()
                r.text:SetPoint("RIGHT", -4, 0)
                if it.header then
                    r.text:SetTextColor(unpack(C.accent));
                    r.text:SetPoint("LEFT", 8, 0)
                else
                    r.text:SetTextColor(unpack(it.id == d.selected and C.accent or C.text));
                    r.text:SetPoint("LEFT", it.icon and 38 or 16, 0)
                end
                r:Show()
            else
                r:Hide()
            end
        end
        pop.none:SetShown(n == 0)
        if n > DD_ROWS then
            thumb:Show()
            local h = (DD_ROWS * DD_H) * DD_ROWS / n
            thumb:SetHeight(h)
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPRIGHT", -2, -DD_TOP - (DD_ROWS * DD_H - h) * d.offset / (n - DD_ROWS))
        else
            thumb:Hide()
        end
    end

    local function Filter()
        local q = search:GetText():lower():match("^%s*(.-)%s*$")
        search.hint:SetShown(q == "" and not search:HasFocus() or search:GetText() == "")
        if q == "" then
            d.view = d.items
        else
            d.view = {}
            for _, it in ipairs(d.items) do
                if not it.header and it.text:lower():find(q, 1, true) then
                    d.view[#d.view + 1] = it
                end
            end
        end
        d.offset = 0
        Refresh()
    end
    search:SetScript("OnTextChanged", Filter)
    search:SetScript("OnEscapePressed", function()
        pop:Hide()
    end)
    search:SetScript("OnEnterPressed", function()
        for _, it in ipairs(d.view) do
            if not it.header then
                pop:Hide();
                d:SetSelected(it.id);
                if d.onSelect then
                    d.onSelect(it.id, it.text)
                end
                return
            end
        end
    end)

    pop.none = UI.Text(pop, 11, C.dim, "CENTER")
    pop.none:SetPoint("TOP", 0, -DD_TOP - 12)
    pop.none:SetText("No matches")

    pop.rows = {}
    for i = 1, DD_ROWS do
        local r = CreateFrame("Button", nil, pop)
        r:SetPoint("TOPLEFT", 2, -DD_TOP - (i - 1) * DD_H)
        r:SetPoint("TOPRIGHT", -8, -DD_TOP - (i - 1) * DD_H)
        r:SetHeight(DD_H)
        r.hl = r:CreateTexture(nil, "BACKGROUND")
        r.hl:SetAllPoints()
        r.hl:SetTexture(WHITE)
        r.hl:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.25)
        r.hl:Hide()
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(16, 16)
        r.icon:SetPoint("LEFT", 16, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.text = UI.Text(r, 11, C.text)
        r:SetScript("OnEnter", function(s)
            if s.item and not s.item.header then
                s.hl:Show()
            end
        end)
        r:SetScript("OnLeave", function(s)
            s.hl:Hide()
        end)
        r:SetScript("OnClick", function(s)
            if s.item and not s.item.header then
                pop:Hide()
                d:SetSelected(s.item.id)
                if d.onSelect then
                    d.onSelect(s.item.id, s.item.text)
                end
            end
        end)
        pop.rows[i] = r
    end
    pop:SetScript("OnMouseWheel", function(_, delta)
        d.offset = d.offset - delta * 3;
        Refresh()
    end)

    function d:SetItems(items)
        self.items = items
    end
    function d:SetSelected(id)
        self.selected = id
        local text, icon
        for _, it in ipairs(self.items) do
            if it.id == id then
                text, icon = it.text, it.icon
            end
        end
        self.icon:SetTexture(icon)
        self.icon:SetShown(icon ~= nil)
        self.label:ClearAllPoints()
        self.label:SetPoint("LEFT", icon and 28 or 8, 0)
        self.label:SetPoint("RIGHT", -22, 0)
        self.label:SetText(text or self.placeholder or "Select...")
        self.label:SetTextColor(unpack(text and C.text or C.dim))
    end
    d:SetOnClick(function()
        if pop:IsShown() then
            pop:Hide()
            return
        end
        if d.getItems then
            d.items = d.getItems()
        end
        pop:ClearAllPoints()
        pop:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -2)
        search:SetText("")
        d.view = d.items
        d.offset = 0
        for i, it in ipairs(d.items) do
            if it.id == d.selected then
                d.offset = math.max(0, i - 4)
            end
        end
        Refresh()
        pop:Show()
        search.hint:Show()
        search:SetFocus()
    end)
    search:HookScript("OnEditFocusGained", function()
        search.hint:Hide()
    end)
    search:HookScript("OnEditFocusLost", function()
        search.hint:SetShown(search:GetText() == "")
    end)
    return d
end
