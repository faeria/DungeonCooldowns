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

local COLORS = {
    panel = { 0.018, 0.023, 0.032, 0.995 },
    surface = { 0.032, 0.039, 0.052, 1 },
    row = { 0.045, 0.052, 0.066, 0.96 },
    rowAlt = { 0.055, 0.064, 0.081, 0.96 },
    border = { 0.14, 0.18, 0.24, 1 },
    accent = { 0.08, 0.66, 0.94, 1 },
    accentHover = { 0.18, 0.76, 1.00, 1 },
    muted = { 0.62, 0.67, 0.74 },
    success = { 0.13, 0.72, 0.40, 1 },
    danger = { 0.82, 0.20, 0.24, 1 },
}

local function SetBackdrop(frame, background, border, edgeSize)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = edgeSize or 1,
    })
    frame:SetBackdropColor(unpack(background or COLORS.surface))
    frame:SetBackdropBorderColor(unpack(border or COLORS.border))
end

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
    SetBackdrop(button, { 0.065, 0.080, 0.105, 1 }, COLORS.border)
    button.normalBackground = { 0.065, 0.080, 0.105, 1 }
    button.normalBorder = { unpack(COLORS.border) }
    function button:SetStyle(background, border)
        self.normalBackground = { unpack(background) }
        self.normalBorder = { unpack(border) }
        self:SetBackdropColor(unpack(background))
        self:SetBackdropBorderColor(unpack(border))
    end
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button:SetScript("OnEnter", function(self)
        if self:IsEnabled() then self:SetBackdropColor(0.12, 0.17, 0.22, 1); self:SetBackdropBorderColor(unpack(COLORS.accentHover)) end
    end)
    button:SetScript("OnLeave", function(self)
        if self:IsEnabled() then self:SetBackdropColor(unpack(self.normalBackground)); self:SetBackdropBorderColor(unpack(self.normalBorder)) end
    end)
    return button
end

local function CreateCloseButton(parent)
    local button = CreateButton(parent, "×", 28, 28)
    button:SetPoint("TOPRIGHT", -14, -14)
    button.label:SetFontObject(GameFontNormalLarge)
    button:SetScript("OnClick", function() parent:Hide() end)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.42, 0.07, 0.09, 1)
        self:SetBackdropBorderColor(unpack(COLORS.danger))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.normalBackground))
        self:SetBackdropBorderColor(unpack(self.normalBorder))
    end)
    return button
end

local function GetClassSelectionStats(classID)
    local enabled, total = 0, 0
    local seen = {}
    for _, section in ipairs(GetClassSpellRows(classID)) do
        for _, spellID in ipairs(section.spells) do
            if not seen[spellID] then
                seen[spellID] = true
                total = total + 1
                if ns.IsSpellEnabled(spellID) then enabled = enabled + 1 end
            end
        end
    end
    return enabled, total
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
    row:SetSize(650, 34)
    row:SetPoint("TOPLEFT", 0, -((index - 1) * 36))
    SetBackdrop(row, index % 2 == 0 and COLORS.rowAlt or COLORS.row, { 0.07, 0.09, 0.12, 1 })

    row.categoryStrip = row:CreateTexture(nil, "ARTWORK")
    row.categoryStrip:SetPoint("TOPLEFT", 0, -1)
    row.categoryStrip:SetPoint("BOTTOMLEFT", 0, 1)
    row.categoryStrip:SetWidth(3)

    row.check = CreateFrame("CheckButton", nil, row, "BackdropTemplate")
    row.check:SetSize(18, 18)
    row.check:SetPoint("LEFT", 10, 0)
    SetBackdrop(row.check, { 0.025, 0.030, 0.040, 1 }, COLORS.border)
    row.check.mark = row.check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.check.mark:SetPoint("CENTER", 0, 1)
    row.check.mark:SetText("✓")
    row.check.mark:SetTextColor(0.25, 1.00, 0.58)
    function row.check:RefreshVisual()
        self.mark:SetShown(self:GetChecked() == true)
        if self:GetChecked() then
            self:SetBackdropColor(0.04, 0.24, 0.15, 1)
            self:SetBackdropBorderColor(0.16, 0.78, 0.43, 1)
        else
            self:SetBackdropColor(0.025, 0.030, 0.040, 1)
            self:SetBackdropBorderColor(unpack(COLORS.border))
        end
    end

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(28, 28)
    row.icon:SetPoint("LEFT", row.check, "RIGHT", 8, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.label:SetJustifyH("LEFT")

    row.categoryLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.categoryLabel:SetPoint("RIGHT", -12, 0)

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
        if self.spellID then self:SetBackdropColor(0.10, 0.13, 0.17, 1); self:SetBackdropBorderColor(0.10, 0.45, 0.64, 1) end
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(index % 2 == 0 and COLORS.rowAlt or COLORS.row))
        self:SetBackdropBorderColor(0.07, 0.09, 0.12, 1)
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
        header.categoryStrip:Show()
        header.categoryStrip:SetColorTexture(unpack(COLORS.accent))
        header.categoryLabel:Hide()
        header.label:ClearAllPoints()
        header.label:SetPoint("LEFT", header, "LEFT", 14, 0)
        header.label:SetFontObject(GameFontNormalLarge)
        header.label:SetText(GetSpecLabel(section.specID))
        header.spellID = nil
        header:SetBackdropColor(0.045, 0.12, 0.17, 1)
        header:SetBackdropBorderColor(0.08, 0.30, 0.42, 1)
        header:Show()

        for _, spellID in ipairs(section.spells) do
            index = index + 1
            local row = self.rows[index] or self:CreateRow(self.scrollChild, index)
            row:Enable()
            row.check:Show()
            row.icon:Show()
            row.categoryStrip:Show()
            row.categoryLabel:Show()
            row:SetBackdropColor(unpack(index % 2 == 0 and COLORS.rowAlt or COLORS.row))
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
            row.label:SetFontObject(GameFontHighlight)
            row.spellID = spellID
            row.label:SetText(GetSpellName(spellID))
            row.icon:SetTexture(C_Spell.GetSpellTexture(spellID) or 134400)
            row.check:SetChecked(ns.IsSpellEnabled(spellID))
            row.check:RefreshVisual()
            local data = ns.GetSpellData(spellID)
            if data and data.category == ns.CATEGORY_DEFENSIVE then
                row.categoryStrip:SetColorTexture(0.12, 0.70, 1.00, 1)
                row.categoryLabel:SetText("DÉFENSIF")
                row.categoryLabel:SetTextColor(0.35, 0.82, 1.00)
            else
                row.categoryStrip:SetColorTexture(1.00, 0.42, 0.08, 1)
                row.categoryLabel:SetText("OFFENSIF")
                row.categoryLabel:SetTextColor(1.00, 0.60, 0.28)
            end
            row:Show()
        end
    end

    for rowIndex = index + 1, #self.rows do
        self.rows[rowIndex]:Hide()
    end
    self.scrollChild:SetHeight(math.max(1, index * 36))
    self.classTitle:SetText(GetClassLabel(self.selectedClassID))
    local enabled, total = GetClassSelectionStats(self.selectedClassID)
    self.counter:SetText(string.format("%d / %d sorts affichés", enabled, total))
end

function Selector:SelectClass(classID)
    self.selectedClassID = classID
    for id, button in pairs(self.classButtons) do
        button:SetEnabled(id ~= classID)
        if id == classID then
            button:SetStyle({ 0.06, 0.38, 0.58, 1 }, COLORS.accent)
            button.label:SetTextColor(0.78, 0.94, 1.00)
        else
            button:SetStyle({ 0.065, 0.080, 0.105, 1 }, COLORS.border)
            button.label:SetTextColor(0.82, 0.85, 0.90)
        end
    end
    self:RefreshRows()
end

function Selector:Create()
    if self.frame then return end

    local frame = CreateFrame("Frame", "DungeonCooldownsSpellSelector", UIParent, "BackdropTemplate")
    frame:SetSize(760, 560)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    SetBackdrop(frame, COLORS.panel, { 0.08, 0.48, 0.70, 1 })
    local topLine = frame:CreateTexture(nil, "OVERLAY")
    topLine:SetColorTexture(unpack(COLORS.accent))
    topLine:SetPoint("TOPLEFT", 1, -1)
    topLine:SetPoint("TOPRIGHT", -1, -1)
    topLine:SetHeight(3)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 22, -19)
    title:SetText("SÉLECTION DES COOLDOWNS")
    title:SetTextColor(0.35, 0.82, 1.00)

    CreateCloseButton(frame)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 22, -42)
    hint:SetTextColor(unpack(COLORS.muted))
    hint:SetText("Les sorts décochés sont masqués pour tous les membres du groupe.")

    self.classTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.classTitle:SetPoint("TOPRIGHT", -52, -19)
    self.classTitle:SetTextColor(0.92, 0.94, 0.98)

    self.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.counter:SetPoint("RIGHT", self.classTitle, "LEFT", -12, 0)
    self.counter:SetTextColor(unpack(COLORS.muted))

    self.classButtons = {}
    for classID = 1, 13 do
        local buttonClassID = classID
        local button = CreateButton(frame, GetClassLabel(buttonClassID), 98, 26)
        local column = (classID - 1) % 7
        local line = math.floor((classID - 1) / 7)
        button:SetPoint("TOPLEFT", 22 + column * 102, -68 - line * 30)
        button:SetScript("OnClick", function() Selector:SelectClass(buttonClassID) end)
        self.classButtons[buttonClassID] = button
    end

    local listPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    listPanel:SetPoint("TOPLEFT", 22, -136)
    listPanel:SetPoint("BOTTOMRIGHT", -22, 58)
    SetBackdrop(listPanel, COLORS.surface, { 0.08, 0.12, 0.16, 1 })

    local scroll = CreateFrame("ScrollFrame", nil, listPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(650)
    child:SetHeight(1)
    scroll:SetScrollChild(child)
    self.scrollChild = child

    local footer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", 1, 1)
    footer:SetPoint("BOTTOMRIGHT", -1, 1)
    footer:SetHeight(50)
    SetBackdrop(footer, { 0.024, 0.030, 0.041, 1 }, { 0.07, 0.09, 0.12, 1 })

    local all = CreateButton(frame, "Tout sélectionner", 130, 32)
    all:SetPoint("BOTTOMLEFT", 18, 10)
    all:SetScript("OnClick", function() Selector:SetClassEnabled(true) end)

    local none = CreateButton(frame, "Tout masquer", 110, 32)
    none:SetPoint("LEFT", all, "RIGHT", 8, 0)
    none:SetScript("OnClick", function() Selector:SetClassEnabled(false) end)

    local preview = CreateButton(frame, "Activer l’aperçu", 170, 32)
    preview:SetPoint("LEFT", none, "RIGHT", 8, 0)
    preview:SetScript("OnClick", function() ns.Core:ToggleTest(); Selector:RefreshPreviewButton() end)
    self.previewButton = preview

    local done = CreateButton(frame, "Retour aux options", 140, 32)
    done:SetPoint("BOTTOMRIGHT", -18, 10)
    done:SetScript("OnClick", function() frame:Hide() end)

    frame:SetScript("OnHide", function()
        Selector:RefreshCooldowns()
        if Selector.returnToOptions and ns.Options and ns.Options.frame then
            Selector.returnToOptions = nil
            ns.Options.frame:Show()
            ns.Options:SelectPage("SPELLS")
        end
    end)
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
    self.returnToOptions = ns.Options and ns.Options.frame and ns.Options.frame:IsShown() or false
    if self.returnToOptions then ns.Options.frame:Hide() end
    self:SelectClass(self.selectedClassID or 1)
    self:RefreshPreviewButton()
    self.frame:Show()
end

function Selector:RefreshPreviewButton()
    if not self.previewButton then return end
    if ns.Core.testMode then
        self.previewButton.label:SetText("Désactiver l’aperçu")
        self.previewButton:SetStyle({ 0.10, 0.42, 0.25, 1 }, COLORS.success)
    else
        self.previewButton.label:SetText("Activer l’aperçu")
        self.previewButton:SetStyle({ 0.065, 0.080, 0.105, 1 }, COLORS.border)
    end
end
