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
text:SetText(date("%I:%M %p"))

-- Update the time every second
frame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    if self.timeSinceLastUpdate >= 1 then
        text:SetText(date("%I:%M %p"))
        self.timeSinceLastUpdate = 0
    end
end)

-- Right-click to open the stopwatch, left-click to open/close the calendar, shift+right-click to open new window
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
        CreateNewWindow()
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
    GameTooltip:AddLine("Shift + Right-click: Open New Window", 1, 1, 1)
    GameTooltip:Show()
end)

frame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Function to create a new window with similar styling
function CreateNewWindow()
    local newFrame = CreateFrame("Frame", "NewWindowFrame", UIParent)
    newFrame:SetSize(200, 100)
    newFrame:SetPoint("CENTER")
    newFrame:SetTemplate("Transparent")
    newFrame:Show()

    -- Enable dragging
    newFrame:EnableMouse(true)
    newFrame:SetMovable(true)
    newFrame:RegisterForDrag("LeftButton")
    newFrame:SetScript("OnDragStart", newFrame.StartMoving)
    newFrame:SetScript("OnDragStop", newFrame.StopMovingOrSizing)

    -- Create the top border texture for the new window
    local newTopBorder = newFrame:CreateTexture(nil, "OVERLAY")
    newTopBorder:SetPoint("TOPLEFT", newFrame, "TOPLEFT", 1, 0)
    newTopBorder:SetPoint("TOPRIGHT", newFrame, "TOPRIGHT", -1, 0)
    newTopBorder:SetHeight(3)
    newTopBorder:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.8) -- Set the class color

    -- Close button
    local closeButton = CreateFrame("Button", nil, newFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", newFrame, "TOPRIGHT")
    closeButton:SetScript("OnClick", function()
        newFrame:Hide()
    end)
end

-- Print debug messages to ensure everything is working
print("Frame created, styled, and movable")
