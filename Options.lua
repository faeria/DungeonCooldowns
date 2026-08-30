local _, ns = ...

local Options = {
    settings = {},
}
ns.Options = Options

local SETTING_VARIABLES = {
    enabled = "DUNGEON_COOLDOWNS_ENABLED",
    showDefensive = "DUNGEON_COOLDOWNS_SHOW_DEFENSIVE",
    showOffensive = "DUNGEON_COOLDOWNS_SHOW_OFFENSIVE",
    showReady = "DUNGEON_COOLDOWNS_SHOW_READY",
    side = "DUNGEON_COOLDOWNS_SIDE",
    iconSize = "DUNGEON_COOLDOWNS_ICON_SIZE",
    maxPerCategory = "DUNGEON_COOLDOWNS_MAX_PER_CATEGORY",
}

local function ApplySetting(key)
    if key == "enabled" then
        ns.Core:UpdateActiveState()
    else
        ns.UI:ApplyLayout()
    end
end

function Options:RegisterSetting(key, variableType, label)
    local setting = Settings.RegisterAddOnSetting(
        self.category,
        SETTING_VARIABLES[key],
        key,
        DungeonCooldownsDB,
        variableType,
        label,
        ns.defaults[key]
    )

    setting:SetValueChangedCallback(function()
        ApplySetting(key)
    end)
    self.settings[key] = setting
    return setting
end

local function GetSideOptions()
    local container = Settings.CreateControlTextContainer()
    container:Add("RIGHT", "À droite")
    container:Add("LEFT", "À gauche")
    return container:GetData()
end

function Options:RegisterCategory()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        ns.Print("l’API des options Blizzard n’est pas disponible.")
        return
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("Dungeon Cooldowns")
    self.category = category
    self.categoryID = category:GetID()

    if CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Activation"))
    end

    local enabled = self:RegisterSetting("enabled", Settings.VarType.Boolean, "Activer l’addon")
    Settings.CreateCheckbox(category, enabled, "Active l’affichage uniquement dans les instances de groupe à cinq joueurs.")

    if CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Affichage"))
    end

    local defensive = self:RegisterSetting("showDefensive", Settings.VarType.Boolean, "Afficher les défensifs")
    Settings.CreateCheckbox(category, defensive, "Affiche la ligne bleue des temps de recharge défensifs.")

    local offensive = self:RegisterSetting("showOffensive", Settings.VarType.Boolean, "Afficher les offensifs")
    Settings.CreateCheckbox(category, offensive, "Affiche la ligne orange des temps de recharge offensifs.")

    local ready = self:RegisterSetting("showReady", Settings.VarType.Boolean, "Afficher aussi les CDs disponibles")
    Settings.CreateCheckbox(category, ready, "Conserve les icônes visibles quand leur temps de recharge est prêt.")

    local side = self:RegisterSetting("side", Settings.VarType.String, "Position à côté des cadres")
    Settings.CreateDropdown(category, side, GetSideOptions, "Place les icônes à gauche ou à droite des cadres de groupe Blizzard.")

    local iconSize = self:RegisterSetting("iconSize", Settings.VarType.Number, "Taille des icônes")
    local iconSizeOptions = Settings.CreateSliderOptions(14, 36, 1)
    iconSizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%d px", value)
    end)
    Settings.CreateSlider(category, iconSize, iconSizeOptions, "Définit la largeur et la hauteur de chaque icône.")

    local maxIcons = self:RegisterSetting("maxPerCategory", Settings.VarType.Number, "Icônes maximum par catégorie")
    local maxIconsOptions = Settings.CreateSliderOptions(1, 8, 1)
    maxIconsOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return tostring(value)
    end)
    Settings.CreateSlider(category, maxIcons, maxIconsOptions, "Limite séparément les défensifs et les offensifs affichés pour chaque joueur.")

    if CreateSettingsListSectionHeaderInitializer and CreateSettingsButtonInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Diagnostic"))

        local testButton = CreateSettingsButtonInitializer(
            "Aperçu des icônes",
            "Tester 20 s",
            function()
                ns.Core:StartTest()
            end,
            "Affiche un cadre de démonstration pendant vingt secondes.",
            true
        )
        layout:AddInitializer(testButton)

        local statusButton = CreateSettingsButtonInitializer(
            "État de l’addon",
            "Afficher dans le chat",
            function()
                ns.Core:PrintStatus()
            end,
            "Affiche le contexte actif et le mode de suivi distant utilisé.",
            true
        )
        layout:AddInitializer(statusButton)
    end

    Settings.RegisterAddOnCategory(category)
end

function Options:Open()
    if InCombatLockdown() then
        ns.Print("les options ne peuvent pas être ouvertes en combat.")
        return
    end
    if not self.categoryID then
        ns.Print("la catégorie d’options n’a pas pu être enregistrée.")
        return
    end
    Settings.OpenToCategory(self.categoryID)
end

function Options:Reset()
    for key, value in pairs(ns.defaults) do
        local setting = self.settings[key]
        if setting then
            setting:SetValue(value)
        else
            ns.db[key] = value
        end
    end
    ns.UI:ApplyLayout()
    ns.Core:UpdateActiveState()
    ns.Print("configuration réinitialisée.")
end

function Options:PrintHelp()
    ns.Print("/dcd — Options > AddOns > Dungeon Cooldowns")
    ns.Print("/dcd test — aperçu pendant 20 secondes")
    ns.Print("/dcd status — état et restrictions actives")
    ns.Print("/dcd reset — réinitialiser la configuration")
end

function Options:HandleSlash(message)
    local command = string.lower(strtrim(message or ""))
    if command == "" or command == "options" then
        self:Open()
    elseif command == "test" then
        ns.Core:StartTest()
    elseif command == "status" then
        ns.Core:PrintStatus()
    elseif command == "reset" then
        self:Reset()
    elseif command == "help" then
        self:PrintHelp()
    else
        self:PrintHelp()
    end
end

function Options:Initialize()
    self:RegisterCategory()

    SLASH_DUNGEONCOOLDOWNS1 = "/dcd"
    SLASH_DUNGEONCOOLDOWNS2 = "/dungeoncds"
    SlashCmdList.DUNGEONCOOLDOWNS = function(message)
        Options:HandleSlash(message)
    end
end
