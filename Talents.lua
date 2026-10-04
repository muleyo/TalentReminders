local _, TR = ...

function TR:BuildTalentItems()
    local items, seen = {}, {}
    local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    local cfg = configID and C_Traits.GetConfigInfo(configID)
    if not cfg then
        return items
    end
    for _, treeID in ipairs(cfg.treeIDs or {}) do
        for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID)) do
            local node = C_Traits.GetNodeInfo(configID, nodeID)
            if node and node.isVisible then
                for _, entryID in ipairs(node.entryIDs or {}) do
                    local entry = C_Traits.GetEntryInfo(configID, entryID)
                    local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
                    local spell = def and def.spellID
                    if spell and not seen[spell] then
                        local name, icon = TR.SpellInfo(spell)
                        if name then
                            seen[spell] = true
                            items[#items + 1] = {
                                id = spell,
                                text = name,
                                icon = icon
                            }
                        end
                    end
                end
            end
        end
    end
    table.sort(items, function(a, b)
        return a.text < b.text
    end)
    return items
end
