local addonName, ns = ...

ns.addonName = addonName
ns.version = "1.0.2"
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
    maxPerCategory = 5,
}

function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff35cfffDungeon Cooldowns|r : " .. tostring(message))
end

_G.DungeonCooldowns = ns
