local addonName, ns = ...

local Core = {
    states = {},
    rosterGUIDs = {},
    nameToGUID = {},
    active = false,
    testMode = false,
    inspectQueue = {},
    pendingInspectGUID = nil,
}
ns.Core = Core

local eventFrame = CreateFrame("Frame")
Core.eventFrame = eventFrame

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                for childKey, childValue in pairs(value) do
                    target[key][childKey] = childValue
                end
            else
                target[key] = value
            end
        end
    end
end

local function GetPlayerSpecID()
    if PlayerUtil and PlayerUtil.GetCurrentSpecID then
        return PlayerUtil.GetCurrentSpecID() or 0
    end
    local index = GetSpecialization and GetSpecialization()
    if index then
        return GetSpecializationInfo(index) or 0
    end
    return 0
end

local function FullUnitName(unit)
    local name, realm = UnitFullName(unit)
    if not name then
        return nil
    end
    if not realm or realm == "" then
        realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    end
    return name .. "-" .. realm
end

local function ShortName(name)
    return name and Ambiguate(name, "short")
end

function Core:IsDungeonContent()
    if not ns.db or not ns.db.enabled then
        return false
    end
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "party" or IsInRaid() then
        return false
    end
    local members = GetNumGroupMembers()
    return members >= 1 and members <= 5
end

function Core:IsDisplayActive()
    return self.testMode or self.active
end

function Core:GetOrCreateState(guid)
    if not guid then
        return nil
    end
    local state = self.states[guid]
    if not state then
        state = {
            guid = guid,
            known = {},
            knownSet = {},
            timers = {},
            source = "observed",
            specID = 0,
        }
        self.states[guid] = state
    end
    return state
end

function Core:SetKnownSpells(state, spellList, source, specID)
    if not state then
        return
    end
    wipe(state.known)
    wipe(state.knownSet)

    local seenGroups = {}
    for _, spellID in ipairs(spellList or {}) do
        local data, canonicalID = ns.GetSpellData(spellID)
        if data then
            local group = data.group or canonicalID
            if not seenGroups[group] then
                seenGroups[group] = true
                state.known[#state.known + 1] = spellID
                state.knownSet[spellID] = true
            end
        end
    end

    state.source = source or state.source
    state.specID = specID or state.specID or 0
end

function Core:AddKnownSpell(state, spellID, source)
    if not state or state.knownSet[spellID] then
        return
    end
    local data = ns.GetSpellData(spellID)
    if not data then
        return
    end
    state.known[#state.known + 1] = spellID
    state.knownSet[spellID] = true
    if state.source ~= "synced" then
        state.source = source or "observed"
    end
end

function Core:IsSpellKnown(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) then
        return true
    end
    return IsPlayerSpell and IsPlayerSpell(spellID) or false
end

function Core:BuildLocalKnownSpells()
    local guid = UnitGUID("player")
    local state = self:GetOrCreateState(guid)
    if not state then
        return
    end

    local known = {}
    local seenGroups = {}
    for _, baseSpellID in ipairs(ns.spellOrder) do
        local candidate = baseSpellID
        if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
            local overrideSpellID = C_SpellBook.FindSpellOverrideByID(baseSpellID)
            if overrideSpellID and overrideSpellID ~= baseSpellID and self:IsSpellKnown(overrideSpellID) then
                candidate = overrideSpellID
            end
        end

        if self:IsSpellKnown(candidate) then
            local data, canonicalID = ns.GetSpellData(candidate)
            data = data or ns.spells[baseSpellID]
            canonicalID = canonicalID or baseSpellID
            if data then
                if not ns.spells[candidate] then
                    ns.spells[candidate] = {
                        id = candidate,
                        category = data.category,
                        cooldown = data.cooldown,
                        priority = data.priority,
                        group = data.group,
                    }
                end
                local group = data.group or canonicalID
                if not seenGroups[group] then
                    seenGroups[group] = true
                    known[#known + 1] = candidate
                end
            end
        end
    end

    state.isLocal = true
    state.unit = "player"
    state.synced = true
    self:SetKnownSpells(state, known, "self", GetPlayerSpecID())
end

function Core:RebuildRoster()
    wipe(self.rosterGUIDs)
    wipe(self.nameToGUID)
    local present = {}

    local units = { "player", "party1", "party2", "party3", "party4" }
    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local guid = UnitGUID(unit)
            if guid then
                present[guid] = true
                self.rosterGUIDs[guid] = true
                local state = self:GetOrCreateState(guid)
                state.unit = unit
                state.isLocal = UnitIsUnit(unit, "player")
                state.class = select(2, UnitClass(unit))
                state.fullName = FullUnitName(unit)

                if state.fullName then
                    self.nameToGUID[state.fullName] = guid
                    self.nameToGUID[ShortName(state.fullName)] = guid
                end
                local displayName = GetUnitName(unit, true)
                if displayName then
                    self.nameToGUID[displayName] = guid
                    self.nameToGUID[ShortName(displayName)] = guid
                end
            end
        end
    end

    for guid in pairs(self.states) do
        if not present[guid] then
            self.states[guid] = nil
        end
    end

    self:BuildLocalKnownSpells()
end

function Core:GetGUIDFromSender(sender)
    return self.nameToGUID[sender] or self.nameToGUID[ShortName(sender)]
end

function Core:GetCommChannel()
    if not IsInGroup() then
        return nil
    end
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and not IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return "INSTANCE_CHAT"
    end
    return "PARTY"
end

function Core:Send(message)
    if not self.active then
        return false
    end
    local channel = self:GetCommChannel()
    if not channel then
        return false
    end
    local result = C_ChatInfo.SendAddonMessage(ns.prefix, message, channel)
    self.lastCommResult = result
    return result == Enum.SendAddonMessageResult.Success
end

function Core:SendHello()
    self:Send("H|" .. ns.protocol)
end

function Core:SendKnownSpells()
    local state = self.states[UnitGUID("player")]
    if not state then
        return
    end
    local message = table.concat({
        "K",
        ns.protocol,
        state.specID or 0,
        table.concat(state.known, ","),
    }, "|")
    if #message <= 250 then
        self:Send(message)
    end
end

function Core:SendUsage(spellID)
    self:Send(table.concat({ "U", ns.protocol, spellID }, "|"))
end

function Core:RecordUsage(guid, spellID, source)
    local data, canonicalID = ns.GetSpellData(spellID)
    if not data then
        return false
    end

    local state = self:GetOrCreateState(guid)
    if not state then
        return false
    end
    self:AddKnownSpell(state, spellID, source)

    local now = GetTime()
    local timer = {
        start = now,
        duration = data.cooldown,
        expires = now + data.cooldown,
        canonicalID = canonicalID,
    }
    state.timers[spellID] = timer
    state.timers[canonicalID] = timer
    if data.group then
        state.timers[data.group] = timer
    end
    if state.source ~= "synced" then
        state.source = source or "observed"
    end
    ns.UI:RefreshAll()
    return true
end

function Core:HandleAddonMessage(message, sender)
    local kind, protocol, value1, value2 = strsplit("|", message)
    if tonumber(protocol) ~= ns.protocol then
        return
    end

    if kind == "H" then
        C_Timer.After(math.random() * 0.35, function()
            if Core.active then
                Core:SendKnownSpells()
            end
        end)
        return
    end

    local guid = self:GetGUIDFromSender(sender)
    if not guid or guid == UnitGUID("player") then
        return
    end
    local state = self:GetOrCreateState(guid)

    if kind == "K" then
        local specID = tonumber(value1) or 0
        local spells = {}
        for token in string.gmatch(value2 or "", "[^,]+") do
            local spellID = tonumber(token)
            if spellID and ns.GetSpellData(spellID) then
                spells[#spells + 1] = spellID
            end
        end
        state.synced = true
        self:SetKnownSpells(state, spells, "synced", specID)
        ns.UI:RefreshAll()
    elseif kind == "U" then
        local spellID = tonumber(value1)
        if spellID then
            state.synced = true
            state.source = "synced"
            self:RecordUsage(guid, spellID, "synced")
        end
    end
end

function Core:QueueInspections()
    wipe(self.inspectQueue)
    self.pendingInspectGUID = nil
    if not self.active then
        return
    end
    for index = 1, 4 do
        local unit = "party" .. index
        local guid = UnitGUID(unit)
        local state = guid and self.states[guid]
        if state and not state.synced then
            self.inspectQueue[#self.inspectQueue + 1] = unit
        end
    end
    C_Timer.After(0.75, function()
        Core:ProcessNextInspection()
    end)
end

function Core:ApplyInspectedSpec(unit, specID)
    local guid = UnitGUID(unit)
    local state = guid and self.states[guid]
    local spells = specID and ns.spellsBySpec[specID]
    if state and not state.synced and spells then
        self:SetKnownSpells(state, spells, "inspect", specID)
        ns.UI:RefreshAll()
    end
end

function Core:ProcessNextInspection()
    if not self.active or InCombatLockdown() or self.pendingInspectGUID then
        return
    end

    while #self.inspectQueue > 0 do
        local unit = table.remove(self.inspectQueue, 1)
        local guid = UnitGUID(unit)
        local state = guid and self.states[guid]
        if state and not state.synced and UnitExists(unit) then
            local knownSpec = GetInspectSpecialization(unit)
            if knownSpec and knownSpec > 0 then
                self:ApplyInspectedSpec(unit, knownSpec)
            elseif CanInspect(unit, false) then
                self.pendingInspectGUID = guid
                NotifyInspect(unit)
                return
            end
        end
    end
end

function Core:HandleInspectReady(guid)
    if guid ~= self.pendingInspectGUID then
        return
    end
    local state = self.states[guid]
    if state and state.unit then
        local specID = GetInspectSpecialization(state.unit)
        self:ApplyInspectedSpec(state.unit, specID)
    end
    ClearInspectPlayer()
    self.pendingInspectGUID = nil
    C_Timer.After(0.6, function()
        Core:ProcessNextInspection()
    end)
end

function Core:HandlePlayerSpellcast(unit, spellID)
    if not self.active or unit ~= "player" then
        return
    end
    local data = ns.GetSpellData(spellID)
    if data then
        self:SendUsage(spellID)
        ns.UI:RefreshCooldowns()
    end
end

function Core:RefreshLocalAfterSpellbookChange()
    C_Timer.After(0.25, function()
        if not ns.db then
            return
        end
        Core:BuildLocalKnownSpells()
        if Core.active then
            Core:SendKnownSpells()
        end
        ns.UI:RefreshAll()
    end)
end

function Core:UpdateActiveState()
    local wasActive = self.active
    self.active = self:IsDungeonContent()

    if self.active then
        self:RebuildRoster()
        ns.UI:EnsureFrames()
        if not wasActive then
            self:SendHello()
        end
        self:SendKnownSpells()
        self:QueueInspections()
    elseif wasActive then
        wipe(self.states)
        wipe(self.rosterGUIDs)
        wipe(self.nameToGUID)
    end

    ns.UI:RefreshAll()
end

function Core:StartTest()
    self.testMode = true
    self.testStarted = GetTime()
    ns.UI:EnsureFrames()
    ns.UI:RefreshAll()
    ns.Print("aperçu actif pendant 20 secondes sur vos cadres de groupe.")

    local started = self.testStarted
    C_Timer.After(20, function()
        if Core.testMode and Core.testStarted == started then
            Core.testMode = false
            ns.UI:RefreshAll()
            ns.Print("mode test terminé.")
        end
    end)
end

function Core:StopTest()
    self.testMode = false
    ns.UI:RefreshAll()
end

function Core:PrintStatus()
    local mode = self.active and "actif en donjon" or "inactif hors donjon à 5"
    ns.Print(mode .. " — suivi distant par synchronisation entre utilisateurs de l’addon.")
end

function Core:RegisterRuntimeEvents()
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    eventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:RegisterEvent("INSPECT_READY")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end

function Core:Initialize()
    DungeonCooldownsDB = DungeonCooldownsDB or {}
    CopyDefaults(DungeonCooldownsDB, ns.defaults)
    ns.db = DungeonCooldownsDB

    C_ChatInfo.RegisterAddonMessagePrefix(ns.prefix)
    ns.UI:Initialize()
    ns.Options:Initialize()
    self:RegisterRuntimeEvents()
end

function Core:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            eventFrame:UnregisterEvent("ADDON_LOADED")
            self:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        ns.UI:EnsureFrames()
        self:UpdateActiveState()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA"
        or event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_RESET" then
        C_Timer.After(0.2, function()
            Core:UpdateActiveState()
        end)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, _, sender = ...
        if self.active and prefix == ns.prefix then
            self:HandleAddonMessage(message, sender)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        self:HandlePlayerSpellcast(unit, spellID)
    elseif event == "INSPECT_READY" then
        self:HandleInspectReady(...)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.UI.pendingFrames or ns.UI.pendingLayout then
            ns.UI:EnsureFrames()
            ns.UI:ApplyLayout()
        end
        if self.active then
            self:BuildLocalKnownSpells()
            self:SendKnownSpells()
            self:ProcessNextInspection()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        ns.UI:RefreshCooldowns()
    elseif event == "SPELLS_CHANGED" or event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:RefreshLocalAfterSpellbookChange()
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    Core:OnEvent(event, ...)
end)
eventFrame:RegisterEvent("ADDON_LOADED")
