local passed = 0
local failed = 0

local function Fail(message)
    error(message, 2)
end

local function AssertEqual(actual, expected, message)
    if actual ~= expected then
        Fail((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function AssertTrue(value, message)
    if value ~= true then
        Fail((message or "expected true") .. ": got " .. tostring(value))
    end
end

local function AssertFalse(value, message)
    if value ~= false then
        Fail((message or "expected false") .. ": got " .. tostring(value))
    end
end

local function AssertContains(value, fragment, message)
    if not string.find(value or "", fragment, 1, true) then
        Fail((message or "missing fragment") .. ": expected " .. tostring(fragment) .. " in " .. tostring(value))
    end
end

local function AssertNotContains(value, fragment, message)
    if string.find(value or "", fragment, 1, true) then
        Fail((message or "unexpected fragment") .. ": found " .. tostring(fragment) .. " in " .. tostring(value))
    end
end

local function Test(name, callback)
    local ok, err = pcall(callback)
    if ok then
        passed = passed + 1
        print("PASS " .. name)
    else
        failed = failed + 1
        print("FAIL " .. name .. "\n  " .. tostring(err))
    end
end

local now = 100
local chatLockdown = false
local outgoingRestricted = false
local sendResult = 0
local sendCalls = 0
local printed = {}

function CreateFrame()
    return {
        RegisterEvent = function() end,
        UnregisterEvent = function() end,
        RegisterUnitEvent = function() end,
        SetScript = function() end,
    }
end

function wipe(target)
    for key in pairs(target) do
        target[key] = nil
    end
end

function GetTime()
    return now
end

function UnitGUID(unit)
    if unit == "player" then
        return "Player-1-LOCAL"
    end
    return nil
end

function IsInGroup()
    return true
end

function IsInRaid()
    return false
end

function Ambiguate(name)
    return name
end

function strsplit(separator, value)
    local fields = {}
    local start = 1
    while true do
        local first, last = string.find(value, separator, start, true)
        if not first then
            fields[#fields + 1] = string.sub(value, start)
            break
        end
        fields[#fields + 1] = string.sub(value, start, first - 1)
        start = last + 1
    end
    return unpack(fields)
end

C_Timer = {
    After = function(_, callback) callback() end,
    NewTicker = function() return {} end,
}

Enum = {
    SendAddonMessageResult = {
        Success = 0,
        AddonMessageThrottle = 3,
        NotInGroup = 5,
        AddOnMessageLockdown = 11,
    },
}

C_ChatInfo = {
    InChatMessagingLockdown = function()
        return chatLockdown
    end,
    AreOutgoingAddonChatMessagesRestricted = function()
        return outgoingRestricted
    end,
    SendAddonMessage = function()
        sendCalls = sendCalls + 1
        return sendResult
    end,
    RegisterAddonMessagePrefix = function()
        return true
    end,
}

local uiStub = {
    refreshes = 0,
    RefreshAll = function(self) self.refreshes = self.refreshes + 1 end,
    RefreshCooldowns = function() end,
    EnsureFrames = function() end,
}

local ns = {
    UI = uiStub,
    Options = { Initialize = function() end },
    defaults = {},
    prefix = "DCD5",
    protocol = 1,
    version = "test",
    spellOrder = {},
    spells = {},
    spellsBySpec = {},
    colors = {
        OFFENSIVE = { 1, 0.4, 0.1 },
        DEFENSIVE = { 0.1, 0.7, 1 },
        READY = { 0.2, 1, 0.35 },
    },
    CATEGORY_OFFENSIVE = "OFFENSIVE",
    CATEGORY_DEFENSIVE = "DEFENSIVE",
    GetSpellData = function() return nil end,
    IsSpellEnabled = function() return true end,
    Print = function(message) printed[#printed + 1] = message end,
}

local coreChunk = assert(loadfile("Core.lua"))
coreChunk("DungeonCooldowns", ns)
local Core = ns.Core

local function ResetCore()
    now = 100
    Core.active = true
    Core.communicationState = "unavailable"
    Core.communicationReason = nil
    Core.lastCommResult = nil
    Core.lastSendAt = nil
    Core.lastSendChannel = nil
    Core.states = {
        ["Player-1-LOCAL"] = {
            guid = "Player-1-LOCAL",
            known = {},
            knownSet = {},
            timers = {},
            specID = 0,
            isLocal = true,
        },
    }
    Core.peers = {}
    Core.rosterGUIDs = { ["Player-1-LOCAL"] = true }
    chatLockdown = false
    outgoingRestricted = false
    sendResult = Enum.SendAddonMessageResult.Success
    sendCalls = 0
    printed = {}
    uiStub.refreshes = 0
    ns.UI = uiStub
end

Test("successful addon messages still use PARTY outside lockdown", function()
    ResetCore()
    AssertTrue(Core:Send("H|1"), "successful send")
    AssertEqual(sendCalls, 1, "transport call count")
    AssertEqual(Core.lastCommResult, Enum.SendAddonMessageResult.Success, "stored result")
    AssertEqual(Core.lastSendChannel, "PARTY", "selected channel")
end)

Test("chat lockdown blocks transport before SendAddonMessage", function()
    ResetCore()
    chatLockdown = true
    outgoingRestricted = true

    AssertFalse(Core:Send("U|1|642"), "lockdown send result")
    AssertEqual(sendCalls, 0, "blocked transport must not be called")
    AssertEqual(Core.lastCommResult, Enum.SendAddonMessageResult.AddOnMessageLockdown, "lockdown result")
    AssertEqual(Core.communicationState, "blocked", "communication state")
end)

Test("enum 11 returned by the transport is classified as blocked", function()
    ResetCore()
    sendResult = Enum.SendAddonMessageResult.AddOnMessageLockdown

    AssertFalse(Core:Send("U|1|642"), "enum 11 send result")
    AssertEqual(sendCalls, 1, "transport call count")
    AssertEqual(Core.communicationState, "blocked", "communication state")
    AssertEqual(Core.communicationReason, "lockdown", "communication reason")
end)

Test("sync diagnostic reports Blizzard lockdown instead of a sent test", function()
    ResetCore()
    chatLockdown = true
    outgoingRestricted = true
    sendResult = Enum.SendAddonMessageResult.AddOnMessageLockdown

    Core:PrintSyncStatus()
    local output = string.lower(table.concat(printed, "\n"))
    AssertContains(output, "bloqu", "lockdown diagnostic")
    AssertNotContains(output, "test envoyé", "false success diagnostic")
end)

Test("sync diagnostic explains enum 11 returned after a clear preflight", function()
    ResetCore()
    sendResult = Enum.SendAddonMessageResult.AddOnMessageLockdown

    Core:PrintSyncStatus()
    local output = string.lower(table.concat(printed, "\n"))
    AssertContains(output, "bloqu", "enum 11 diagnostic")
    AssertContains(output, "wow", "enum 11 source")
    AssertNotContains(output, "test envoyé", "false enum 11 success")
end)

Test("a successful send restores communication after lockdown", function()
    ResetCore()
    chatLockdown = true
    outgoingRestricted = true
    AssertFalse(Core:Send("H|1"), "blocked send")
    AssertEqual(Core.communicationState, "blocked", "blocked state")

    chatLockdown = false
    outgoingRestricted = false
    sendResult = Enum.SendAddonMessageResult.Success
    AssertTrue(Core:Send("H|1"), "recovery send")
    AssertEqual(Core.communicationState, "available", "recovered state")
end)

Test("remote tracking requires a recent synchronized peer", function()
    ResetCore()
    AssertTrue(Core:Send("H|1"), "communication setup")
    local remote = {
        guid = "Player-1-REMOTE",
        synced = true,
        source = "synced",
    }
    Core.rosterGUIDs[remote.guid] = true
    Core.peers[remote.guid] = { lastSeen = now }

    AssertTrue(Core:IsRemoteTrackingAvailable(remote), "recent peer")
    now = now + 46
    AssertFalse(Core:IsRemoteTrackingAvailable(remote), "stale peer")
    AssertEqual(Core:GetRemoteTrackingReason(remote), "stale", "stale reason")
end)

Test("peer diagnostics exclude stale addon peers", function()
    ResetCore()
    Core.rosterGUIDs["Player-1-REMOTE"] = true
    Core.peers["Player-1-REMOTE"] = { lastSeen = now }
    AssertEqual(Core:GetPeerCount(), 1, "recent peer count")

    now = now + 46
    AssertEqual(Core:GetPeerCount(), 0, "stale peer count")
end)

Test("missing lockdown helper APIs preserve compatible sending", function()
    ResetCore()
    local inLockdown = C_ChatInfo.InChatMessagingLockdown
    local outgoing = C_ChatInfo.AreOutgoingAddonChatMessagesRestricted
    C_ChatInfo.InChatMessagingLockdown = nil
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted = nil

    local ok, result = pcall(function()
        return Core:Send("H|1")
    end)

    C_ChatInfo.InChatMessagingLockdown = inLockdown
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted = outgoing
    AssertTrue(ok, "optional API guard")
    AssertTrue(result, "compatible send")
end)

local uiChunk = assert(loadfile("UI.lua"))
uiChunk("DungeonCooldowns", ns)
local UI = ns.UI

local function VisibilityWidget(initial)
    return {
        visible = initial == true,
        Show = function(self) self.visible = true end,
        Hide = function(self) self.visible = false end,
        SetShown = function(self, value) self.visible = value == true end,
    }
end

local function RemoteIcon(trackingAvailable)
    local icon = {
        timer = nil,
        remoteTrackingAvailable = trackingAvailable,
        cooldown = {
            cleared = false,
            Clear = function(self) self.cleared = true end,
            SetCooldown = function(self) self.cleared = false end,
        },
        texture = {
            desaturated = false,
            SetDesaturated = function(self, value) self.desaturated = value == true end,
        },
        ready = VisibilityWidget(false),
        unknown = VisibilityWidget(false),
        charges = { SetText = function() end },
    }
    return icon
end

Test("remote cooldown is unknown rather than ready when live tracking is blocked", function()
    local icon = RemoteIcon(false)
    UI:RefreshRemoteIcon(icon)

    AssertFalse(icon.ready.visible, "ready marker")
    AssertTrue(icon.unknown.visible, "unknown marker")
    AssertTrue(icon.texture.desaturated, "unknown icon desaturation")
    AssertTrue(icon.cooldown.cleared, "unknown cooldown swipe")
end)

Test("remote cooldown can still be ready when live tracking is available", function()
    local icon = RemoteIcon(true)
    UI:RefreshRemoteIcon(icon)

    AssertTrue(icon.ready.visible, "ready marker")
    AssertFalse(icon.unknown.visible, "unknown marker")
end)

Test("remote icon transitions to unknown when its peer becomes stale", function()
    ResetCore()
    AssertTrue(Core:Send("H|1"), "communication setup")
    local remote = {
        guid = "Player-1-REMOTE",
        synced = true,
        source = "synced",
    }
    Core.rosterGUIDs[remote.guid] = true
    Core.peers[remote.guid] = { lastSeen = now }
    local icon = RemoteIcon(true)
    icon.isLocal = false

    AssertTrue(type(UI.RefreshRemoteTrackingState) == "function", "tracking refresh helper")
    UI:RefreshRemoteTrackingState(icon, remote)
    AssertTrue(icon.remoteTrackingAvailable, "recent UI state")

    now = now + 46
    UI:RefreshRemoteTrackingState(icon)
    UI:RefreshRemoteIcon(icon)
    AssertFalse(icon.ready.visible, "stale ready marker")
    AssertTrue(icon.unknown.visible, "stale unknown marker")
end)

Test("local icon refresh clears a recycled remote unknown marker", function()
    local icon = RemoteIcon(false)
    icon.spellID = 642
    icon.unknown:Show()
    local previousSpellAPI = C_Spell
    C_Spell = {
        GetSpellCooldown = function() return nil end,
        GetSpellCharges = function() return nil end,
    }

    local ok, err = pcall(function()
        UI:RefreshLocalIcon(icon)
    end)

    C_Spell = previousSpellAPI
    AssertTrue(ok, "local refresh: " .. tostring(err))
    AssertFalse(icon.unknown.visible, "recycled unknown marker")
end)

Test("unknown remote spells remain visible when ready spells are hidden", function()
    ns.db = {
        showOffensive = true,
        showDefensive = true,
        showReady = false,
    }
    local data = { category = ns.CATEGORY_DEFENSIVE }
    AssertTrue(UI:ShouldIncludeSpell(642, data, false, nil, false), "unknown remote visibility")
end)

Test("hidden overlays are periodically reconsidered for newly unknown peers", function()
    local previousCombatLockdown = InCombatLockdown
    local previousIsDisplayActive = Core.IsDisplayActive
    local previousIsUnitFrameVisible = UI.IsUnitFrameVisible
    local previousRefreshOverlay = UI.RefreshOverlay
    local previousOverlays = UI.overlays
    local unitFrame = {}
    local overlay = {
        lastUnitFrameVisible = true,
        IsShown = function() return false end,
    }
    local refreshes = 0

    InCombatLockdown = function() return true end
    Core.IsDisplayActive = function() return true end
    Core.testMode = false
    UI.IsUnitFrameVisible = function() return true end
    UI.RefreshOverlay = function() refreshes = refreshes + 1 end
    UI.overlays = { [unitFrame] = overlay }
    UI.nextHiddenOverlayRefresh = nil

    local ok, err = pcall(function()
        UI:RefreshCooldowns()
    end)

    InCombatLockdown = previousCombatLockdown
    Core.IsDisplayActive = previousIsDisplayActive
    UI.IsUnitFrameVisible = previousIsUnitFrameVisible
    UI.RefreshOverlay = previousRefreshOverlay
    UI.overlays = previousOverlays
    AssertTrue(ok, "hidden overlay refresh: " .. tostring(err))
    AssertEqual(refreshes, 1, "hidden overlay refresh count")
end)

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
    os.exit(1)
end
