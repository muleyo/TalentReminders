local _, TR = ...

TR.CurrentDungeons = {"Murder Row", "Den of Nalorakk", "Temple of Sethraliss", "Kings' Rest", "The Blinding Vale", "Ruby Life Pools",
                      "Voidscar Arena", "Altar of Fangs"}

TR.instanceNames = {}
local function Norm(s)
    return (s or ""):lower():gsub("[^%w]", "")
end

function TR:BuildInstanceItems()
    if self.instanceItems then
        return self.instanceItems
    end
    if not EJ_GetInstanceByIndex then
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
        elseif LoadAddOn then
            LoadAddOn("Blizzard_EncounterJournal")
        end
    end
    if not EJ_GetInstanceByIndex then
        return {}
    end

    local seen, groups, byNorm = {}, {}, {}
    local prevTier = EJ_GetCurrentTier and EJ_GetCurrentTier()
    for tier = 1, EJ_GetNumTiers() do
        EJ_SelectTier(tier)
        local tierName = EJ_GetTierInfo(tier)
        for _, raid in ipairs({true, false}) do
            local g = {
                title = ("%s - %s"):format(tierName, raid and "Raids" or "Dungeons"),
                list = {}
            }
            local i = 1
            while true do
                local jid, name = EJ_GetInstanceByIndex(i, raid)
                if not jid then
                    break
                end
                local mapID = select(10, EJ_GetInstanceInfo(jid))
                if mapID and mapID > 0 and not seen[mapID] then
                    seen[mapID] = true
                    local e = {
                        id = mapID,
                        text = name
                    }
                    g.list[#g.list + 1] = e
                    byNorm[Norm(name)] = e
                    self.instanceNames[mapID] = name
                end
                i = i + 1
            end
            if #g.list > 0 then
                groups[#groups + 1] = g
            end
        end
    end
    if prevTier then
        EJ_SelectTier(prevTier)
    end

    local items, missing = {}, {}
    for _, n in ipairs(self.CurrentDungeons) do
        local e = byNorm[Norm(n)]
        if e then
            items[#items + 1] = {
                id = e.id,
                text = e.text
            }
        else
            missing[#missing + 1] = n
        end
    end
    self.missingCurrent = missing
    self.instanceItems = items
    return items
end
