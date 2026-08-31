local addonName, ns = ...

ns.addonName = addonName
ns.version = "1.3.0"
ns.protocol = 1
ns.prefix = "DCD5"

ns.CATEGORY_OFFENSIVE = "OFFENSIVE"
ns.CATEGORY_DEFENSIVE = "DEFENSIVE"

ns.colors = {
    OFFENSIVE = { 1.00, 0.42, 0.08 },
    DEFENSIVE = { 0.12, 0.70, 1.00 },
    READY = { 0.20, 1.00, 0.35 },
}

ns.defaults = {
    enabled = true,
    showOffensive = true,
    showDefensive = true,
    showReady = true,
    side = "RIGHT",
    iconSize = 20,
    spacing = 2,
    rowSpacing = 2,
    frameGap = 4,
    offsetX = 0,
    offsetY = 0,
    alignment = "CENTER",
    iconAlpha = 1,
    borderStyle = "CATEGORY",
    borderSize = 1,
    maxPerCategory = 5,
    disabledSpells = {},
}

function ns.IsSpellEnabled(spellID)
    if not ns.db or not ns.db.disabledSpells then
        return true
    end
    local _, canonicalID = ns.GetSpellData(spellID)
    return ns.db.disabledSpells[tostring(canonicalID or spellID)] ~= true
end

function ns.SetSpellEnabled(spellID, enabled)
    ns.db.disabledSpells = ns.db.disabledSpells or {}
    local _, canonicalID = ns.GetSpellData(spellID)
    local key = tostring(canonicalID or spellID)
    ns.db.disabledSpells[key] = enabled and nil or true
end

function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff35cfffDungeon Cooldowns|r : " .. tostring(message))
end

_G.DungeonCooldowns = ns
