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
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height or 24)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0.10, 0.11, 0.14, 0.96)
    button:SetBackdropBorderColor(0.26, 0.29, 0.35, 1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() then self:SetBackdropColor(0.18, 0.21, 0.27, 1) end
    end)
    button:SetScript("OnLeave", function(self)
        if self:IsEnabled() then self:SetBackdropColor(0.10, 0.11, 0.14, 0.96) end
    end)
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
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(610, 32)
    row:SetPoint("TOPLEFT", 2, -((index - 1) * 34))
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    row:SetBackdropColor(0.055, 0.06, 0.075, index % 2 == 0 and 0.88 or 0.58)

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(24, 24)
    row.check:SetPoint("LEFT", 5, 0)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(26, 26)
    row.icon:SetPoint("LEFT", row.check, "RIGHT", 5, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.label:SetJustifyH("LEFT")

    local function Toggle(check)
        if not row.spellID then return end
        if check ~= row.check then row.check:SetChecked(not row.check:GetChecked()) end
        ns.SetSpellEnabled(row.spellID, row.check:GetChecked())
        Selector:RefreshRows()
        Selector:RefreshCooldowns()
    end
    row.check:SetScript("OnClick", Toggle)
    row:SetScript("OnClick", Toggle)
    row:SetScript("OnEnter", function(self)
        if self.spellID then self:SetBackdropColor(0.14, 0.16, 0.20, 0.95) end
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.055, 0.06, 0.075, index % 2 == 0 and 0.88 or 0.58)
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
        header.check:Hide()
        header.icon:Hide()
        header.label:ClearAllPoints()
        header.label:SetPoint("LEFT", header, "LEFT", 6, 0)
        header.label:SetFontObject(GameFontNormalLarge)
        header.label:SetText(GetSpecLabel(section.specID))
        header.spellID = nil
        header:SetBackdropColor(0.08, 0.20, 0.30, 0.92)
        header:Show()

        for _, spellID in ipairs(section.spells) do
            index = index + 1
            local row = self.rows[index] or self:CreateRow(self.scrollChild, index)
            row:Enable()
            row.check:Show()
            row.icon:Show()
            row:SetBackdropColor(0.055, 0.06, 0.075, index % 2 == 0 and 0.88 or 0.58)
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
            row.label:SetFontObject(GameFontHighlight)
            row.spellID = spellID
            row.label:SetText(GetSpellName(spellID))
            row.icon:SetTexture(C_Spell.GetSpellTexture(spellID) or 134400)
            row.check:SetChecked(ns.IsSpellEnabled(spellID))
            row:Show()
        end
    end

    for rowIndex = index + 1, #self.rows do
        self.rows[rowIndex]:Hide()
    end
    self.scrollChild:SetHeight(math.max(1, index * 34))
    self.title:SetText("Cooldowns — " .. GetClassLabel(self.selectedClassID))
end

function Selector:SelectClass(classID)
    self.selectedClassID = classID
    for id, button in pairs(self.classButtons) do
        button:SetEnabled(id ~= classID)
        if id == classID then
            button:SetBackdropColor(0.08, 0.45, 0.70, 1)
            button:SetBackdropBorderColor(0.25, 0.78, 1, 1)
        else
            button:SetBackdropColor(0.10, 0.11, 0.14, 0.96)
            button:SetBackdropBorderColor(0.26, 0.29, 0.35, 1)
        end
    end
    self:RefreshRows()
end

function Selector:Create()
    if self.frame then return end

    local frame = CreateFrame("Frame", "DungeonCooldownsSpellSelector", UIParent, "BackdropTemplate")
    frame:SetSize(700, 650)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(0.025, 0.028, 0.038, 0.98)
    frame:SetBackdropBorderColor(0.12, 0.55, 0.82, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 24, -20)
    self.title = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 24, -48)
    hint:SetTextColor(0.68, 0.72, 0.78)
    hint:SetText("Les sorts décochés sont masqués pour tous les membres du groupe.")

    self.classButtons = {}
    for classID = 1, 13 do
        local buttonClassID = classID
        local button = CreateButton(frame, GetClassLabel(buttonClassID), 89, 25)
        local column = (classID - 1) % 7
        local line = math.floor((classID - 1) / 7)
        button:SetPoint("TOPLEFT", 24 + column * 93, -72 - line * 29)
        button:SetScript("OnClick", function() Selector:SelectClass(buttonClassID) end)
        self.classButtons[buttonClassID] = button
    end

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 24, -142)
    scroll:SetPoint("BOTTOMRIGHT", -46, 56)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(620)
    child:SetHeight(1)
    scroll:SetScrollChild(child)
    self.scrollChild = child

    local all = CreateButton(frame, "Tout sélectionner", 130)
    all:SetPoint("BOTTOMLEFT", 24, 20)
    all:SetScript("OnClick", function() Selector:SetClassEnabled(true) end)

    local none = CreateButton(frame, "Tout masquer", 110)
    none:SetPoint("LEFT", all, "RIGHT", 8, 0)
    none:SetScript("OnClick", function() Selector:SetClassEnabled(false) end)

    local preview = CreateButton(frame, "Activer / désactiver l’aperçu", 190)
    preview:SetPoint("LEFT", none, "RIGHT", 8, 0)
    preview:SetScript("OnClick", function() ns.Core:ToggleTest() end)

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
