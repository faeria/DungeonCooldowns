local _, ns = ...

-- The selection follows Blizzard_CooldownBroadcaster/TrackedCooldowns.lua from
-- the Retail 12.1.0 UI source, restricted to offensive and defensive cooldowns.
-- Durations are only used for remote estimations; the local player uses the
-- live C_Spell cooldown data directly.

ns.spells = {}
ns.spellOrder = {}

local function Add(spellID, category, cooldown, priority, group)
    ns.spells[spellID] = {
        id = spellID,
        category = category,
        cooldown = cooldown,
        priority = priority or 50,
        group = group,
    }
    ns.spellOrder[#ns.spellOrder + 1] = spellID
end

local OFF = ns.CATEGORY_OFFENSIVE
local DEF = ns.CATEGORY_DEFENSIVE

-- Death Knight
Add(49028, OFF, 90, 1)       -- Dancing Rune Weapon
Add(55233, DEF, 90, 1)       -- Vampiric Blood
Add(48792, DEF, 120, 2)      -- Icebound Fortitude
Add(48707, DEF, 60, 3)       -- Anti-Magic Shell
Add(51052, DEF, 120, 4)      -- Anti-Magic Zone
Add(51271, OFF, 60, 1)       -- Pillar of Frost
Add(47568, OFF, 120, 2)      -- Empower Rune Weapon
Add(1249658, OFF, 120, 3)    -- Breath of Sindragosa (12.1)
Add(42650, OFF, 480, 1)      -- Army of the Dead
Add(207289, OFF, 90, 2)      -- Unholy Assault
Add(275699, OFF, 45, 3)      -- Apocalypse

-- Demon Hunter
Add(191427, OFF, 120, 1)     -- Metamorphosis (Havoc)
Add(1217605, OFF, 120, 1)    -- Void Metamorphosis (Devourer)
Add(187827, DEF, 180, 1)     -- Metamorphosis (Vengeance)
Add(370965, OFF, 90, 2)      -- The Hunt
Add(1246167, OFF, 90, 2)     -- The Hunt (Devourer)
Add(198589, DEF, 60, 1)      -- Blur
Add(196718, DEF, 180, 2)     -- Darkness
Add(196555, DEF, 180, 3)     -- Netherwalk
Add(204021, DEF, 60, 2)      -- Fiery Brand
Add(203720, DEF, 20, 3)      -- Demon Spikes

-- Druid
Add(194223, OFF, 180, 1, "DRUID_BALANCE_BURST") -- Celestial Alignment
Add(102560, OFF, 180, 1, "DRUID_BALANCE_BURST") -- Incarnation: Chosen of Elune
Add(390414, OFF, 180, 1, "DRUID_BALANCE_BURST") -- Incarnation override
Add(102543, OFF, 180, 1, "DRUID_FERAL_BURST")   -- Incarnation: Avatar of Ashamane
Add(50334, OFF, 180, 1, "DRUID_GUARDIAN_BURST") -- Berserk
Add(102558, DEF, 180, 1, "DRUID_GUARDIAN_BURST")-- Incarnation: Guardian of Ursoc
Add(391528, OFF, 120, 2)     -- Convoke the Spirits
Add(22812, DEF, 60, 1)       -- Barkskin
Add(61336, DEF, 180, 2)      -- Survival Instincts
Add(22842, DEF, 36, 3)       -- Frenzied Regeneration
Add(108238, DEF, 90, 4)      -- Renewal
Add(740, DEF, 180, 1)        -- Tranquility
Add(33891, DEF, 180, 2)      -- Incarnation: Tree of Life
Add(102342, DEF, 90, 3)      -- Ironbark

-- Evoker
Add(375087, OFF, 120, 1)     -- Dragonrage
Add(370553, OFF, 120, 2)     -- Tip the Scales
Add(403631, OFF, 120, 1, "EVOKER_BREATH_OF_EONS") -- Breath of Eons
Add(442204, OFF, 120, 1, "EVOKER_BREATH_OF_EONS") -- Maneuverability override
Add(404977, OFF, 120, 2)     -- Time Skip
Add(363534, DEF, 240, 1)     -- Rewind
Add(363916, DEF, 90, 2)      -- Obsidian Scales
Add(374348, DEF, 60, 3)      -- Renewing Blaze
Add(374227, DEF, 120, 4)     -- Zephyr
Add(357170, DEF, 60, 2)      -- Time Dilation
Add(370960, DEF, 180, 3)     -- Emerald Communion

-- Hunter
Add(19574, OFF, 60, 1)       -- Bestial Wrath
Add(288613, OFF, 120, 1)     -- Trueshot
Add(1250646, OFF, 120, 1)    -- Takedown (12.1)
Add(360952, OFF, 120, 2)     -- Coordinated Assault
Add(186265, DEF, 180, 1)     -- Aspect of the Turtle
Add(264735, DEF, 180, 2)     -- Survival of the Fittest
Add(109304, DEF, 120, 3)     -- Exhilaration
Add(388035, DEF, 120, 4)     -- Fortitude of the Bear

-- Mage
Add(365350, OFF, 90, 1)      -- Arcane Surge
Add(190319, OFF, 90, 1)      -- Combustion
Add(205021, OFF, 60, 1)      -- Ray of Frost
Add(12472, OFF, 120, 2)      -- Icy Veins
Add(45438, DEF, 240, 1, "MAGE_ICE_BLOCK") -- Ice Block
Add(414658, DEF, 240, 1, "MAGE_ICE_BLOCK")-- Ice Cold
Add(342245, DEF, 60, 2)      -- Alter Time
Add(110959, DEF, 120, 3)     -- Greater Invisibility
Add(235450, DEF, 25, 4)      -- Prismatic Barrier
Add(235313, DEF, 25, 4)      -- Blazing Barrier
Add(11426, DEF, 25, 4)       -- Ice Barrier

-- Monk
Add(132578, OFF, 180, 1)     -- Invoke Niuzao
Add(123904, OFF, 120, 1)     -- Invoke Xuen
Add(322118, DEF, 180, 1, "MONK_HEALING_CELESTIAL") -- Invoke Yu'lon
Add(325197, DEF, 180, 1, "MONK_HEALING_CELESTIAL") -- Invoke Chi-Ji
Add(115203, DEF, 360, 1)     -- Fortifying Brew
Add(116849, DEF, 120, 2)     -- Life Cocoon
Add(322507, DEF, 60, 2)      -- Celestial Brew
Add(122783, DEF, 90, 3)      -- Diffuse Magic
Add(122278, DEF, 120, 4)     -- Dampen Harm
Add(122470, DEF, 90, 5)      -- Touch of Karma
Add(115310, DEF, 180, 2)     -- Revival

-- Paladin
Add(31884, OFF, 120, 1, "PALADIN_WINGS") -- Avenging Wrath
Add(231895, OFF, 120, 1, "PALADIN_WINGS")-- Crusade
Add(216331, OFF, 60, 2)      -- Avenging Crusader
Add(389539, DEF, 120, 1)     -- Sentinel
Add(31821, DEF, 180, 1)      -- Aura Mastery
Add(642, DEF, 300, 1)        -- Divine Shield
Add(6940, DEF, 120, 2)       -- Blessing of Sacrifice
Add(633, DEF, 600, 3)        -- Lay on Hands
Add(1022, DEF, 300, 4)       -- Blessing of Protection
Add(86659, DEF, 180, 1)      -- Guardian of Ancient Kings
Add(31850, DEF, 120, 2)      -- Ardent Defender
Add(498, DEF, 60, 2)         -- Divine Protection
Add(184662, DEF, 120, 2)     -- Shield of Vengeance

-- Priest
Add(10060, OFF, 120, 1)      -- Power Infusion
Add(228260, OFF, 120, 1)     -- Voidform
Add(421453, DEF, 240, 1)     -- Ultimate Penitence
Add(62618, DEF, 180, 1)      -- Power Word: Barrier
Add(19236, DEF, 90, 2)       -- Desperate Prayer
Add(33206, DEF, 180, 2)      -- Pain Suppression
Add(472433, DEF, 90, 3)      -- Evangelism
Add(47536, DEF, 90, 3)       -- Rapture
Add(200183, DEF, 120, 1)     -- Apotheosis
Add(64843, DEF, 180, 2)      -- Divine Hymn
Add(47788, DEF, 180, 2)      -- Guardian Spirit
Add(47585, DEF, 120, 1)      -- Dispersion

-- Rogue
Add(360194, OFF, 120, 1)     -- Deathmark
Add(13750, OFF, 180, 1)      -- Adrenaline Rush
Add(51690, OFF, 120, 2)      -- Killing Spree
Add(121471, OFF, 180, 1)     -- Shadow Blades
Add(185313, OFF, 60, 2)      -- Shadow Dance
Add(31224, DEF, 120, 1)      -- Cloak of Shadows
Add(5277, DEF, 120, 2)       -- Evasion
Add(1856, DEF, 120, 3)       -- Vanish
Add(185311, DEF, 30, 4)      -- Crimson Vial
Add(1966, DEF, 15, 5)        -- Feint

-- Shaman
Add(114050, OFF, 180, 1)     -- Ascendance (Elemental)
Add(114051, OFF, 180, 1)     -- Ascendance (Enhancement)
Add(191634, OFF, 60, 2)      -- Stormkeeper
Add(384352, OFF, 90, 2)      -- Doom Winds
Add(114052, DEF, 180, 1)     -- Ascendance (Restoration)
Add(108271, DEF, 120, 1)     -- Astral Shift
Add(198103, DEF, 300, 2)     -- Earth Elemental
Add(108280, DEF, 180, 1)     -- Healing Tide Totem
Add(98008, DEF, 180, 2)      -- Spirit Link Totem
Add(108281, DEF, 120, 3)     -- Ancestral Guidance

-- Warlock
Add(205180, OFF, 120, 1)     -- Summon Darkglare
Add(265187, OFF, 90, 1)      -- Summon Demonic Tyrant
Add(1122, OFF, 120, 1)       -- Summon Infernal
Add(104773, DEF, 180, 1)     -- Unending Resolve
Add(108416, DEF, 60, 2)      -- Dark Pact

-- Warrior
Add(107574, OFF, 90, 1)      -- Avatar
Add(228920, OFF, 90, 2)      -- Ravager
Add(227847, OFF, 90, 2)      -- Bladestorm
Add(1719, OFF, 90, 2)        -- Recklessness
Add(97462, DEF, 180, 1)      -- Rallying Cry
Add(118038, DEF, 120, 2)     -- Die by the Sword
Add(184364, DEF, 120, 2)     -- Enraged Regeneration
Add(871, DEF, 240, 1)        -- Shield Wall
Add(1160, DEF, 45, 2)        -- Demoralizing Shout
Add(12975, DEF, 180, 3)      -- Last Stand
Add(23920, DEF, 20, 4)       -- Spell Reflection

-- Spec IDs and their recommended visible cooldowns. These are used only when
-- inspecting a party member who does not run Dungeon Cooldowns.
ns.spellsBySpec = {
    [250] = { 49028, 55233, 48792, 48707, 51052 },
    [251] = { 1249658, 51271, 47568, 48792, 48707, 51052 },
    [252] = { 42650, 207289, 275699, 48792, 48707, 51052 },
    [577] = { 191427, 370965, 198589, 196718, 196555 },
    [1480] = { 1217605, 1246167, 198589, 196718, 196555 },
    [581] = { 187827, 204021, 203720, 196718 },
    [102] = { 194223, 102560, 390414, 391528, 22812, 108238 },
    [103] = { 102543, 391528, 22812, 61336, 108238 },
    [104] = { 50334, 102558, 391528, 22812, 61336, 22842 },
    [105] = { 740, 391528, 33891, 22812, 102342, 108238 },
    [1467] = { 375087, 370553, 363916, 374348, 374227 },
    [1468] = { 363534, 357170, 370960, 363916, 374227 },
    [1473] = { 403631, 442204, 404977, 363916, 374227 },
    [253] = { 19574, 186265, 264735, 109304, 388035 },
    [254] = { 288613, 186265, 264735, 109304, 388035 },
    [255] = { 1250646, 360952, 186265, 264735, 109304 },
    [62] = { 365350, 45438, 414658, 342245, 110959, 235450 },
    [63] = { 190319, 45438, 414658, 342245, 110959, 235313 },
    [64] = { 205021, 12472, 45438, 414658, 342245, 11426 },
    [268] = { 132578, 115203, 322507, 122783, 122278 },
    [269] = { 123904, 115203, 122783, 122278, 122470 },
    [270] = { 322118, 325197, 115203, 116849, 115310 },
    [65] = { 31884, 216331, 31821, 642, 6940, 633 },
    [66] = { 31884, 389539, 86659, 31850, 642, 6940, 633 },
    [70] = { 31884, 231895, 642, 6940, 1022, 184662 },
    [256] = { 10060, 421453, 62618, 19236, 33206, 472433, 47536 },
    [257] = { 10060, 200183, 64843, 47788, 19236 },
    [258] = { 10060, 228260, 19236, 47585 },
    [259] = { 360194, 31224, 5277, 1856, 185311, 1966 },
    [260] = { 13750, 51690, 31224, 5277, 1856, 185311 },
    [261] = { 121471, 185313, 31224, 5277, 1856, 185311 },
    [262] = { 114050, 191634, 108271, 198103 },
    [263] = { 114051, 384352, 108271, 198103 },
    [264] = { 108280, 114052, 98008, 108271, 108281 },
    [265] = { 205180, 104773, 108416 },
    [266] = { 265187, 104773, 108416 },
    [267] = { 1122, 104773, 108416 },
    [71] = { 107574, 228920, 227847, 97462, 118038 },
    [72] = { 107574, 227847, 1719, 97462, 184364 },
    [73] = { 107574, 871, 97462, 1160, 12975, 23920 },
}

function ns.GetSpellData(spellID)
    local data = ns.spells[spellID]
    if data then
        return data, spellID
    end

    if C_SpellBook and C_SpellBook.FindBaseSpellByID then
        local baseSpellID = C_SpellBook.FindBaseSpellByID(spellID)
        if baseSpellID and ns.spells[baseSpellID] then
            return ns.spells[baseSpellID], baseSpellID
        end
    end

    return nil
end
