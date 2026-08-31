local _, ns = ...

local UI = {
    overlays = {},
    iconPool = {},
    ticker = nil,
}
ns.UI = UI

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function GetSpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local texture = C_Spell.GetSpellTexture(spellID)
        if texture then
            return texture
        end
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.iconID
    end

    return 134400
end

local function FormatSeconds(seconds)
    if seconds >= 60 then
        return string.format("%dm %02ds", math.floor(seconds / 60), math.floor(seconds % 60))
    end
    return string.format("%.1fs", math.max(0, seconds))
end

local function OnIconEnter(icon)
    if not icon.spellID then
        return
    end

    GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(icon.spellID)

    local data = ns.spells[icon.spellID]
    if not data then
        data = select(1, ns.GetSpellData(icon.spellID))
    end

    if data then
        local label = data.category == ns.CATEGORY_DEFENSIVE and "Défensif" or "Offensif"
        local color = ns.colors[data.category]
        GameTooltip:AddLine(label, color[1], color[2], color[3])
    end

    if icon.isLocal then
        GameTooltip:AddLine("État exact fourni par WoW", 0.35, 1.0, 0.45)
    elseif icon.source == "synced" then
        GameTooltip:AddLine("Sort confirmé par Dungeon Cooldowns", 0.35, 1.0, 0.45)
        GameTooltip:AddLine("Durée distante estimée", 1.0, 0.82, 0.25)
    elseif icon.source == "inspect" then
        GameTooltip:AddLine("Spécialisation inspectée — estimation", 1.0, 0.82, 0.25)
    elseif icon.source == "observed" then
        GameTooltip:AddLine("Utilisation observée — estimation", 1.0, 0.82, 0.25)
    end

    if icon.timer and icon.timer.expires and icon.timer.expires > GetTime() then
        GameTooltip:AddLine("Recharge estimée : " .. FormatSeconds(icon.timer.expires - GetTime()), 0.9, 0.9, 0.9)
    end

    GameTooltip:Show()
end

local function CreateIcon(parent)
    local icon = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    icon:SetBackdrop(BACKDROP)
    icon:SetBackdropColor(0.02, 0.02, 0.02, 0.92)
    icon:SetClipsChildren(true)
    icon:EnableMouse(true)

    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints(icon.texture)
    icon.cooldown:SetDrawSwipe(true)
    icon.cooldown:SetDrawEdge(true)
    icon.cooldown:SetHideCountdownNumbers(false)
    icon.cooldown:SetSwipeColor(0, 0, 0, 0.78)

    icon.ready = icon:CreateTexture(nil, "OVERLAY")
    icon.ready:SetColorTexture(unpack(ns.colors.READY))
    icon.ready:SetSize(4, 4)
    icon.ready:SetPoint("TOPRIGHT", -2, -2)

    icon.charges = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    icon.charges:SetPoint("BOTTOMRIGHT", -1, 1)
    icon.charges:SetJustifyH("RIGHT")

    icon:SetScript("OnEnter", OnIconEnter)
    icon:SetScript("OnLeave", GameTooltip_Hide)
    return icon
end

function UI:CreateOverlay(unitFrame)
    -- CompactPartyFrame members are protected unit frames. Parenting addon
    -- frames to them can propagate taint and eventually block Blizzard UI
    -- actions. Keep our overlays in an independent UIParent hierarchy and
    -- only use the Blizzard frame as an out-of-combat anchor.
    local overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetFrameStrata(unitFrame:GetFrameStrata() or "MEDIUM")
    overlay:SetFrameLevel(unitFrame:GetFrameLevel() + 20)
    overlay.unitFrame = unitFrame
    overlay.lastUnitFrameVisible = false
    overlay.icons = {}
    overlay:Hide()

    self.overlays[unitFrame] = overlay
    return overlay
end

function UI:CreateTestPreview()
    if self.testFrame then
        return
    end

    local frame = CreateFrame("Frame", "DungeonCooldownsTestPreview", UIParent, "BackdropTemplate")
    frame:SetSize(180, 52)
    frame:SetPoint("CENTER", UIParent, "CENTER", -180, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0.02, 0.02, 0.025, 0.98)
    frame:SetBackdropBorderColor(0.08, 0.08, 0.10, 1)
    frame.isDungeonCooldownsTest = true

    local health = frame:CreateTexture(nil, "BACKGROUND")
    health:SetPoint("TOPLEFT", 2, -2)
    health:SetPoint("BOTTOMRIGHT", -2, 7)
    health:SetColorTexture(0.25, 0.58, 0.82, 0.90)

    local healthShade = frame:CreateTexture(nil, "BORDER")
    healthShade:SetPoint("TOPLEFT", health, "TOPLEFT")
    healthShade:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
    healthShade:SetColorTexture(0, 0, 0, 0.18)

    local resource = frame:CreateTexture(nil, "ARTWORK")
    resource:SetPoint("BOTTOMLEFT", 2, 2)
    resource:SetPoint("BOTTOMRIGHT", -2, 2)
    resource:SetHeight(4)
    resource:SetColorTexture(0.10, 0.35, 0.95, 1)

    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("TOP", 0, -8)
    name:SetText("Aperçu raid frame")

    local healthValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    healthValue:SetPoint("BOTTOM", 0, 10)
    healthValue:SetText("463K")

    frame:Hide()
    self.testFrame = frame
    self:CreateOverlay(frame)
end

function UI:GetUnitFrames()
    local frames = {}
    local seen = {}
    local function AddFrame(frame)
        if frame and not seen[frame] and frame.GetObjectType then
            seen[frame] = true
            frames[#frames + 1] = frame
        end
    end
    if CompactPartyFrame and CompactPartyFrame.memberUnitFrames then
        for _, frame in ipairs(CompactPartyFrame.memberUnitFrames) do AddFrame(frame) end
    end
    for index = 1, 5 do
        AddFrame(_G["CompactPartyFrameMember" .. index])
    end
    for index = 1, 40 do
        AddFrame(_G["CompactRaidFrame" .. index])
    end
    if CompactRaidFrameContainer and CompactRaidFrameContainer.unitFramePool then
        for frame in CompactRaidFrameContainer.unitFramePool:EnumerateActive() do AddFrame(frame) end
    end
    if PartyFrame and PartyFrame.PartyMemberFramePool then
        for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do AddFrame(frame) end
    end
    return frames
end

function UI:EnsureFrames()
    -- Never call CompactPartyFrame_Generate here. It creates protected
    -- Blizzard unit frames and is reserved for Blizzard's own UI code.
    local unitFrames = self:GetUnitFrames()
    if #unitFrames == 0 then
        self.pendingFrames = true
        return false
    end

    local foundAllFrames = true
    local createdAny = false
    self.frameOrder = unitFrames
    for _, unitFrame in ipairs(unitFrames) do
        if not self.overlays[unitFrame] then
            if InCombatLockdown() then
                foundAllFrames = false
            else
                self:CreateOverlay(unitFrame)
                createdAny = true
            end
        end
    end

    self.pendingFrames = foundAllFrames and nil or true
    if createdAny then self:ApplyLayout() end
    return foundAllFrames
end

function UI:ApplyLayout()
    if not ns.db then
        return
    end
    if InCombatLockdown() then
        self.pendingLayout = true
        return
    end

    local size = ns.db.iconSize
    local spacing = ns.db.spacing
    local width = (size * ns.db.maxPerCategory) + (spacing * math.max(0, ns.db.maxPerCategory - 1))
    local visibleRows = (ns.db.showDefensive and 1 or 0) + (ns.db.showOffensive and 1 or 0)
    local height = math.max(size, (size * visibleRows) + (ns.db.rowSpacing * math.max(0, visibleRows - 1)))

    for unitFrame, overlay in pairs(self.overlays) do
        overlay:ClearAllPoints()
        overlay:SetSize(width, height)
        local alignment = ns.db.alignment or "CENTER"
        local overlayPoint
        local framePoint
        if ns.db.side == "LEFT" then
            overlayPoint = alignment == "TOP" and "TOPRIGHT" or (alignment == "BOTTOM" and "BOTTOMRIGHT" or "RIGHT")
            framePoint = alignment == "TOP" and "TOPLEFT" or (alignment == "BOTTOM" and "BOTTOMLEFT" or "LEFT")
            overlay:SetPoint(overlayPoint, unitFrame, framePoint, -(ns.db.frameGap or 4) + (ns.db.offsetX or 0), ns.db.offsetY or 0)
        else
            overlayPoint = alignment == "TOP" and "TOPLEFT" or (alignment == "BOTTOM" and "BOTTOMLEFT" or "LEFT")
            framePoint = alignment == "TOP" and "TOPRIGHT" or (alignment == "BOTTOM" and "BOTTOMRIGHT" or "RIGHT")
            overlay:SetPoint(overlayPoint, unitFrame, framePoint, (ns.db.frameGap or 4) + (ns.db.offsetX or 0), ns.db.offsetY or 0)
        end

        for _, icon in ipairs(overlay.icons) do
            icon:SetSize(size, size)
            local edgeSize = ns.db.borderStyle == "NONE" and 0 or (ns.db.borderSize or 1)
            icon:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = edgeSize > 0 and "Interface\\Buttons\\WHITE8X8" or nil,
                edgeSize = edgeSize,
            })
        end
    end

    self.pendingLayout = nil
    self:RefreshAll()
end

local function IsLocalSpellOnCooldown(spellID)
    local info = C_Spell.GetSpellCooldown(spellID)
    return info and info.isActive and not info.isOnGCD
end

function UI:ShouldIncludeSpell(spellID, data, isLocal, timer)
    if not ns.IsSpellEnabled(spellID) then
        return false
    end
    if data.category == ns.CATEGORY_OFFENSIVE and not ns.db.showOffensive then
        return false
    end
    if data.category == ns.CATEGORY_DEFENSIVE and not ns.db.showDefensive then
        return false
    end
    if ns.db.showReady then
        return true
    end
    if timer and timer.expires and timer.expires > GetTime() then
        return true
    end
    if isLocal then
        -- In 12.1 cooldown state can be a protected value. Never branch on it
        -- when secret restrictions exist; the Cooldown widget remains legal.
        if C_Secrets and C_Secrets.HasSecretRestrictions and C_Secrets.HasSecretRestrictions() then
            return true
        end
        return IsLocalSpellOnCooldown(spellID)
    end
    return false
end

function UI:GetEntries(state, isLocal)
    local entries = {}
    local seenGroups = {}
    local known = state and state.known or {}

    for _, spellID in ipairs(known) do
        local data, canonicalID = ns.GetSpellData(spellID)
        if data then
            local timer = state.timers and (state.timers[spellID] or state.timers[canonicalID] or state.timers[data.group])
            local group = data.group or canonicalID
            if not seenGroups[group] and self:ShouldIncludeSpell(spellID, data, isLocal, timer) then
                seenGroups[group] = true
                entries[#entries + 1] = {
                    spellID = spellID,
                    data = data,
                    timer = timer,
                }
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.data.category ~= b.data.category then
            return a.data.category == ns.CATEGORY_DEFENSIVE
        end
        if a.data.priority ~= b.data.priority then
            return a.data.priority < b.data.priority
        end
        return a.spellID < b.spellID
    end)

    local selected = {}
    local counts = { OFFENSIVE = 0, DEFENSIVE = 0 }
    for _, entry in ipairs(entries) do
        local category = entry.data.category
        if counts[category] < ns.db.maxPerCategory then
            counts[category] = counts[category] + 1
            entry.categoryIndex = counts[category]
            selected[#selected + 1] = entry
        end
    end

    return selected
end

local TEST_PROFILES = {
    { 642, 6940, 633, 31884, 1022, 184662 },
    { 55233, 48792, 48707, 49028, 51052 },
    { 190319, 45438, 342245, 110959, 235313 },
    { 10060, 62618, 19236, 33206, 47536 },
    { 107574, 97462, 118038, 871, 23920 },
}

function UI:GetTestEntries(unitFrame)
    local profileIndex = 1
    if self.frameOrder then
        for index, frame in ipairs(self.frameOrder) do
            if frame == unitFrame then
                profileIndex = index
                break
            end
        end
    end
    local testSpells = TEST_PROFILES[profileIndex] or TEST_PROFILES[1]
    local state = {
        known = testSpells,
        timers = {},
        source = "synced",
    }
    local now = GetTime()
    local testElapsed = now - (ns.Core.testStarted or now)
    local first = testSpells[1]
    local second = testSpells[2]
    local fourth = testSpells[4]
    local function AddLoopingTimer(spellID, duration, offset)
        if not spellID then return end
        local elapsed = (testElapsed + offset) % duration
        state.timers[spellID] = { start = now - elapsed, duration = duration, expires = now + duration - elapsed }
    end
    AddLoopingTimer(first, 120, 18)
    AddLoopingTimer(second, 90, 32)
    AddLoopingTimer(fourth, 120, 54)
    return self:GetEntries(state, false), state
end

function UI:AcquireIcon(overlay, index)
    local icon = overlay.icons[index]
    if not icon then
        icon = CreateIcon(overlay)
        overlay.icons[index] = icon
    end
    icon:SetSize(ns.db.iconSize, ns.db.iconSize)
    local edgeSize = ns.db.borderStyle == "NONE" and 0 or (ns.db.borderSize or 1)
    icon:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = edgeSize > 0 and "Interface\\Buttons\\WHITE8X8" or nil,
        edgeSize = edgeSize,
    })
    return icon
end

function UI:PositionIcon(icon, entry)
    local size = ns.db.iconSize
    local spacing = ns.db.spacing
    local bothRows = ns.db.showDefensive and ns.db.showOffensive
    local row = 0
    if bothRows and entry.data.category == ns.CATEGORY_OFFENSIVE then
        row = 1
    end
    local x = (entry.categoryIndex - 1) * (size + spacing)
    local y = row * (size + (ns.db.rowSpacing or spacing))

    icon:ClearAllPoints()
    if ns.db.side == "LEFT" then
        icon:SetPoint("TOPRIGHT", icon:GetParent(), "TOPRIGHT", -x, -y)
    else
        icon:SetPoint("TOPLEFT", icon:GetParent(), "TOPLEFT", x, -y)
    end
end

function UI:RefreshLocalIcon(icon)
    local cooldownInfo = C_Spell.GetSpellCooldown(icon.spellID)
    if cooldownInfo then
        icon.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.modRate)
    else
        icon.cooldown:Clear()
    end

    icon.charges:SetText("")
    icon.ready:Hide()
    icon.texture:SetDesaturated(false)

    local secretsEnabled = C_Secrets and C_Secrets.HasSecretRestrictions and C_Secrets.HasSecretRestrictions()
    if not secretsEnabled then
        local active = cooldownInfo and cooldownInfo.isActive and not cooldownInfo.isOnGCD
        icon.texture:SetDesaturated(active or false)
        icon.ready:SetShown(not active)

        local chargeInfo = C_Spell.GetSpellCharges(icon.spellID)
        if chargeInfo and chargeInfo.maxCharges and chargeInfo.maxCharges > 1 then
            icon.charges:SetText(chargeInfo.currentCharges)
        end
    end
end

function UI:RefreshRemoteIcon(icon)
    local timer = icon.timer
    if timer and timer.expires and timer.expires > GetTime() then
        icon.cooldown:SetCooldown(timer.start, timer.duration, 1)
        icon.texture:SetDesaturated(true)
        icon.ready:Hide()
    else
        icon.cooldown:Clear()
        icon.texture:SetDesaturated(false)
        icon.ready:Show()
    end
    icon.charges:SetText("")
end

function UI:AssignIcon(icon, entry, state, isLocal)
    icon.spellID = entry.spellID
    icon.timer = entry.timer
    icon.isLocal = isLocal
    icon.source = state and state.source
    icon.texture:SetTexture(GetSpellTexture(entry.spellID))

    local color = ns.colors[entry.data.category]
    if ns.db.borderStyle == "DARK" then
        icon:SetBackdropBorderColor(0.04, 0.04, 0.05, 1)
    elseif ns.db.borderStyle == "NONE" then
        icon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        icon:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    end
    local sourceAlpha = (isLocal or icon.source == "synced") and 1 or 0.82
    icon:SetAlpha(sourceAlpha * (ns.db.iconAlpha or 1))

    if isLocal then
        self:RefreshLocalIcon(icon)
    else
        self:RefreshRemoteIcon(icon)
    end

    self:PositionIcon(icon, entry)
    icon:Show()
end

function UI:RefreshOverlay(unitFrame, overlay)
    local unitFrameVisible = unitFrame:IsVisible()
    overlay.lastUnitFrameVisible = unitFrameVisible
    if not ns.Core or not ns.Core:IsDisplayActive() or not unitFrameVisible then
        overlay:Hide()
        return
    end

    local isTestPreview = unitFrame.isDungeonCooldownsTest
    local unit
    if unitFrame.GetUnit then
        unit = unitFrame:GetUnit()
    end
    unit = unit or unitFrame.displayedUnit or unitFrame.unit or unitFrame.unitToken
    if not isTestPreview and (not unit or not UnitExists(unit) or not UnitIsPlayer(unit)) then
        overlay:Hide()
        return
    end

    local isLocal = not isTestPreview and UnitIsUnit(unit, "player")
    local state
    local entries
    if ns.Core.testMode then
        entries, state = self:GetTestEntries(unitFrame)
        isLocal = false
    else
        local guid = UnitGUID(unit)
        state = guid and ns.Core.states[guid]
        if not state then
            overlay:Hide()
            return
        end
        entries = self:GetEntries(state, isLocal)
    end

    if #entries == 0 then
        overlay:Hide()
        return
    end

    for index, entry in ipairs(entries) do
        local icon = self:AcquireIcon(overlay, index)
        self:AssignIcon(icon, entry, state, isLocal)
    end
    for index = #entries + 1, #overlay.icons do
        overlay.icons[index]:Hide()
    end
    overlay:Show()
end

function UI:RefreshAll()
    if not ns.db then
        return
    end
    if self.testFrame then
        local hasVisiblePartyFrame = false
        if ns.Core and ns.Core.testMode then
            for _, frame in ipairs(self:GetUnitFrames()) do
                if frame:IsVisible() then
                    hasVisiblePartyFrame = true
                    break
                end
            end
        end
        self.testFrame:SetShown(ns.Core and ns.Core.testMode and not hasVisiblePartyFrame or false)
    end
    for unitFrame, overlay in pairs(self.overlays) do
        self:RefreshOverlay(unitFrame, overlay)
    end
end

function UI:RefreshCooldowns()
    if not InCombatLockdown() then
        local now = GetTime()
        if not self.nextFrameDiscovery or now >= self.nextFrameDiscovery then
            self.nextFrameDiscovery = now + 1
            self:EnsureFrames()
        end
    end

    if not ns.Core or not ns.Core:IsDisplayActive() then
        return
    end

    if ns.Core.testMode then
        self:RefreshAll()
        return
    end

    local needsLayoutRefresh = false
    local now = GetTime()
    for unitFrame, overlay in pairs(self.overlays) do
        local unitFrameVisible = unitFrame:IsVisible()
        if unitFrameVisible ~= overlay.lastUnitFrameVisible then
            self:RefreshOverlay(unitFrame, overlay)
        elseif overlay:IsShown() then
            for _, icon in ipairs(overlay.icons) do
                if icon:IsShown() then
                    if icon.isLocal then
                        self:RefreshLocalIcon(icon)
                    else
                        local expired = icon.timer and icon.timer.expires and icon.timer.expires <= now
                        self:RefreshRemoteIcon(icon)
                        if expired and not ns.db.showReady then
                            needsLayoutRefresh = true
                        end
                    end
                end
            end
        end
    end

    if needsLayoutRefresh then
        self:RefreshAll()
    end
end

function UI:Initialize()
    self:EnsureFrames()
    self:CreateTestPreview()
    self:ApplyLayout()
    if not self.ticker then
        self.ticker = C_Timer.NewTicker(0.25, function()
            UI:RefreshCooldowns()
        end)
    end
end
