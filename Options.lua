local _, ns = ...

local Options = { controls = {}, pages = {}, tabButtons = {}, activePage = "GENERAL" }
ns.Options = Options

local COLORS = {
    panel = { 0.018, 0.023, 0.032, 0.99 }, card = { 0.045, 0.055, 0.072, 0.98 },
    surface = { 0.032, 0.039, 0.052, 1 }, footer = { 0.024, 0.030, 0.041, 1 },
    border = { 0.14, 0.18, 0.24, 1 }, accent = { 0.08, 0.66, 0.94, 1 },
    accentHover = { 0.16, 0.72, 1.00, 1 }, muted = { 0.62, 0.67, 0.74 },
    success = { 0.13, 0.72, 0.40, 1 }, danger = { 0.82, 0.20, 0.24, 1 },
}

local function SetBackdrop(frame, background, border)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(background or COLORS.card))
    frame:SetBackdropBorderColor(unpack(border or COLORS.border))
end

local function CreateText(parent, text, font, anchor, relative, relativeAnchor, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint(anchor or "TOPLEFT", relative or parent, relativeAnchor or anchor or "TOPLEFT", x or 0, y or 0)
    label:SetText(text or "")
    return label
end

local function CreateButton(parent, text, width, height, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 150, height or 32)
    SetBackdrop(button, { 0.065, 0.080, 0.105, 1 }, COLORS.border)
    button.normalBackground = { 0.065, 0.080, 0.105, 1 }
    button.normalBorder = { unpack(COLORS.border) }
    function button:SetStyle(background, border)
        self.normalBackground = { unpack(background) }
        self.normalBorder = { unpack(border) }
        self:SetBackdropColor(unpack(self.normalBackground))
        self:SetBackdropBorderColor(unpack(self.normalBorder))
    end
    button.label = CreateText(button, text, "GameFontHighlightSmall", "CENTER")
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.14, 0.18, 0.24, 1)
        self:SetBackdropBorderColor(unpack(COLORS.accentHover))
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.normalBackground))
        self:SetBackdropBorderColor(unpack(self.normalBorder))
    end)
    button:SetScript("OnClick", callback)
    return button
end

local function CreateCloseButton(parent)
    local button = CreateButton(parent, "×", 28, 28, function(self) self:GetParent():Hide() end)
    button:SetPoint("TOPRIGHT", -14, -14)
    button.label:SetFontObject(GameFontNormalLarge)
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

local function CreateCard(parent, title, description, top, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", 0, top)
    card:SetPoint("TOPRIGHT", 0, top)
    card:SetHeight(height)
    SetBackdrop(card)
    local marker = card:CreateTexture(nil, "ARTWORK")
    marker:SetColorTexture(unpack(COLORS.accent))
    marker:SetPoint("TOPLEFT", 0, 0)
    marker:SetPoint("BOTTOMLEFT", 0, 0)
    marker:SetWidth(3)
    local titleText = CreateText(card, title, "GameFontNormalLarge", "TOPLEFT", card, "TOPLEFT", 18, -15)
    titleText:SetTextColor(0.88, 0.93, 0.98)
    if description then
        local info = CreateText(card, description, "GameFontHighlightSmall", "TOPLEFT", card, "TOPLEFT", 18, -39)
        info:SetTextColor(unpack(COLORS.muted))
    end
    return card
end

function Options:ApplyValue(key, value)
    ns.db[key] = value
    if key == "enabled" or key == "contentMode" then ns.Core:UpdateActiveState() else ns.UI:ApplyLayout() end
    self:RefreshControls()
end

function Options:CreateToggle(parent, key, label, description, x, y)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(500, 42)
    row:SetPoint("TOPLEFT", x, y)
    local box = CreateFrame("Frame", nil, row, "BackdropTemplate")
    box:SetSize(38, 20)
    box:SetPoint("LEFT")
    SetBackdrop(box, { 0.12, 0.13, 0.16, 1 }, COLORS.border)
    box.knob = box:CreateTexture(nil, "OVERLAY")
    box.knob:SetSize(14, 14)
    box.knob:SetColorTexture(0.82, 0.85, 0.89, 1)
    CreateText(row, label, "GameFontHighlight", "TOPLEFT", row, "TOPLEFT", 52, -4)
    if description then
        local info = CreateText(row, description, "GameFontHighlightSmall", "TOPLEFT", row, "TOPLEFT", 52, -23)
        info:SetTextColor(unpack(COLORS.muted))
    end
    function row:SetValue(value)
        self.value = value and true or false
        box.knob:ClearAllPoints()
        if self.value then
            box:SetBackdropColor(unpack(COLORS.success)); box:SetBackdropBorderColor(0.22, 0.92, 0.52, 1); box.knob:SetPoint("RIGHT", -3, 0)
        else
            box:SetBackdropColor(0.12, 0.13, 0.16, 1); box:SetBackdropBorderColor(unpack(COLORS.border)); box.knob:SetPoint("LEFT", 3, 0)
        end
    end
    row:SetScript("OnClick", function(self) Options:ApplyValue(key, not self.value) end)
    self.controls[key] = row
end

function Options:CreateCycle(parent, key, label, values, x, y, width)
    CreateText(parent, label, "GameFontHighlight", "TOPLEFT", parent, "TOPLEFT", x, y)
    local button = CreateButton(parent, "", width or 180, 30, function(self)
        local currentIndex = 1
        for index, option in ipairs(values) do if option.value == ns.db[key] then currentIndex = index break end end
        Options:ApplyValue(key, values[(currentIndex % #values) + 1].value)
    end)
    button:SetPoint("TOPLEFT", x, y - 23)
    button.values = values
    function button:SetValue(value)
        for _, option in ipairs(self.values) do if option.value == value then self.label:SetText(option.label) return end end
        self.label:SetText(tostring(value))
    end
    self.controls[key] = button
end

function Options:CreateSlider(parent, key, label, minimum, maximum, step, x, y, width, formatter)
    CreateText(parent, label, "GameFontHighlight", "TOPLEFT", parent, "TOPLEFT", x, y)
    local valueLabel = CreateText(parent, "", "GameFontNormal", "TOPRIGHT", parent, "TOPLEFT", x + width, y)
    valueLabel:SetTextColor(unpack(COLORS.accentHover))
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", x, y - 24)
    slider:SetSize(width, 8)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    SetBackdrop(slider, { 0.10, 0.12, 0.16, 1 }, { 0.14, 0.17, 0.22, 1 })
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(14, 18)
    thumb:SetColorTexture(unpack(COLORS.accent))
    slider.formatter, slider.valueLabel, slider.suppress = formatter or tostring, valueLabel, false
    function slider:SetDisplayValue(value)
        self.suppress = true; self:SetValue(value); self.valueLabel:SetText(self.formatter(value)); self.suppress = false
    end
    slider:SetScript("OnValueChanged", function(self, value)
        if self.suppress then return end
        local rounded = math.floor((value / step) + 0.5) * step
        self.valueLabel:SetText(self.formatter(rounded))
        Options:ApplyValue(key, rounded)
    end)
    self.controls[key] = slider
end

function Options:CreateGeneralPage(parent)
    local page = CreateFrame("Frame", nil, parent); page:SetAllPoints()
    local activation = CreateCard(page, "Activation", "Contrôle global de l’addon.", 0, 98)
    self:CreateToggle(activation, "enabled", "Activer Dungeon Cooldowns", "Active l’affichage selon la portée choisie.", 18, -48)
    local scope = CreateCard(page, "Portée", "Détermine où l’affichage réel est actif.", -108, 96)
    self:CreateCycle(scope, "contentMode", "Contenus pris en charge", {{value="DUNGEON",label="Donjons à 5 uniquement"},{value="PARTY",label="Solo ou groupe de 5"}}, 18, -42, 240)
    local display = CreateCard(page, "Affichage", "Cooldowns réunis dans une grille unique.", -214, 220)
    self:CreateToggle(display, "showDefensive", "Cooldowns défensifs", "Bordure bleue.", 18, -48)
    self:CreateToggle(display, "showOffensive", "Cooldowns offensifs", "Bordure orange.", 18, -88)
    self:CreateToggle(display, "showReady", "Afficher les sorts disponibles", "Conserve les icônes prêtes.", 18, -128)
    self:CreateSlider(display, "iconsPerRow", "Icônes par ligne", 1, 10, 1, 18, -174, 240, tostring)
    self:CreateSlider(display, "maxRows", "Nombre de lignes", 1, 5, 1, 304, -174, 240, tostring)
    return page
end

function Options:CreateAppearancePage(parent)
    local page = CreateFrame("Frame", nil, parent); page:SetAllPoints()
    local placement = CreateCard(page, "Position", "Placement précis autour des cadres de groupe.", 0, 186)
    self:CreateCycle(placement, "side", "Côté", {{value="LEFT",label="À gauche"},{value="RIGHT",label="À droite"}}, 18, -50, 240)
    self:CreateCycle(placement, "alignment", "Alignement vertical", {{value="TOP",label="Haut"},{value="CENTER",label="Centre"},{value="BOTTOM",label="Bas"}}, 304, -50, 240)
    self:CreateSlider(placement, "frameGap", "Distance", 0, 30, 1, 18, -116, 160, function(v) return string.format("%d px", v) end)
    self:CreateSlider(placement, "offsetX", "Décalage X", -100, 100, 1, 202, -116, 160, function(v) return string.format("%+d px", v) end)
    self:CreateSlider(placement, "offsetY", "Décalage Y", -100, 100, 1, 386, -116, 158, function(v) return string.format("%+d px", v) end)
    local icons = CreateCard(page, "Style des icônes", "Dimensions, espacements et bordures.", -196, 232)
    self:CreateSlider(icons, "iconSize", "Taille", 14, 40, 1, 18, -52, 160, function(v) return string.format("%d px", v) end)
    self:CreateSlider(icons, "spacing", "Espacement X", 0, 10, 1, 202, -52, 160, function(v) return string.format("%d px", v) end)
    self:CreateSlider(icons, "rowSpacing", "Espacement Y", 0, 12, 1, 386, -52, 158, function(v) return string.format("%d px", v) end)
    self:CreateSlider(icons, "iconAlpha", "Opacité", 0.30, 1, 0.05, 18, -120, 160, function(v) return string.format("%d %%", math.floor(v * 100 + 0.5)) end)
    self:CreateCycle(icons, "borderStyle", "Style de bordure", {{value="CATEGORY",label="Couleur de catégorie"},{value="DARK",label="Sombre"},{value="NONE",label="Aucune"}}, 202, -120, 160)
    self:CreateSlider(icons, "borderSize", "Épaisseur", 1, 4, 1, 386, -120, 158, function(v) return string.format("%d px", v) end)
    local tip = CreateText(icons, "Chaque modification est appliquée instantanément à l’aperçu.", "GameFontHighlightSmall", "BOTTOMLEFT", icons, "BOTTOMLEFT", 18, 16)
    tip:SetTextColor(unpack(COLORS.muted))
    return page
end

function Options:CreateSpellsPage(parent)
    local page = CreateFrame("Frame", nil, parent); page:SetAllPoints()
    local card = CreateCard(page, "Cooldowns suivis", "Sélection individuelle par classe et spécialisation.", 0, 220)
    local text = CreateText(card, "La sélection s’applique à votre personnage et à tous les membres du groupe. Les sorts masqués ne consomment aucune place dans l’affichage.", "GameFontHighlight", "TOPLEFT", card, "TOPLEFT", 18, -62)
    text:SetWidth(520); text:SetJustifyH("LEFT")
    local detail = CreateText(card, "13 classes  •  40 spécialisations  •  Choix sauvegardés automatiquement", "GameFontHighlightSmall", "TOPLEFT", card, "TOPLEFT", 18, -108)
    detail:SetTextColor(0.35, 0.82, 1)
    local open = CreateButton(card, "Configurer les sorts", 220, 36, function() ns.CooldownSelector:Open() end)
    open:SetPoint("BOTTOMLEFT", 18, 22)
    return page
end

function Options:SelectPage(pageID)
    self.activePage = pageID
    for id, page in pairs(self.pages) do page:SetShown(id == pageID) end
    for id, button in pairs(self.tabButtons) do
        if id == pageID then
            button:SetStyle({ 0.08, 0.32, 0.49, 1 }, COLORS.accent); button.label:SetTextColor(0.75, 0.93, 1, 1)
            if button.selectionBar then button.selectionBar:Show() end
        else
            button:SetStyle({ 0.045, 0.052, 0.068, 1 }, { 0.09, 0.11, 0.15, 1 }); button.label:SetTextColor(0.72, 0.75, 0.80, 1)
            if button.selectionBar then button.selectionBar:Hide() end
        end
    end
end

function Options:RefreshPreviewButton()
    if not self.previewButton then return end
    if ns.Core.testMode then
        self.previewButton.label:SetText("Désactiver l’aperçu"); self.previewButton:SetStyle({ 0.12, 0.46, 0.27, 1 }, COLORS.success)
    else
        self.previewButton.label:SetText("Activer l’aperçu"); self.previewButton:SetStyle({ 0.09, 0.11, 0.15, 1 }, COLORS.border)
    end
end

function Options:RefreshControls()
    if not ns.db then return end
    for key, control in pairs(self.controls) do
        local value = ns.db[key]
        if control.SetDisplayValue then control:SetDisplayValue(value) elseif control.SetValue then control:SetValue(value) end
    end
    self:RefreshPreviewButton()
end

function Options:Create()
    if self.frame then return end
    local frame = CreateFrame("Frame", "DungeonCooldownsConfig", UIParent, "BackdropTemplate")
    frame:SetSize(760, 560); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    SetBackdrop(frame, COLORS.panel, { 0.08, 0.48, 0.70, 1 }); self.frame = frame
    local topLine = frame:CreateTexture(nil, "OVERLAY"); topLine:SetColorTexture(unpack(COLORS.accent)); topLine:SetPoint("TOPLEFT", 1, -1); topLine:SetPoint("TOPRIGHT", -1, -1); topLine:SetHeight(3)
    local title = CreateText(frame, "DUNGEON COOLDOWNS", "GameFontNormalLarge", "TOPLEFT", frame, "TOPLEFT", 22, -19)
    title:SetTextColor(0.35, 0.82, 1, 1)
    local version = CreateText(frame, "v" .. ns.version, "GameFontHighlightSmall", "LEFT", title, "RIGHT", 10, 0); version:SetTextColor(unpack(COLORS.muted))
    local subtitle = CreateText(frame, "Configuration des cadres de groupe", "GameFontHighlightSmall", "TOPLEFT", frame, "TOPLEFT", 22, -41); subtitle:SetTextColor(unpack(COLORS.muted))
    CreateCloseButton(frame)
    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 18, -68); sidebar:SetPoint("BOTTOMLEFT", 18, 58); sidebar:SetWidth(140)
    SetBackdrop(sidebar, COLORS.surface, { 0.07, 0.09, 0.12, 1 })
    local tabs = {{"GENERAL","Général"},{"APPEARANCE","Apparence"},{"SPELLS","Sorts suivis"}}
    for index, data in ipairs(tabs) do
        local pageID, pageLabel = data[1], data[2]
        local button = CreateButton(sidebar, pageLabel, 116, 38, function() Options:SelectPage(pageID) end)
        button:SetPoint("TOPLEFT", 12, -12 - ((index - 1) * 46)); button.label:ClearAllPoints(); button.label:SetPoint("LEFT", 16, 0)
        button.selectionBar = button:CreateTexture(nil, "OVERLAY"); button.selectionBar:SetColorTexture(unpack(COLORS.accent)); button.selectionBar:SetPoint("TOPLEFT", 0, 0); button.selectionBar:SetPoint("BOTTOMLEFT", 0, 0); button.selectionBar:SetWidth(3); button.selectionBar:Hide()
        self.tabButtons[pageID] = button
    end
    local reset = CreateButton(sidebar, "Réinitialiser", 116, 32, function() Options:Reset() end); reset:SetPoint("BOTTOMLEFT", 12, 12)
    local content = CreateFrame("Frame", nil, frame); content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 16, 0); content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 58)
    self.pages.GENERAL = self:CreateGeneralPage(content); self.pages.APPEARANCE = self:CreateAppearancePage(content); self.pages.SPELLS = self:CreateSpellsPage(content)
    local footer = CreateFrame("Frame", nil, frame, "BackdropTemplate"); footer:SetPoint("BOTTOMLEFT", 1, 1); footer:SetPoint("BOTTOMRIGHT", -1, 1); footer:SetHeight(50); SetBackdrop(footer, COLORS.footer, { 0.07, 0.09, 0.12, 1 })
    local preview = CreateButton(frame, "Activer l’aperçu", 190, 36, function() ns.Core:ToggleTest(); Options:RefreshPreviewButton() end)
    preview:SetPoint("BOTTOMRIGHT", -116, 8); self.previewButton = preview
    local done = CreateButton(frame, "Fermer", 90, 36, function() frame:Hide() end); done:SetPoint("LEFT", preview, "RIGHT", 8, 0)
    frame:Hide(); table.insert(UISpecialFrames, frame:GetName()); self:SelectPage(self.activePage)
end

function Options:Open()
    if InCombatLockdown() then ns.Print("la configuration ne peut pas être ouverte en combat.") return end
    self:Create(); self:RefreshControls(); self.frame:Show()
end

function Options:Reset()
    for key, value in pairs(ns.defaults) do
        if type(value) == "table" then ns.db[key] = {}; for childKey, childValue in pairs(value) do ns.db[key][childKey] = childValue end else ns.db[key] = value end
    end
    ns.UI:ApplyLayout(); ns.Core:UpdateActiveState(); self:RefreshControls(); ns.Print("configuration réinitialisée.")
end

function Options:PrintHelp()
    ns.Print("/dcd — ouvrir l’interface de configuration")
    ns.Print("/dcd test — activer ou désactiver l’aperçu")
    ns.Print("/dcd status — état de l’addon")
    ns.Print("/dcd sync — tester la synchronisation du groupe")
    ns.Print("/dcd frames — cadres d’unité détectés")
    ns.Print("/dcd reset — réinitialiser la configuration")
end

function Options:HandleSlash(message)
    local command = string.lower(strtrim(message or ""))
    if command == "" or command == "options" then self:Open()
    elseif command == "test" or command == "preview" then ns.Core:ToggleTest()
    elseif command == "status" then ns.Core:PrintStatus()
    elseif command == "sync" then ns.Core:PrintSyncStatus()
    elseif command == "frames" then ns.Core:PrintDetectedFrames()
    elseif command == "reset" then self:Reset()
    else self:PrintHelp() end
end

function Options:Initialize()
    SLASH_DUNGEONCOOLDOWNS1 = "/dcd"; SLASH_DUNGEONCOOLDOWNS2 = "/dungeoncds"
    SlashCmdList.DUNGEONCOOLDOWNS = function(message) Options:HandleSlash(message) end
end
