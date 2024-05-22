-- Check if ElvUI is loaded
if not IsAddOnLoaded("ElvUI") then
    print("ElvUI is not loaded.")
    return
end

-- Initialize ElvUI
local E, C, L, DB = unpack(ElvUI)
print("ElvUI initialized:", E, C, L, DB)

-- Get the class color
local classColor = E:ClassColor(E.myclass, true)

-- Initialize saved variables
if not TimeDisplayConfig then
    TimeDisplayConfig = {}
end

if TimeDisplayConfig.use24Hour == nil then
    TimeDisplayConfig.use24Hour = false  -- Default to 12-hour format
end

-- Function to get the time format
local function GetTimeFormat()
    if TimeDisplayConfig.use24Hour then
        return "%H:%M %p"
    else
        return "%I:%M %p"
    end
end

-- Create the main frame
local frame = CreateFrame("Frame", "TimeDisplayFrame", UIParent)
frame:SetSize(75, 25)  -- Slightly smaller size
frame:SetPoint("CENTER")
frame:SetTemplate("Transparent")
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
end)

-- Create the top border texture
local topBorder = frame:CreateTexture(nil, "OVERLAY")
topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, 0)
topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, 0)
topBorder:SetHeight(3)
topBorder:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.8) -- Set the class color

-- Create the text element using ElvUI's FontString function
local text = frame:CreateFontString(nil, "OVERLAY")
text:SetPoint("CENTER")
text:FontTemplate(nil, 12, "OUTLINE")  -- Slightly smaller font size
text:SetText(date(GetTimeFormat()))

-- Update the time every second
frame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    if self.timeSinceLastUpdate >= 1 then
        text:SetText(date(GetTimeFormat()))
        self.timeSinceLastUpdate = 0
    end
end)

-- Right-click to open the stopwatch, left-click to open/close the calendar, shift+right-click to toggle time format
frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        isDragging = false
    end
end)

frame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and not isDragging then
        if not IsAddOnLoaded("Blizzard_Calendar") then
            UIParentLoadAddOn("Blizzard_Calendar")
        end
        if Calendar_Toggle then
            Calendar_Toggle()
        end
    elseif button == "RightButton" and IsShiftKeyDown() then
        TimeDisplayConfig.use24Hour = not TimeDisplayConfig.use24Hour  -- Toggle the time format
        text:SetText(date(GetTimeFormat()))  -- Update the time display immediately
    elseif button == "RightButton" then
        Stopwatch_Toggle()
    end
end)

-- Show tooltip on mouseover, centered at the top
frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -5)
    GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -10)  -- Center at the top with 10 pixels offset down
    GameTooltip:AddLine("Time Display")
    GameTooltip:AddLine("Left-click: Open/Close Calendar", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Open/Close Stopwatch", 1, 1, 1)
    GameTooltip:AddLine("Shift + Right-click: Toggle Time Format", 1, 1, 1)
    GameTooltip:Show()
end)

frame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Print debug messages to ensure everything is working
print("Frame created, styled, and movable")
