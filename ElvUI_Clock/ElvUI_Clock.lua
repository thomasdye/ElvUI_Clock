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
    frame:SetSize(75, 25)  -- Slightly smaller size
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
    windowBorder:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.8) -- Set the class color

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
    -- Function to create a new window displaying current settings
local function CreateSettingsWindow()
    local settingsFrame = CreateFrame("Frame", "SettingsFrame", UIParent)
    settingsFrame:SetSize(250, 200)
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
    settingsBorder:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.8)
    settingsBorder:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT")
    settingsBorder:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT")

    -- Create title for settings frame
    local title = settingsFrame:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", settingsFrame, "TOP", 0, -10)
    title:FontTemplate(nil, 14, "OUTLINE")
    title:SetText("Time Display Settings")

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

    settingsFrame:Show()
end


    -- Left-click to open/close the calendar, shift + left-click to toggle border position
    -- Right-click to open the stopwatch, shift + right-click to toggle time format
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
                if not IsAddOnLoaded("Blizzard_Calendar") then
                    UIParentLoadAddOn("Blizzard_Calendar")
                end
                if Calendar_Toggle then
                    Calendar_Toggle()
                end
            end
        elseif button == "RightButton" and IsShiftKeyDown() then
            Use24HourTime = not Use24HourTime  -- Toggle the time format
            text:SetText(date(GetTimeFormat()))  -- Update the time display immediately
        elseif button == "RightButton" then
            Stopwatch_Toggle()
        end
    end)

    -- Show tooltip on mouseover, centered at the bottom of clock window frame
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -5)
        GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -10)
        GameTooltip:AddLine("Time Display")
        GameTooltip:AddLine("Left-click: Open/Close Calendar", 1, 1, 1)
        GameTooltip:AddLine("Shift + Left-click: Toggle Border Position", 1, 1, 1)
        GameTooltip:AddLine("Ctrl + Left-click: Show Settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Open/Close Stopwatch", 1, 1, 1)
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
end
