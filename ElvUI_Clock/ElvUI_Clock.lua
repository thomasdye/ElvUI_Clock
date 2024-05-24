TimeDisplayAddon = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    TimeDisplayAddon[event](TimeDisplayAddon, ...)
end)

function TimeDisplayAddon:PLAYER_LOGIN()
    self:SetDefaults()

    -- Initialize ElvUI
    if not IsAddOnLoaded("ElvUI") then
        print("ElvUI is not loaded.")
        return
    end

    local E, C, L, DB = unpack(ElvUI)
    print("ElvUI initialized:", E, C, L, DB)

    local classColor = E:ClassColor(E.myclass, true)

    -- Create the main frame
    local frame = CreateFrame("Frame", "TimeDisplayFrame", UIParent)
    frame:SetSize(WindowWidth or 75, 25)  -- Use WindowWidth for the width
    frame:SetTemplate("Transparent")

    -- Set the frame position from saved variables
    if FramePosition then
        frame:SetPoint(FramePosition.point, FramePosition.relativeTo, FramePosition.relativePoint, FramePosition.xOfs, FramePosition.yOfs)
    else
        frame:SetPoint("CENTER")
    end

    frame:Show()

    -- Enable dragging
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    -- Create a flag to detect dragging
    local isDragging = false

    frame:SetScript("OnDragStart", function(self)
        isDragging = true
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        isDragging = false
        self:StopMovingOrSizing()

        -- Save the new position
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        FramePosition = { point = point, relativeTo = relativeTo and relativeTo:GetName() or "UIParent", relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
    end)

    -- Create the top border texture
    local windowBorder = frame:CreateTexture(nil, "OVERLAY")
    windowBorder:SetHeight(3)

    local function UpdateBorderColor()
        if ColorChoice == "Class Color" then
            windowBorder:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.8)
        elseif ColorChoice == "Blue" then
            windowBorder:SetColorTexture(0, 0, 1, 0.8)
        elseif ColorChoice == "Red" then
            windowBorder:SetColorTexture(1, 0, 0, 0.8)
        elseif ColorChoice == "Green" then
            windowBorder:SetColorTexture(0, 1, 0, 0.8)
        elseif ColorChoice == "Pink" then
            windowBorder:SetColorTexture(1, 0, 1, 0.8)
        elseif ColorChoice == "Cyan" then
            windowBorder:SetColorTexture(0, 1, 1, 0.8)
        elseif ColorChoice == "Yellow" then
            windowBorder:SetColorTexture(1, 1, 0, 0.8)
        else
            windowBorder:SetColorTexture(0, 0, 0, 0)  -- Make it transparent
        end
    end

    -- Function to update the border position
    local function UpdateBorderPosition()
        windowBorder:ClearAllPoints()
        if BorderPosition == "TOP" then
            windowBorder:SetPoint("TOPLEFT", frame, "TOPLEFT")
            windowBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
        elseif BorderPosition == "RIGHT" then
            windowBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
            windowBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
        elseif BorderPosition == "BOTTOM" then
            windowBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
            windowBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
        elseif BorderPosition == "LEFT" then
            windowBorder:SetPoint("TOPLEFT", frame, "TOPLEFT")
            windowBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
        end
    end

    UpdateBorderColor()
    UpdateBorderPosition()

    -- Function to cycle through border positions
    local function CycleBorderPosition()
        if BorderPosition == "TOP" then
            BorderPosition = "RIGHT"
        elseif BorderPosition == "RIGHT" then
            BorderPosition = "BOTTOM"
        elseif BorderPosition == "BOTTOM" then
            BorderPosition = "LEFT"
        elseif BorderPosition == "LEFT" then
            BorderPosition = "TOP"
        end
        UpdateBorderPosition()
    end

    -- Function to get the time format
    local function GetTimeFormat()
        if Use24HourTime then
            return "%H:%M"
        else
            return "%I:%M %p"
        end
    end

    -- Create the text element using ElvUI's FontString function
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    text:FontTemplate(nil, 12, "OUTLINE")  -- Slightly smaller font size

    -- Update the time display immediately
    text:SetText(date(GetTimeFormat()))

    -- Update the time every second
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
        if self.timeSinceLastUpdate >= 1 then
            text:SetText(date(GetTimeFormat()))
            self.timeSinceLastUpdate = 0
        end
    end)

    -- Function to create a new window displaying current settings
    local function CreateSettingsWindow()
        local settingsFrame = CreateFrame("Frame", "SettingsFrame", UIParent)
        settingsFrame:SetSize(250, 300)  -- Adjust size to accommodate the slider
        settingsFrame:SetTemplate("Transparent")

        -- Set the frame position from saved variables
        if SettingsFramePosition then
            settingsFrame:SetPoint(SettingsFramePosition.point, SettingsFramePosition.relativeTo, SettingsFramePosition.relativePoint, SettingsFramePosition.xOfs, SettingsFramePosition.yOfs)
        else
            settingsFrame:SetPoint("CENTER")
        end

        -- Enable dragging
        settingsFrame:EnableMouse(true)
        settingsFrame:SetMovable(true)
        settingsFrame:RegisterForDrag("LeftButton")

        settingsFrame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)

        settingsFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()

            -- Save the new position
            local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
            SettingsFramePosition = { point = point, relativeTo = relativeTo and relativeTo:GetName() or "UIParent", relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
        end)

        -- Create close button
        local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT")
        closeButton:SetScript("OnClick", function()
            settingsFrame:Hide()
        end)

        -- Create top border for settings frame
        local settingsBorder = settingsFrame:CreateTexture(nil, "OVERLAY")
        settingsBorder:SetHeight(3)
        settingsBorder:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT")
        settingsBorder:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT")

        -- Function to update the settings border color
        local function UpdateSettingsBorderColor()
            if ColorChoice == "Class Color" then
                settingsBorder:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.8)
            elseif ColorChoice == "Blue" then
                settingsBorder:SetColorTexture(0, 0, 1, 0.8)
            elseif ColorChoice == "Red" then
                settingsBorder:SetColorTexture(1, 0, 0, 0.8)
            elseif ColorChoice == "Green" then
                settingsBorder:SetColorTexture(0, 1, 0, 0.8)
            elseif ColorChoice == "Pink" then
                settingsBorder:SetColorTexture(1, 0, 1, 0.8)
            elseif ColorChoice == "Cyan" then
                settingsBorder:SetColorTexture(0, 1, 1, 0.8)
            elseif ColorChoice == "Yellow" then
                settingsBorder:SetColorTexture(1, 1, 0, 0.8)
            else
                settingsBorder:SetColorTexture(0, 0, 0, 0)  -- Make it transparent
            end
        end

        UpdateSettingsBorderColor()

        -- Create title for settings frame
        local title = settingsFrame:CreateFontString(nil, "OVERLAY")
        title:SetPoint("TOP", settingsFrame, "TOP", 0, -10)
        title:FontTemplate(nil, 14, "OUTLINE")
        title:SetText("ElvUI Clock Settings")

        -- Create checkbox for 24 Hour Time
        local checkbox = CreateFrame("CheckButton", nil, settingsFrame, "ChatConfigCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -40)
        checkbox:SetChecked(Use24HourTime)
        checkbox:SetScript("OnClick", function(self)
            Use24HourTime = self:GetChecked()
            text:SetText(date(GetTimeFormat()))  -- Update the time display immediately
        end)

        -- Create text label for checkbox
        local checkboxLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
        checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkboxLabel:FontTemplate(nil, 12, "OUTLINE")
        checkboxLabel:SetText("24 Hour")

        -- Create dropdown for Border Position
        local dropdown = CreateFrame("Frame", "BorderPositionDropdown", settingsFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -9, -70)

        local function OnClick(self)
            UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
            BorderPosition = self.value
            UpdateBorderPosition()
        end

        local function Initialize(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local positions = {"TOP", "RIGHT", "BOTTOM", "LEFT"}

            for k, v in pairs(positions) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.value = v
                info.func = OnClick
                info.checked = (v == BorderPosition)
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(dropdown, Initialize)
        UIDropDownMenu_SetWidth(dropdown, 100)
        UIDropDownMenu_SetButtonWidth(dropdown, 124)
        UIDropDownMenu_SetSelectedID(dropdown, 1)
        UIDropDownMenu_JustifyText(dropdown, "LEFT")

        -- Set the selected value based on current BorderPosition
        local positions = {"TOP", "RIGHT", "BOTTOM", "LEFT"}
        for i, pos in ipairs(positions) do
            if pos == BorderPosition then
                UIDropDownMenu_SetSelectedID(dropdown, i)
                break
            end
        end

        -- Create text label for dropdown
        local dropdownLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
        dropdownLabel:SetPoint("LEFT", dropdown, "RIGHT", -7, 0)
        dropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        dropdownLabel:SetText("Border")

        -- Create dropdown for Color Choice
        local colorDropdown = CreateFrame("Frame", "ColorChoiceDropdown", settingsFrame, "UIDropDownMenuTemplate")
        colorDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -9, -110)

        local function OnColorClick(self)
            UIDropDownMenu_SetSelectedID(colorDropdown, self:GetID())
            ColorChoice = self.value
            UpdateBorderColor()
            UpdateSettingsBorderColor()
        end

        local function InitializeColorDropdown(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local colors = {"Class Color", "Blue", "Red", "Green", "Pink", "Cyan", "Yellow", "None"}

            for k, v in pairs(colors) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.value = v
                info.func = OnColorClick
                info.checked = (v == ColorChoice)
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(colorDropdown, InitializeColorDropdown)
        UIDropDownMenu_SetWidth(colorDropdown, 100)
        UIDropDownMenu_SetButtonWidth(colorDropdown, 124)
        UIDropDownMenu_SetSelectedID(colorDropdown, 1)
        UIDropDownMenu_JustifyText(colorDropdown, "LEFT")

        -- Set the selected value based on current ColorChoice
        local colors = {"Class Color", "Blue", "Red", "Green", "Pink", "Cyan", "Yellow", "None"}
        for i, color in ipairs(colors) do
            if color == ColorChoice then
                UIDropDownMenu_SetSelectedID(colorDropdown, i)
                break
            end
        end

        -- Create text label for color dropdown
        local colorDropdownLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
        colorDropdownLabel:SetPoint("LEFT", colorDropdown, "RIGHT", -7, 0)
        colorDropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        colorDropdownLabel:SetText("Color")

        -- Create dropdown for Left Click Functionality
        local leftClickDropdown = CreateFrame("Frame", "LeftClickDropdown", settingsFrame, "UIDropDownMenuTemplate")
        leftClickDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -9, -150)

        local function OnLeftClickOptionSelected(self)
            UIDropDownMenu_SetSelectedID(leftClickDropdown, self:GetID())
            LeftClickFunctionality = self.value
        end

        local function InitializeLeftClickDropdown(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local options = {"Calendar", "Friends", "Character", "Spellbook", "Talents", "Achievements", "Quests", "Guild", "Dungeon Finder", "Raid Finder", "Collections", "Shop", "Stopwatch", "None"}

            for k, v in pairs(options) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.value = v
                info.func = OnLeftClickOptionSelected
                info.checked = (v == LeftClickFunctionality)
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(leftClickDropdown, InitializeLeftClickDropdown)
        UIDropDownMenu_SetWidth(leftClickDropdown, 100)
        UIDropDownMenu_SetButtonWidth(leftClickDropdown, 124)
        UIDropDownMenu_SetSelectedID(leftClickDropdown, 1)
        UIDropDownMenu_JustifyText(leftClickDropdown, "LEFT")

        -- Set the selected value based on current LeftClickFunctionality
        local options = {"Calendar", "Friends", "Character", "Spellbook", "Talents", "Achievements", "Quests", "Guild", "Dungeon Finder", "Raid Finder", "Collections", "Shop", "Stopwatch", "None"}
        for i, option in ipairs(options) do
            if option == LeftClickFunctionality then
                UIDropDownMenu_SetSelectedID(leftClickDropdown, i)
                break
            end
        end

        -- Create text label for left click dropdown
        local leftClickDropdownLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
        leftClickDropdownLabel:SetPoint("LEFT", leftClickDropdown, "RIGHT", -7, 0)
        leftClickDropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        leftClickDropdownLabel:SetText("Left Click")

        -- Create dropdown for Right Click Functionality
        local rightClickDropdown = CreateFrame("Frame", "RightClickDropdown", settingsFrame, "UIDropDownMenuTemplate")
        rightClickDropdown:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", -9, -190)

        local function OnRightClickOptionSelected(self)
            UIDropDownMenu_SetSelectedID(rightClickDropdown, self:GetID())
            RightClickFunctionality = self.value
        end

        local function InitializeRightClickDropdown(self, level)
            local info = UIDropDownMenu_CreateInfo()
            local options = {"Calendar", "Friends", "Character", "Spellbook", "Talents", "Achievements", "Quests", "Guild", "Dungeon Finder", "Raid Finder", "Collections", "Shop", "Stopwatch", "None"}

            for k, v in pairs(options) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.value = v
                info.func = OnRightClickOptionSelected
                info.checked = (v == RightClickFunctionality)
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(rightClickDropdown, InitializeRightClickDropdown)
        UIDropDownMenu_SetWidth(rightClickDropdown, 100)
        UIDropDownMenu_SetButtonWidth(rightClickDropdown, 124)
        UIDropDownMenu_SetSelectedID(rightClickDropdown, 1)
        UIDropDownMenu_JustifyText(rightClickDropdown, "LEFT")

        -- Set the selected value based on current RightClickFunctionality
        for i, option in ipairs(options) do
            if option == RightClickFunctionality then
                UIDropDownMenu_SetSelectedID(rightClickDropdown, i)
                break
            end
        end

        -- Create text label for right click dropdown
        local rightClickDropdownLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
        rightClickDropdownLabel:SetPoint("LEFT", rightClickDropdown, "RIGHT", -7, 0)
        rightClickDropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        rightClickDropdownLabel:SetText("Right Click")

        -- Create slider for Window Width
        local slider = CreateFrame("Slider", "WindowWidthSlider", settingsFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -230)
        slider:SetMinMaxValues(75, 200)
        slider:SetValueStep(1)
        slider:SetValue(WindowWidth)
        slider:SetScript("OnValueChanged", function(self, value)
            WindowWidth = value
            frame:SetWidth(value)  -- Adjust the frame width
        end)

        -- Create text label for slider
        local sliderLabel = settingsFrame:CreateFontString(nil, "OVERLAY")
        sliderLabel:SetPoint("LEFT", slider, "RIGHT", 10, 0)
        sliderLabel:FontTemplate(nil, 12, "OUTLINE")
        sliderLabel:SetText("Window Width")

        settingsFrame:Show()
    end

    -- Left-click to perform selected functionality, shift + left-click to toggle border position
    -- Right-click to perform selected functionality, shift + right-click to toggle time format
    -- Ctrl + left-click to create a settings window
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = false
        end
    end)

    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and not isDragging then
            if IsShiftKeyDown() then
                CycleBorderPosition()
            elseif IsControlKeyDown() then
                CreateSettingsWindow()
            else
                if LeftClickFunctionality == "Friends" then
                    ToggleFriendsFrame(1)
                elseif LeftClickFunctionality == "Character" then
                    ToggleCharacter("PaperDollFrame")
                elseif LeftClickFunctionality == "Spellbook" then
                    ToggleSpellBook(BOOKTYPE_SPELL)
                elseif LeftClickFunctionality == "Talents" then
                    ToggleTalentFrame()
                elseif LeftClickFunctionality == "Achievements" then
                    ToggleAchievementFrame()
                elseif LeftClickFunctionality == "Quests" then
                    ToggleQuestLog()
                elseif LeftClickFunctionality == "Guild" then
                    ToggleGuildFrame()
                elseif LeftClickFunctionality == "Dungeon Finder" then
                    PVEFrame_ToggleFrame()
                elseif LeftClickFunctionality == "Raid Finder" then
                    ToggleRaidFrame()
                elseif LeftClickFunctionality == "Collections" then
                    ToggleCollectionsJournal()
                elseif LeftClickFunctionality == "Shop" then
                    ToggleStoreUI()
                elseif LeftClickFunctionality == "Stopwatch" then
                    Stopwatch_Toggle()
                elseif LeftClickFunctionality == "None" then
                    -- Do nothing
                else
                    if not IsAddOnLoaded("Blizzard_Calendar") then
                        UIParentLoadAddOn("Blizzard_Calendar")
                    end
                    if Calendar_Toggle then
                        Calendar_Toggle()
                    end
                end
            end
        elseif button == "RightButton" then
            if IsShiftKeyDown() then
                Use24HourTime = not Use24HourTime  -- Toggle the time format
                text:SetText(date(GetTimeFormat()))  -- Update the time display immediately
            else
                if RightClickFunctionality == "Friends" then
                    ToggleFriendsFrame(1)
                elseif RightClickFunctionality == "Character" then
                    ToggleCharacter("PaperDollFrame")
                elseif RightClickFunctionality == "Spellbook" then
                    ToggleSpellBook(BOOKTYPE_SPELL)
                elseif RightClickFunctionality == "Talents" then
                    ToggleTalentFrame()
                elseif RightClickFunctionality == "Achievements" then
                    ToggleAchievementFrame()
                elseif RightClickFunctionality == "Quests" then
                    ToggleQuestLog()
                elseif RightClickFunctionality == "Guild" then
                    ToggleGuildFrame()
                elseif RightClickFunctionality == "Dungeon Finder" then
                    PVEFrame_ToggleFrame()
                elseif RightClickFunctionality == "Raid Finder" then
                    ToggleRaidFrame()
                elseif RightClickFunctionality == "Collections" then
                    ToggleCollectionsJournal()
                elseif RightClickFunctionality == "Shop" then
                    ToggleStoreUI()
                elseif RightClickFunctionality == "Stopwatch" then
                    Stopwatch_Toggle()
                elseif RightClickFunctionality == "None" then
                    -- Do nothing
                end
            end
        end
    end)

    -- Show tooltip on mouseover, centered at the bottom of clock window frame
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -5)
        GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -10)
        GameTooltip:AddLine("Time Display")
        GameTooltip:AddLine("Left-click: Perform Selected Action", 1, 1, 1)
        GameTooltip:AddLine("Shift + Left-click: Toggle Border Position", 1, 1, 1)
        GameTooltip:AddLine("Ctrl + Left-click: Show Settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Perform Selected Action or Open Stopwatch", 1, 1, 1)
        GameTooltip:AddLine("Shift + Right-click: Toggle Time Format", 1, 1, 1)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

function TimeDisplayAddon:SetDefaults()
    if Use24HourTime == nil then
        print('setting use 24 hour time to false')
        Use24HourTime = false  -- Default to 12-hour format
    end

    if BorderPosition == nil then
        print('setting border position to top')
        BorderPosition = "TOP"  -- Default border position
    end

    if FramePosition == nil then
        FramePosition = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", xOfs = 0, yOfs = 0 }
    end

    if SettingsFramePosition == nil then
        SettingsFramePosition = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", xOfs = 0, yOfs = 0 }
    end

    if ColorChoice == nil then
        print('setting color choice to class color')
        ColorChoice = "Class Color"
    end

    if LeftClickFunctionality == nil then
        print('setting left click functionality to calendar')
        LeftClickFunctionality = "Calendar"
    end

    if RightClickFunctionality == nil then
        print('setting right click functionality to stopwatch')
        RightClickFunctionality = "Stopwatch"
    end

    if WindowWidth == nil then
        print('setting window width to 75')
        WindowWidth = 75  -- Default window width
    end
end
