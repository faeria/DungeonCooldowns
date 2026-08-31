local addonName, ns = ...

ns.addonName = addonName
ns.version = "1.5.0"
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
    contentMode = "DUNGEON",
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
    iconsPerRow = 5,
    maxRows = 2,
    disabledSpells = {},
    spellEnabled = {},
}

function ns.IsSpellEnabled(spellID)
    if not ns.db then
        return true
    end
    local _, canonicalID = ns.GetSpellData(spellID)
    local key = tostring(canonicalID or spellID)
    if ns.db.spellEnabled and ns.db.spellEnabled[key] ~= nil then
        return ns.db.spellEnabled[key] == true
    end
    return not ns.db.disabledSpells or ns.db.disabledSpells[key] ~= true
end

function ns.SetSpellEnabled(spellID, enabled)
    ns.db.disabledSpells = ns.db.disabledSpells or {}
    ns.db.spellEnabled = ns.db.spellEnabled or {}
    local _, canonicalID = ns.GetSpellData(spellID)
    local key = tostring(canonicalID or spellID)
    ns.db.spellEnabled[key] = enabled == true
    ns.db.disabledSpells[key] = enabled and nil or true
end

function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff35cfffDungeon Cooldowns|r : " .. tostring(message))
end

_G.DungeonCooldowns = ns
