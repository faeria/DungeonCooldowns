local _, ns = ...

local Selector = {
    selectedClassID = nil,
    rows = {},
}
ns.CooldownSelector = Selector

local CLASS_SPECS = {
    [1] = { 71, 72, 73 },
    [2] = { 65, 66, 70 },
    [3] = { 253, 254, 255 },
    [4] = { 259, 260, 261 },
    [5] = { 256, 257, 258 },
    [6] = { 250, 251, 252 },
    [7] = { 262, 263, 264 },
    [8] = { 62, 63, 64 },
    [9] = { 265, 266, 267 },
    [10] = { 268, 269, 270 },
    [11] = { 102, 103, 104, 105 },
    [12] = { 577, 581, 1480 },
    [13] = { 1467, 1468, 1473 },
}

local function GetSpellName(spellID)
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    return info and info.name or ("Sort " .. spellID)
end

local function GetClassLabel(classID)
    local className = GetClassInfo and GetClassInfo(classID)
    return className or ("Classe " .. classID)
end

local function GetSpecLabel(specID)
    local _, name = GetSpecializationInfoByID(specID)
    return name or ("Spécialisation " .. specID)
end

local function GetClassSpellRows(classID)
    local result = {}
    for _, specID in ipairs(CLASS_SPECS[classID] or {}) do
        local spells = {}
        local seen = {}
        for _, spellID in ipairs(ns.spellsBySpec[specID] or {}) do
            local _, canonicalID = ns.GetSpellData(spellID)
            canonicalID = canonicalID or spellID
            if not seen[canonicalID] then
                seen[canonicalID] = true
                spells[#spells + 1] = canonicalID
            end
        end
        result[#result + 1] = { specID = specID, spells = spells }
    end
    return result
end

local function CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height or 24)
    button:SetText(text)
    return button
end

function Selector:RefreshCooldowns()
    ns.UI:RefreshAll()
end

function Selector:SetClassEnabled(enabled)
    for _, section in ipairs(GetClassSpellRows(self.selectedClassID)) do
        for _, spellID in ipairs(section.spells) do
            ns.SetSpellEnabled(spellID, enabled)
        end
    end
    self:RefreshRows()
    self:RefreshCooldowns()
end

function Selector:CreateRow(parent, index)
    local row = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    row:SetSize(430, 28)
    row:SetPoint("TOPLEFT", 4, -((index - 1) * 30))

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(22, 22)
    row.icon:SetPoint("LEFT", row, "LEFT", 30, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.label:SetJustifyH("LEFT")

    row:SetScript("OnClick", function(check)
        ns.SetSpellEnabled(check.spellID, check:GetChecked())
        Selector:RefreshCooldowns()
    end)
    self.rows[index] = row
    return row
end

function Selector:RefreshRows()
    if not self.frame then return end

    local index = 0
    for _, section in ipairs(GetClassSpellRows(self.selectedClassID)) do
        index = index + 1
        local header = self.rows[index] or self:CreateRow(self.scrollChild, index)
        header:Disable()
        if header:GetNormalTexture() then header:GetNormalTexture():SetAlpha(0) end
        if header:GetDisabledCheckedTexture() then header:GetDisabledCheckedTexture():SetAlpha(0) end
        header.icon:Hide()
        header.label:ClearAllPoints()
        header.label:SetPoint("LEFT", header, "LEFT", 6, 0)
        header.label:SetFontObject(GameFontNormalLarge)
        header.label:SetText(GetSpecLabel(section.specID))
        header.spellID = nil
        header:SetChecked(false)
        header:Show()

        for _, spellID in ipairs(section.spells) do
            index = index + 1
            local row = self.rows[index] or self:CreateRow(self.scrollChild, index)
            row:Enable()
            if row:GetNormalTexture() then row:GetNormalTexture():SetAlpha(1) end
            row.icon:Show()
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
            row.label:SetFontObject(GameFontHighlight)
            row.spellID = spellID
            row.label:SetText(GetSpellName(spellID))
            row.icon:SetTexture(C_Spell.GetSpellTexture(spellID) or 134400)
            row:SetChecked(ns.IsSpellEnabled(spellID))
            row:Show()
        end
    end

    for rowIndex = index + 1, #self.rows do
        self.rows[rowIndex]:Hide()
    end
    self.scrollChild:SetHeight(math.max(1, index * 30))
    self.title:SetText("Cooldowns — " .. GetClassLabel(self.selectedClassID))
end

function Selector:SelectClass(classID)
    self.selectedClassID = classID
    for id, button in pairs(self.classButtons) do
        button:SetEnabled(id ~= classID)
    end
    self:RefreshRows()
end

function Selector:Create()
    if self.frame then return end

    local frame = CreateFrame("Frame", "DungeonCooldownsSpellSelector", UIParent, "BackdropTemplate")
    frame:SetSize(620, 620)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    self.title = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 24, -48)
    hint:SetText("Les sorts décochés sont masqués pour tous les membres du groupe.")

    self.classButtons = {}
    for classID = 1, 13 do
        local button = CreateButton(frame, GetClassLabel(classID), 88, 22)
        local column = (classID - 1) % 6
        local line = math.floor((classID - 1) / 6)
        button:SetPoint("TOPLEFT", 24 + column * 94, -70 - line * 26)
        button:SetScript("OnClick", function() Selector:SelectClass(classID) end)
        self.classButtons[classID] = button
    end

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 24, -156)
    scroll:SetPoint("BOTTOMRIGHT", -46, 56)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(530)
    child:SetHeight(1)
    scroll:SetScrollChild(child)
    self.scrollChild = child

    local all = CreateButton(frame, "Tout sélectionner", 130)
    all:SetPoint("BOTTOMLEFT", 24, 20)
    all:SetScript("OnClick", function() Selector:SetClassEnabled(true) end)

    local none = CreateButton(frame, "Tout masquer", 110)
    none:SetPoint("LEFT", all, "RIGHT", 8, 0)
    none:SetScript("OnClick", function() Selector:SetClassEnabled(false) end)

    local preview = CreateButton(frame, "Aperçu 20 s", 110)
    preview:SetPoint("LEFT", none, "RIGHT", 8, 0)
    preview:SetScript("OnClick", function() ns.Core:StartTest() end)

    local done = CreateButton(frame, "Fermer", 90)
    done:SetPoint("BOTTOMRIGHT", -24, 20)
    done:SetScript("OnClick", function() frame:Hide() end)

    frame:SetScript("OnHide", function() Selector:RefreshCooldowns() end)
    frame:Hide()
    self.frame = frame
    table.insert(UISpecialFrames, frame:GetName())
end

function Selector:Open()
    if InCombatLockdown() then
        ns.Print("la sélection des cooldowns ne peut pas être ouverte en combat.")
        return
    end
    self:Create()
    self:SelectClass(self.selectedClassID or 1)
    self.frame:Show()
end
