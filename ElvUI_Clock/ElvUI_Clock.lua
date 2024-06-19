TimeDisplayAddon = {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Register event for entering combat
frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Register event for exiting combat
frame:RegisterEvent("ZONE_CHANGED")           -- Register event for zone change
frame:RegisterEvent("ZONE_CHANGED_INDOORS")   -- Register event for indoor zone change
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")  -- Register event for new area change
frame:RegisterEvent("MAIL_INBOX_UPDATE")      -- Register event for mail inbox update
frame:RegisterEvent("UPDATE_PENDING_MAIL")    -- Register event for pending mail update
frame:RegisterEvent("TAXIMAP_OPENED")         -- Register event for opening the taxi map
frame:RegisterEvent("TAXIMAP_CLOSED")         -- Register event for closing the taxi map
frame:RegisterEvent("PLAYER_CONTROL_LOST")    -- Register event for starting flying
frame:RegisterEvent("PLAYER_CONTROL_GAINED")  -- Register event for stopping flying
frame:RegisterEvent("LFG_UPDATE")             -- Register event for LFG update
frame:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")-- Register event for LFG queue status update
frame:RegisterEvent("PLAYER_LEVEL_UP")  -- Register event for player level up

frame:SetScript("OnEvent", function(self, event, ...)
    TimeDisplayAddon[event](TimeDisplayAddon, ...)
end)

local inCombat = false  -- Track combat state
local mailIndicator = nil  -- Texture element for mail indicator
local flyingFrame = nil   -- Frame for the flying window
local queueFrame = nil   -- Frame for the queue time window
local destinationName = ""  -- Variable to store flight destination name

local function PrintMessage(message)
    local addonName = "ElvUI Clock"
    local colorCode = "|cff00ff00"  -- Green color code
    local resetCode = "|r"          -- Reset code to return to normal font color
    print(colorCode .. addonName .. resetCode .. ": " .. message)
end

function TimeDisplayAddon:PLAYER_LOGIN()
    self:SetDefaults()

    -- Initialize ElvUI
    if not IsAddOnLoaded("ElvUI") then
        PrintMessage("ElvUI is not loaded.")
        return
    end

    local E, C, L, DB = unpack(ElvUI)
    PrintMessage("ElvUI initialized", E, C, L, DB)

    local classColor = E:ClassColor(E.myclass, true)
    local colors = {"Class Color", "Blue", "Red", "Green", "Pink", "Cyan", "Yellow", "Purple", "Orange", "Black", "Grey", "White", "None"}
    local functionalityOptions = {"Calendar", "Friends", "Character", "Spellbook", "Talents", "Achievements", "Quests", "Guild", "Dungeon Finder", "Raid Finder", "Collections", "Shop", "Stopwatch", "Map", "Professions", "Mount Journal", "Pet Journal", "None"}

    -- Adjust WindowHeight if ShowLocation is true
    local function GetAdjustedHeight()
        local height = WindowHeight + (ShowLocation and 50 or 0)
        if ShowDate and not ShowLocation then
            height = height + 20  -- Add padding for the date
        end
        return height
    end

    -- Create the main frame
    local frame = CreateFrame("Frame", "TimeDisplayFrame", UIParent)
    frame:SetSize(WindowWidth or 175, GetAdjustedHeight())  -- Adjusted height to fit time and location
    frame:SetTemplate("Transparent")

    -- Set the frame position from saved variables
    if FramePosition then
        frame:SetPoint(FramePosition.point, FramePosition.relativeTo, FramePosition.relativePoint, FramePosition.xOfs, FramePosition.yOfs)
    else
        frame:SetPoint("CENTER")
    end

    frame:Show()

    -- Enable dragging if WindowLocked is false
    frame:EnableMouse(true)
    frame:SetMovable(not WindowLocked)
    frame:RegisterForDrag("LeftButton")

    -- Create a flag to detect dragging
    local isDragging = false

    frame:SetScript("OnDragStart", function(self)
        if not WindowLocked then
            isDragging = true
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        if not WindowLocked then
            isDragging = false
            self:StopMovingOrSizing()

            -- Save the new position
            local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
            FramePosition = { point = point, relativeTo = relativeTo and relativeTo:GetName() or "UIParent", relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
        end
    end)

    -- Function to get the version number from the TOC file
    local function GetAddonVersion()
        local version = GetAddOnMetadata("ElvUI_Clock", "Version")
        return version or "Unknown"
    end

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
        elseif ColorChoice == "Purple" then
            windowBorder:SetColorTexture(0.5, 0, 0.5, 0.8)
        elseif ColorChoice == "Orange" then
            windowBorder:SetColorTexture(1, 0.5, 0, 0.8)
        elseif ColorChoice == "Black" then
            windowBorder:SetColorTexture(0, 0, 0, 0.8)
        elseif ColorChoice == "Grey" then
            windowBorder:SetColorTexture(0.5, 0.5, 0.5, 0.8)
        elseif ColorChoice == "White" then
            windowBorder:SetColorTexture(1, 1, 1, 0.8)
        else
            windowBorder:SetColorTexture(0, 0, 0, 0)  -- Make it transparent
        end
    end

    -- Function to update the border position
    local function UpdateBorderPosition()
        windowBorder:ClearAllPoints()
        windowBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
        windowBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    end

    UpdateBorderColor()
    UpdateBorderPosition()

    -- Function to get the time format
    local function GetTimeFormat()
        if Use24HourTime then
            return "%H:%M"
        else
            return "%I:%M %p"
        end
    end

    -- Function to truncate long strings
    local function TruncateString(str, maxLength)
        if str:len() > maxLength then
            return str:sub(1, maxLength - 3) .. "..."
        else
            return str
        end
    end

    -- Function to get the color based on the string value
    local function GetColor(colorName)
        if colorName == "Class Color" then
            return classColor.r, classColor.g, classColor.b
        elseif colorName == "Blue" then
            return 0, 0, 1
        elseif colorName == "Red" then
            return 1, 0, 0
        elseif colorName == "Green" then
            return 0, 1, 0
        elseif colorName == "Pink" then
            return 1, 0, 1
        elseif colorName == "Cyan" then
            return 0, 1, 1
        elseif colorName == "Yellow" then
            return 1, 1, 0
        elseif colorName == "Purple" then
            return 0.5, 0, 0.5
        elseif colorName == "Orange" then
            return 1, 0.5, 0
        elseif colorName == "Black" then
            return 0, 0, 0
        elseif colorName == "Grey" then
            return 0.5, 0.5, 0.5
        elseif colorName == "White" then
            return 1, 1, 1
        else
            return 1, 1, 1  -- Default to white
        end
    end

    -- Set the font sizes for the text elements
    local dungeonNameFontSize = 12
    local dungeonDifficultyFontSize = 10
    local locationFontSize = 12
    local coordinatesFontSize = 10
    local timeFontSize = 14

    local timeText = frame:CreateFontString(nil, "OVERLAY")
    timeText:SetPoint("TOP", frame, "TOP", 0, -5)
    timeText:FontTemplate(nil, timeFontSize, "OUTLINE")
    timeText:SetTextColor(GetColor(TimeColor))  -- Update time color when initializing the frame

    local dateText = frame:CreateFontString(nil, "OVERLAY")  -- New date text
    dateText:SetPoint("TOP", timeText, "BOTTOM", 0, -5)
    dateText:FontTemplate(nil, 10, "OUTLINE")

    local locationText = frame:CreateFontString(nil, "OVERLAY")
    locationText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 25)  -- Adjusted position
    locationText:SetWidth(WindowWidth or 175)  -- Set the width to match the frame width
    locationText:FontTemplate(nil, locationFontSize, "OUTLINE")

    local coordinatesText = frame:CreateFontString(nil, "OVERLAY")
    coordinatesText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    coordinatesText:SetWidth((WindowWidth or 175) * 1.5)
    coordinatesText:FontTemplate(nil, coordinatesFontSize, "OUTLINE")

    local dungeonNameText = frame:CreateFontString(nil, "OVERLAY")
    dungeonNameText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 25)
    dungeonNameText:SetWidth((WindowWidth or 175) * 1.5)
    dungeonNameText:FontTemplate(nil, dungeonNameFontSize, "OUTLINE")

    local dungeonDifficultyText = frame:CreateFontString(nil, "OVERLAY")
    dungeonDifficultyText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    dungeonDifficultyText:SetWidth((WindowWidth or 175) * 1.5)
    dungeonDifficultyText:FontTemplate(nil, dungeonDifficultyFontSize, "OUTLINE")

    local levelUpFrame = CreateFrame("Frame", "LevelUpDisplayFrame", UIParent)
    levelUpFrame:SetSize(WindowWidth or 175, 75)
    levelUpFrame:SetPoint("TOP", frame, "BOTTOM", 0, 0)  -- Position underneat the main window
    levelUpFrame:SetTemplate("Transparent")
    levelUpFrame:Hide()  -- Initially hidden

    -- Create the bottom border texture for the levelUpFrame
    local levelUpFrameBottomBorder = levelUpFrame:CreateTexture(nil, "OVERLAY")
    levelUpFrameBottomBorder:SetHeight(3)
    levelUpFrameBottomBorder:SetPoint("BOTTOMLEFT", levelUpFrame, "BOTTOMLEFT")
    levelUpFrameBottomBorder:SetPoint("BOTTOMRIGHT", levelUpFrame, "BOTTOMRIGHT")

    local levelUpText = levelUpFrame:CreateFontString(nil, "OVERLAY")
    levelUpText:SetAllPoints(levelUpFrame)
    levelUpText:FontTemplate(nil, 14, "OUTLINE")
    levelUpText:SetText("Congratulations on leveling up!")

    -- Create the texture element for mail indicator
    mailIndicator = frame:CreateTexture(nil, "OVERLAY")
    mailIndicator:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
    mailIndicator:SetSize(16, 16)  -- Set the size of the mail icon
    mailIndicator:SetTexture("Interface\\AddOns\\ElvUI_Clock\\custom_mail_icon.tga")  -- Use a built-in mail icon
    mailIndicator:Hide()  -- Initially hidden

    -- Function to update player location
    local function UpdateLocation()
        local inInstance, instanceType = IsInInstance()
        if inInstance then
            local instanceName, _, _, difficultyName = GetInstanceInfo()
            dungeonNameText:SetText(instanceName)
            dungeonDifficultyText:SetText(difficultyName)
            locationText:SetText("")
            coordinatesText:SetText("")
        else
            dungeonNameText:SetText("")
            dungeonDifficultyText:SetText("")
            local mapID = C_Map.GetBestMapForUnit("player")
            if not mapID then
                locationText:SetText("Unknown Location")
                coordinatesText:SetText("")
                return
            end

            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if not position then
                locationText:SetText("Unknown Location")
                coordinatesText:SetText("")
                return
            end

            local x, y = position:GetXY()
            local playerLocation = GetZoneText()
            playerLocation = TruncateString(playerLocation, 30)  -- Truncate the location name if it's too long
            locationText:SetText(playerLocation)
            coordinatesText:SetText(string.format("%.2f, %.2f", x * 100, y * 100))
        end
    end

    -- Check if timeToConvert starts with "0" and remove it if Use24HourTime is false
    local function removeLeadingZero(timeToConvert)
        if Use24HourTime then
            return timeToConvert
        end
        timeToConvert = timeToConvert:gsub("^0", "")
        return timeToConvert
    end

    -- Update the time display immediately
    local time = ""
    if not Use24HourTime then
        time = removeLeadingZero(date(GetTimeFormat()))
    else
        time = date(GetTimeFormat())
    end

    timeText:SetText(time)
    -- Function to update mail indicator visibility
    local mailTooltipEnabled = true  -- Track mail tooltip state
    local mailSenders = {}
    local function UpdateMailIndicator()
        if ShowMail and PlayerHasMail and not inCombat then  -- Hide mail indicator in combat
            mailIndicator:Show()
            mailSenders = { GetLatestThreeSenders() }
            -- Ensure mailSenders is not nil or empty
            if not mailSenders or #mailSenders == 0 then
                mailSenders = { UNKNOWN }
            end
        else
            mailIndicator:Hide()
            mailSenders = {}
        end
    end

    local function UpdateXPDisplay()
        if TrackingXP then
            local level = UnitLevel("player")
            local currentXP = UnitXP("player")
            local maxXP = UnitXPMax("player")
            local percentXP = (currentXP / maxXP) * 100

            if not xpLevelText then
                xpLevelText = frame:CreateFontString(nil, "OVERLAY")
                xpLevelText:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
                xpLevelText:FontTemplate(nil, 12, "OUTLINE")
            end

            if not xpPercentText then
                xpPercentText = frame:CreateFontString(nil, "OVERLAY")
                xpPercentText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
                xpPercentText:FontTemplate(nil, 12, "OUTLINE")
            end

            -- Interpolate color based on XP percentage
            local r = 1 - (percentXP / 100)
            local g = 1
            local b = 1 - (percentXP / 100)

            xpLevelText:SetText("Lvl " .. level)
            if level ~= 85 then
                xpPercentText:SetText(string.format("%.1f%%", percentXP))
            end
            xpPercentText:SetTextColor(r, g, b)

            xpLevelText:Show()
            xpPercentText:Show()
        else
            if xpLevelText then
                xpLevelText:Hide()
            end
            if xpPercentText then
                xpPercentText:Hide()
            end
        end
    end

    -- Function to update the border color for the queue time window
    local function UpdateQueueFrameBorderColor()
        local color = {0, 0, 0, 0}  -- Default transparent color
        if ColorChoice == "Class Color" then
            color = {classColor.r, classColor.g, classColor.b, 0.8}
        elseif ColorChoice == "Blue" then
            color = {0, 0, 1, 0.8}
        elseif ColorChoice == "Red" then
            color = {1, 0, 0, 0.8}
        elseif ColorChoice == "Green" then
            color = {0, 1, 0, 0.8}
        elseif ColorChoice == "Pink" then
            color = {1, 0, 1, 0.8}
        elseif ColorChoice == "Cyan" then
            color = {0, 1, 1, 0.8}
        elseif ColorChoice == "Yellow" then
            color = {1, 1, 0, 0.8}
        elseif ColorChoice == "Purple" then
            color = {0.5, 0, 0.5, 0.8}
        elseif ColorChoice == "Orange" then
            color = {1, 0.5, 0, 0.8}
        elseif ColorChoice == "Black" then
            color = {0, 0, 0, 0.8}
        elseif ColorChoice == "Grey" then
            color = {0.5, 0.5, 0.5, 0.8}
        elseif ColorChoice == "White" then
            color = {1, 1, 1, 0.8}
        end
        queueFrame.bottomBorder:SetColorTexture(unpack(color))
    end

    -- Function to update the border color for the levelUpFrame
    local function UpdateLevelUpFrameBorderColor()
        local color = {0, 0, 0, 0}  -- Default transparent color
        if ColorChoice == "Class Color" then
            color = {classColor.r, classColor.g, classColor.b, 0.8}
        elseif ColorChoice == "Blue" then
            color = {0, 0, 1, 0.8}
        elseif ColorChoice == "Red" then
            color = {1, 0, 0, 0.8}
        elseif ColorChoice == "Green" then
            color = {0, 1, 0, 0.8}
        elseif ColorChoice == "Pink" then
            color = {1, 0, 1, 0.8}
        elseif ColorChoice == "Cyan" then
            color = {0, 1, 1, 0.8}
        elseif ColorChoice == "Yellow" then
            color = {1, 1, 0, 0.8}
        elseif ColorChoice == "Purple" then
            color = {0.5, 0, 0.5, 0.8}
        elseif ColorChoice == "Orange" then
            color = {1, 0.5, 0, 0.8}
        elseif ColorChoice == "Black" then
            color = {0, 0, 0, 0.8}
        elseif ColorChoice == "Grey" then
            color = {0.5, 0.5, 0.5, 0.8}
        elseif ColorChoice == "White" then
            color = {1, 1, 1, 0.8}
        end
        levelUpFrameBottomBorder:SetColorTexture(unpack(color))
    end

    UpdateLevelUpFrameBorderColor()

    -- Update the time and date display
    local function UpdateTimeDisplay()
        local time = ""
        if not Use24HourTime then
            time = removeLeadingZero(date(GetTimeFormat()))
        else
            time = date(GetTimeFormat())
        end
        timeText:SetText(time)

        if ShowDate then
            dateText:SetText(date("%m/%d/%y"))
        else
            dateText:SetText("")
        end
    end

    -- Function to create the queue time window
    local function CreateQueueWindow()
        queueFrame = CreateFrame("Frame", "QueueDisplayFrame", UIParent)
        queueFrame:SetSize(WindowWidth or 175, 70)
        queueFrame:SetTemplate("Transparent")

        -- Check if the flyingFrame is shown, and adjust the position of the queueFrame
        if flyingFrame and flyingFrame:IsShown() then
            queueFrame:SetPoint("TOP", frame, "BOTTOM", 0, -75)
        else
            queueFrame:SetPoint("TOP", frame, "BOTTOM", 0, 0)  -- Default position
        end

        queueFrame:Hide()

        local instanceTypeText = queueFrame:CreateFontString(nil, "OVERLAY")
        instanceTypeText:SetPoint("TOP", queueFrame, "TOP", 0, -10)
        instanceTypeText:FontTemplate(nil, 13, "OUTLINE")
        queueFrame.instanceTypeText = instanceTypeText

        local queueTimeText = queueFrame:CreateFontString(nil, "OVERLAY")
        queueTimeText:SetPoint("TOP", instanceTypeText, "BOTTOM", 0, -5)
        queueTimeText:FontTemplate(nil, 12, "OUTLINE")
        queueFrame.queueTimeText = queueTimeText

        local avgQueueTimeText = queueFrame:CreateFontString(nil, "OVERLAY")
        avgQueueTimeText:SetPoint("TOP", queueTimeText, "BOTTOM", 0, -5)
        avgQueueTimeText:FontTemplate(nil, 12, "OUTLINE")
        queueFrame.avgQueueTimeText = avgQueueTimeText

        -- Add the bottom border texture
        local queueFrameBottomBorder = queueFrame:CreateTexture(nil, "OVERLAY")
        queueFrameBottomBorder:SetHeight(3)
        queueFrameBottomBorder:SetPoint("BOTTOMLEFT", queueFrame, "BOTTOMLEFT")
        queueFrameBottomBorder:SetPoint("BOTTOMRIGHT", queueFrame, "BOTTOMRIGHT")
        queueFrame.bottomBorder = queueFrameBottomBorder

        -- Enable mouse interaction for queueFrame
        queueFrame:EnableMouse(true)
        queueFrame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                PVEFrame_ToggleFrame()  -- Open the dungeon finder window
            end
        end)

        return queueFrame
    end

    -- Create the queue time window
    CreateQueueWindow()

    -- Function to show the queue time window
    local function ShowQueueWindow()
        if not queueFrame then
            CreateQueueWindow()
        end

        -- Re-check the position when showing the window
        if flyingFrame and flyingFrame:IsShown() then
            queueFrame:ClearAllPoints()
            queueFrame:SetPoint("TOP", frame, "BOTTOM", 0, -70)
        else
            queueFrame:ClearAllPoints()
            queueFrame:SetPoint("TOP", frame, "BOTTOM", 0, 0)
        end

        queueFrame:Show()
        UpdateQueueFrameBorderColor()
    end

    -- Function to hide the queue time window
    local function HideQueueWindow()
        if queueFrame then
            queueFrame:Hide()
        end
    end

    local function FormatTime(seconds)
        local minutes = floor(seconds / 60)
        local remainingSeconds = seconds % 60
        if minutes > 0 then
            return string.format("%dm %ds", minutes, remainingSeconds)
        else
            return string.format("%ds", remainingSeconds)
        end
    end

    -- Add variables for storing queue time
    local currentQueuedTime = 0

    -- Function to update the queue times
    local function UpdateQueueTimes()
        local inQueue, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, totalTanks, totalHealers, totalDPS, instanceType, 
        instanceSubType, instanceName, averageWait, tankWait, healerWait, dpsWait, myWait, queuedTime = GetLFGQueueStats(1)
        if inQueue then
            currentQueuedTime = GetTime() - queuedTime  -- Set the start time of the queue
            queueFrame.instanceTypeText:SetTextColor(GetColor(TimeColor))
            queueFrame.instanceTypeText:SetText(instanceName)
            queueFrame.queueTimeText:SetText("Time in Queue: " .. FormatTime(currentQueuedTime))
            queueFrame.avgQueueTimeText:SetText("Avg Queue Time: " .. FormatTime(averageWait))
            ShowQueueWindow()
        else
            HideQueueWindow()
        end
    end

    -- Update the time, location, and mail indicator every second
    local frameCounter = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
        if self.timeSinceLastUpdate >= 1 then
            UpdateTimeDisplay()
            UpdateQueueTimes()
            UpdateMailIndicator()
            UpdateXPDisplay()
            timeText:FontTemplate(nil, timeFontSize, "OUTLINE")
            locationText:FontTemplate(nil, locationFontSize, "OUTLINE")
            locationText:SetShown(ShowLocation)
            coordinatesText:SetShown(ShowLocation)
            self.timeSinceLastUpdate = 0
        end
        frameCounter = frameCounter + 1
        if frameCounter >= 60 then  -- Check if 60 frames have passed
            UpdateLocation()
            frameCounter = 0  -- Reset the frame counter
        end
    end)

    function TimeDisplayAddon:PLAYER_LEVEL_UP(level)
        levelUpText:SetText("Congratulations on reaching level " .. level .. "!")
        levelUpFrame:Show()
        C_Timer.After(10, function() levelUpFrame:Hide() end)  -- Hide the frame after 10 seconds
    end

    -- Update location when the player changes zones
    function TimeDisplayAddon:ZONE_CHANGED()
        UpdateLocation()
    end

    function TimeDisplayAddon:ZONE_CHANGED_INDOORS()
        UpdateLocation()
    end

    function TimeDisplayAddon:ZONE_CHANGED_NEW_AREA()
        UpdateLocation()
    end

    -- Function to update the frame size based on ShowLocation
    local function UpdateFrameSize()
        local height = GetAdjustedHeight()
        frame:SetHeight(height)
    end

    -- Function to create the flying window
    local function CreateFlyingWindow()
        flyingFrame = CreateFrame("Frame", "FlyingDisplayFrame", UIParent)
        flyingFrame:SetSize(WindowWidth or 175, 70)  -- Decrease height
        flyingFrame:SetTemplate("Transparent")

        flyingFrame:SetPoint("TOP", frame, "BOTTOM", 0, 0)
        flyingFrame:Hide()

        local flyingText = flyingFrame:CreateFontString(nil, "OVERLAY")
        flyingText:SetPoint("TOP", flyingFrame, "TOP", 0, -5)
        flyingText:FontTemplate(nil, 14, "OUTLINE")
        flyingFrame.text = flyingText

        local mainLocationText = flyingFrame:CreateFontString(nil, "OVERLAY")
        mainLocationText:SetPoint("TOP", flyingText, "BOTTOM", 0, -5)
        mainLocationText:FontTemplate(nil, 14, "OUTLINE")
        flyingFrame.mainLocationText = mainLocationText

        local subLocationText = flyingFrame:CreateFontString(nil, "OVERLAY")
        subLocationText:SetPoint("TOP", mainLocationText, "BOTTOM", 0, -5)
        subLocationText:FontTemplate(nil, 14, "OUTLINE")
        flyingFrame.subLocationText = subLocationText

        -- Add the bottom border texture
        local flyingFrameBottomBorder = flyingFrame:CreateTexture(nil, "OVERLAY")
        flyingFrameBottomBorder:SetHeight(3)
        flyingFrameBottomBorder:SetPoint("BOTTOMLEFT", flyingFrame, "BOTTOMLEFT")
        flyingFrameBottomBorder:SetPoint("BOTTOMRIGHT", flyingFrame, "BOTTOMRIGHT")
        flyingFrame.bottomBorder = flyingFrameBottomBorder

        return flyingFrame
    end

    -- Function to update the border color for the flying window
    local function UpdateFlyingFrameBorderColor()
        local color = {0, 0, 0, 0}  -- Default transparent color
        if ColorChoice == "Class Color" then
            color = {classColor.r, classColor.g, classColor.b, 0.8}
        elseif ColorChoice == "Blue" then
            color = {0, 0, 1, 0.8}
        elseif ColorChoice == "Red" then
            color = {1, 0, 0, 0.8}
        elseif ColorChoice == "Green" then
            color = {0, 1, 0, 0.8}
        elseif ColorChoice == "Pink" then
            color = {1, 0, 1, 0.8}
        elseif ColorChoice == "Cyan" then
            color = {0, 1, 1, 0.8}
        elseif ColorChoice == "Yellow" then
            color = {1, 1, 0, 0.8}
        elseif ColorChoice == "Purple" then
            color = {0.5, 0, 0.5, 0.8}
        elseif ColorChoice == "Orange" then
            color = {1, 0.5, 0, 0.8}
        elseif ColorChoice == "Black" then
            color = {0, 0, 0, 0.8}
        elseif ColorChoice == "Grey" then
            color = {0.5, 0.5, 0.5, 0.8}
        elseif ColorChoice == "White" then
            color = {1, 1, 1, 0.8}
        end
        flyingFrame.bottomBorder:SetColorTexture(unpack(color))
    end

    -- Function to show the flying window with the destination
    local function ShowFlyingWindow(destination)
        if not flyingFrame then
            CreateFlyingWindow()
        end
        flyingFrame:Show()
        local mainLocation, subLocation = destination:match("^(.-),%s*(.-)$")
        flyingFrame.text:SetText("Flying To")
        flyingFrame.mainLocationText:SetText(mainLocation or "")
        flyingFrame.subLocationText:SetText(subLocation or "")
        UpdateFlyingFrameBorderColor()
    end

    -- Function to hide the flying window
    local function HideFlyingWindow()
        if flyingFrame then
            flyingFrame:Hide()
        end
    end

    -- Create the flying window
    CreateFlyingWindow()

    -- Function to create a new window displaying current settings
    local function OpenSettingsWindow()
        if inCombat then
            PrintMessage("Cannot open settings window while in combat.")
            return
        end

        SettingsWindowOpen = true

        SettingsFrame = CreateFrame("Frame", "SettingsFrame", UIParent)
        SettingsFrame:SetSize(250, 530)
        SettingsFrame:SetTemplate("Transparent")

        -- Set the frame position from saved variables
        if SettingsFramePosition then
            SettingsFrame:SetPoint(SettingsFramePosition.point, SettingsFramePosition.relativeTo, SettingsFramePosition.relativePoint, SettingsFramePosition.xOfs, SettingsFramePosition.yOfs)
        else
            SettingsFrame:SetPoint("CENTER")
        end

        -- Enable dragging
        SettingsFrame:EnableMouse(true)
        SettingsFrame:SetMovable(true)
        SettingsFrame:RegisterForDrag("LeftButton")

        SettingsFrame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)

        SettingsFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()

            -- Save the new position
            local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
            SettingsFramePosition = { point = point, relativeTo = relativeTo and relativeTo:GetName() or "UIParent", relativePoint = relativePoint, xOfs = xOfs, yOfs = yOfs }
        end)

        -- Create close button
        local closeButton = CreateFrame("Button", nil, SettingsFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT")
        closeButton:SetScript("OnClick", function()
            SettingsFrame:Hide()
            SettingsWindowOpen = false
        end)

        -- Create top border for settings frame
        local settingsBorder = SettingsFrame:CreateTexture(nil, "OVERLAY")
        settingsBorder:SetHeight(3)
        settingsBorder:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT")
        settingsBorder:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT")

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
            elseif ColorChoice == "Purple" then
                settingsBorder:SetColorTexture(0.5, 0, 0.5, 0.8)
            elseif ColorChoice == "Orange" then
                settingsBorder:SetColorTexture(1, 0.5, 0, 0.8)
            elseif ColorChoice == "Black" then
                settingsBorder:SetColorTexture(0, 0, 0, 0.8)
            elseif ColorChoice == "Grey" then
                settingsBorder:SetColorTexture(0.5, 0.5, 0.5, 0.8)
            elseif ColorChoice == "White" then
                settingsBorder:SetColorTexture(1, 1, 1, 0.8)
            else
                settingsBorder:SetColorTexture(0, 0, 0, 0)  -- Make it transparent
            end
        end

        UpdateSettingsBorderColor()

        -- Create title for settings frame
        local title = SettingsFrame:CreateFontString(nil, "OVERLAY")
        title:SetPoint("TOP", SettingsFrame, "TOP", 0, -10)
        title:FontTemplate(nil, 14, "OUTLINE")
        title:SetText("ElvUI Clock Settings")

        -- Create checkbox for 24 Hour Time
        local checkbox = CreateFrame("CheckButton", nil, SettingsFrame, "ChatConfigCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -40)
        checkbox:SetChecked(Use24HourTime)
        checkbox:SetScript("OnClick", function(self)
            Use24HourTime = self:GetChecked()

            if not Use24HourTime then
                time = removeLeadingZero(date(GetTimeFormat()))
            else
                time = date(GetTimeFormat())
            end
            timeText:SetText(time)  -- Update the time display immediately
        end)

        -- Create text label for 24 Hour checkbox
        local checkboxLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        checkboxLabel:FontTemplate(nil, 12, "OUTLINE")
        checkboxLabel:SetText("24 Hour")

        -- Create checkbox for Combat Warning
        local combatCheckbox = CreateFrame("CheckButton", nil, SettingsFrame, "ChatConfigCheckButtonTemplate")
        combatCheckbox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -70)
        combatCheckbox:SetChecked(CombatWarning)
        combatCheckbox:SetScript("OnClick", function(self)
            CombatWarning = self:GetChecked()
        end)

        -- Create text label for combat warning checkbox
        local combatCheckboxLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        combatCheckboxLabel:SetPoint("LEFT", combatCheckbox, "RIGHT", 5, 0)
        combatCheckboxLabel:FontTemplate(nil, 12, "OUTLINE")
        combatCheckboxLabel:SetText("Combat Warning")

        -- Create checkbox for Show Location
        local locationCheckbox = CreateFrame("CheckButton", nil, SettingsFrame, "ChatConfigCheckButtonTemplate")
        locationCheckbox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -100)
        locationCheckbox:SetChecked(ShowLocation)
        locationCheckbox:SetScript("OnClick", function(self)
            ShowLocation = self:GetChecked()
            UpdateFrameSize()  -- Update frame size when Show Location is toggled
        end)

        -- Create text label for show location checkbox
        local locationCheckboxLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        locationCheckboxLabel:SetPoint("LEFT", locationCheckbox, "RIGHT", 5, 0)
        locationCheckboxLabel:FontTemplate(nil, 12, "OUTLINE")
        locationCheckboxLabel:SetText("Show Location")

        -- Create checkbox for Show Mail
        local mailCheckbox = CreateFrame("CheckButton", nil, SettingsFrame, "ChatConfigCheckButtonTemplate")
        mailCheckbox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -130)
        mailCheckbox:SetChecked(ShowMail)
        mailCheckbox:SetScript("OnClick", function(self)
            ShowMail = self:GetChecked()
            UpdateMailIndicator()  -- Update mail indicator visibility when Show Mail is toggled
        end)

        -- Create text label for show mail checkbox
        local mailCheckboxLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        mailCheckboxLabel:SetPoint("LEFT", mailCheckbox, "RIGHT", 5, 0)
        mailCheckboxLabel:FontTemplate(nil, 12, "OUTLINE")
        mailCheckboxLabel:SetText("Show Mail Indicator")

        -- Create checkbox for Window Locked
        local lockCheckbox = CreateFrame("CheckButton", nil, SettingsFrame, "ChatConfigCheckButtonTemplate")
        lockCheckbox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -160)
        lockCheckbox:SetChecked(WindowLocked)
        lockCheckbox:SetScript("OnClick", function(self)
            WindowLocked = self:GetChecked()
            frame:SetMovable(not WindowLocked)  -- Update frame draggable state immediately
        end)

        -- Create text label for window locked checkbox
        local lockCheckboxLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        lockCheckboxLabel:SetPoint("LEFT", lockCheckbox, "RIGHT", 5, 0)
        lockCheckboxLabel:FontTemplate(nil, 12, "OUTLINE")
        lockCheckboxLabel:SetText("Lock Window")

        -- Create checkbox for Show Date
        local showDateCheckbox = CreateFrame("CheckButton", nil, SettingsFrame, "ChatConfigCheckButtonTemplate")
        showDateCheckbox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -190)
        showDateCheckbox:SetChecked(ShowDate)
        showDateCheckbox:SetScript("OnClick", function(self)
            ShowDate = self:GetChecked()
            UpdateTimeDisplay()  -- Update the display immediately when toggled
            UpdateFrameSize()    -- Adjust frame size when ShowDate is toggled
        end)

        -- Create text label for show date checkbox
        local showDateCheckboxLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        showDateCheckboxLabel:SetPoint("LEFT", showDateCheckbox, "RIGHT", 5, 0)
        showDateCheckboxLabel:FontTemplate(nil, 12, "OUTLINE")
        showDateCheckboxLabel:SetText("Show Date")

        -- Create checkbox for Tracking XP
        local trackingXPCheckbox = CreateFrame("CheckButton", nil, SettingsFrame, "ChatConfigCheckButtonTemplate")
        trackingXPCheckbox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -220)
        trackingXPCheckbox:SetChecked(TrackingXP)
        trackingXPCheckbox:SetScript("OnClick", function(self)
        TrackingXP = self:GetChecked()
        UpdateXPDisplay()  -- Update display immediately when toggled
        end)

        -- Create text label for tracking XP checkbox
        local trackingXPCheckboxLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        trackingXPCheckboxLabel:SetPoint("LEFT", trackingXPCheckbox, "RIGHT", 5, 0)
        trackingXPCheckboxLabel:FontTemplate(nil, 12, "OUTLINE")
        trackingXPCheckboxLabel:SetText("Track XP")

        -- Create dropdown for Color Choice
        local colorDropdown = CreateFrame("Frame", "ColorChoiceDropdown", SettingsFrame, "UIDropDownMenuTemplate")
        colorDropdown:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -9, -260)

        local function OnColorClick(self)
            UIDropDownMenu_SetSelectedID(colorDropdown, self:GetID())
            ColorChoice = self.value
            UpdateBorderColor()
            UpdateSettingsBorderColor()
            UpdateLevelUpFrameBorderColor()
        end

        local function InitializeColorDropdown(self, level)
            local info = UIDropDownMenu_CreateInfo()

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
        for i, color in ipairs(colors) do
            if color == ColorChoice then
                UIDropDownMenu_SetSelectedID(colorDropdown, i)
                break
            end
        end

        -- Create text label for color dropdown
        local colorDropdownLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        colorDropdownLabel:SetPoint("LEFT", colorDropdown, "RIGHT", -7, 0)
        colorDropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        colorDropdownLabel:SetText("Color")

        -- Create dropdown for Left Click Functionality
        local leftClickDropdown = CreateFrame("Frame", "LeftClickDropdown", SettingsFrame, "UIDropDownMenuTemplate")
        leftClickDropdown:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -9, -300)

        local function OnLeftClickOptionSelected(self)
            UIDropDownMenu_SetSelectedID(leftClickDropdown, self:GetID())
            LeftClickFunctionality = self.value
        end

        local function InitializeLeftClickDropdown(self, level)
            local info = UIDropDownMenu_CreateInfo()

            for k, v in pairs(functionalityOptions) do
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
        for i, option in ipairs(functionalityOptions) do
            if option == LeftClickFunctionality then
                UIDropDownMenu_SetSelectedID(leftClickDropdown, i)
                break
            end
        end

        -- Create text label for left click dropdown
        local leftClickDropdownLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        leftClickDropdownLabel:SetPoint("LEFT", leftClickDropdown, "RIGHT", -7, 0)
        leftClickDropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        leftClickDropdownLabel:SetText("Left Click")

        -- Create dropdown for Right Click Functionality
        local rightClickDropdown = CreateFrame("Frame", "RightClickDropdown", SettingsFrame, "UIDropDownMenuTemplate")
        rightClickDropdown:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -9, -340)

        local function OnRightClickOptionSelected(self)
            UIDropDownMenu_SetSelectedID(rightClickDropdown, self:GetID())
            RightClickFunctionality = self.value
        end

        local function InitializeRightClickDropdown(self, level)
            local info = UIDropDownMenu_CreateInfo()

            for k, v in pairs(functionalityOptions) do
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
        for i, option in ipairs(functionalityOptions) do
            if option == RightClickFunctionality then
                UIDropDownMenu_SetSelectedID(rightClickDropdown, i)
                break
            end
        end

        -- Create text label for right click dropdown
        local rightClickDropdownLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        rightClickDropdownLabel:SetPoint("LEFT", rightClickDropdown, "RIGHT", -7, 0)
        rightClickDropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        rightClickDropdownLabel:SetText("Right Click")

        -- Create dropdown for Time Color
        local timeColorDropdown = CreateFrame("Frame", "TimeColorDropdown", SettingsFrame, "UIDropDownMenuTemplate")
        timeColorDropdown:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -9, -380)

        local function OnTimeColorClick(self)
            UIDropDownMenu_SetSelectedID(timeColorDropdown, self:GetID())
            TimeColor = self.value
            timeText:SetTextColor(GetColor(TimeColor))
        end

        local function InitializeTimeColorDropdown(self, level)
            local info = UIDropDownMenu_CreateInfo()

            for k, v in pairs(colors) do
                if v ~= "None" then  -- Exclude "None" from being added to the dropdown
                    info = UIDropDownMenu_CreateInfo()
                    info.text = v
                    info.value = v
                    info.func = OnTimeColorClick
                    info.checked = (v == TimeColor)
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end

        UIDropDownMenu_Initialize(timeColorDropdown, InitializeTimeColorDropdown)
        UIDropDownMenu_SetWidth(timeColorDropdown, 100)
        UIDropDownMenu_SetButtonWidth(timeColorDropdown, 124)
        UIDropDownMenu_SetSelectedID(timeColorDropdown, 1)
        UIDropDownMenu_JustifyText(timeColorDropdown, "LEFT")

        -- Set the selected value based on current TimeColor
        for i, color in ipairs(colors) do
            if color == TimeColor then
                UIDropDownMenu_SetSelectedID(timeColorDropdown, i)
                break
            end
        end

        -- Create text label for time color dropdown
        local timeColorDropdownLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        timeColorDropdownLabel:SetPoint("LEFT", timeColorDropdown, "RIGHT", -7, 0)
        timeColorDropdownLabel:FontTemplate(nil, 12, "OUTLINE")
        timeColorDropdownLabel:SetText("Time Color")

        -- Create slider for Window Width
        local sliderWidth = CreateFrame("Slider", "WindowWidthSlider", SettingsFrame, "OptionsSliderTemplate")
        sliderWidth:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -420)
        sliderWidth:SetMinMaxValues(175, 250)
        sliderWidth:SetValueStep(1)
        sliderWidth:SetValue(WindowWidth)
        sliderWidth:SetScript("OnValueChanged", function(self, value)
            WindowWidth = value
            frame:SetWidth(value)  -- Adjust the main frame width

            -- Adjust the queue frame width
            if queueFrame then
                queueFrame:SetWidth(value)
                queueFrame.instanceTypeText:SetWidth(value)
                queueFrame.queueTimeText:SetWidth(value)
                queueFrame.avgQueueTimeText:SetWidth(value)
            end

            -- Adjust the flying frame width
            if flyingFrame then
                flyingFrame:SetWidth(value)
                flyingFrame.text:SetWidth(value)
                flyingFrame.mainLocationText:SetWidth(value)
                flyingFrame.subLocationText:SetWidth(value)
            end

            -- Adjust the level up frame width
            if levelUpFrame then
                levelUpFrame:SetWidth(value)
                levelUpText:SetWidth(value)
            end
        end)

        -- Create text label for width slider
        local sliderWidthLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        sliderWidthLabel:SetPoint("LEFT", sliderWidth, "RIGHT", 10, 0)
        sliderWidthLabel:FontTemplate(nil, 12, "OUTLINE")
        sliderWidthLabel:SetText("Window Width")

        -- Create slider for Window Height
        local sliderHeight = CreateFrame("Slider", "WindowHeightSlider", SettingsFrame, "OptionsSliderTemplate")
        sliderHeight:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -460)
        sliderHeight:SetMinMaxValues(25, 150)
        sliderHeight:SetValueStep(1)
        sliderHeight:SetValue(WindowHeight)
        sliderHeight:SetScript("OnValueChanged", function(self, value)
            WindowHeight = value
            local additionalHeight = 0
            if ShowLocation then
                additionalHeight = additionalHeight + 50
            end
            if ShowDate and not ShowLocation then
                additionalHeight = additionalHeight + 20
            end
            frame:SetHeight(value + additionalHeight)  -- Adjust the frame height
        end)

        -- Create text label for height slider
        local sliderHeightLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        sliderHeightLabel:SetPoint("LEFT", sliderHeight, "RIGHT", 10, 0)
        sliderHeightLabel:FontTemplate(nil, 12, "OUTLINE")
        sliderHeightLabel:SetText("Window Height")

        -- Create text label for version number
        local versionLabel = SettingsFrame:CreateFontString(nil, "OVERLAY")
        versionLabel:SetPoint("BOTTOM", SettingsFrame, "BOTTOM", 0, 5)
        versionLabel:FontTemplate(nil, 12, "OUTLINE")
        versionLabel:SetText("Version: " .. GetAddonVersion())
        versionLabel:SetTextColor(1, 0.8, 0)
        SettingsFrame:Show()
    end

    -- Left-click to perform selected functionality
    -- Right-click to perform selected functionality
    -- Ctrl + left-click to open the settings window
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = false
        end
    end)

    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and not isDragging then
            if IsControlKeyDown() then
                if not SettingsWindowOpen then
                    OpenSettingsWindow()
                end
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
                elseif LeftClickFunctionality == "Map" then
                    ToggleWorldMap()
                elseif LeftClickFunctionality == "Professions" then
                    ToggleSpellBook("professions")
                elseif LeftClickFunctionality == "Mount Journal" then
                    ToggleCollectionsJournal(1)
                elseif LeftClickFunctionality == "Pet Journal" then
                    ToggleCollectionsJournal(2)
                elseif LeftClickFunctionality == "None" then
                    -- Do nothing
                else
                    if not IsAddOnLoaded("Blizzard_Calendar") then
                        LoadAddOn("Blizzard_Calendar")
                    end
                    if Calendar_Toggle then
                        Calendar_Toggle()
                    end
                end
            end
        elseif button == "RightButton" then
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
            elseif RightClickFunctionality == "Map" then
                ToggleWorldMap()
            elseif RightClickFunctionality == "Professions" then -- Added handling for "Professions"
                ToggleSpellBook("professions")
            elseif RightClickFunctionality == "Mount Journal" then
                ToggleCollectionsJournal(1)
            elseif RightClickFunctionality == "Pet Journal" then
                ToggleCollectionsJournal(2)
            elseif RightClickFunctionality == "None" then
                -- Do nothing
            elseif RightClickFunctionality == "Calendar" then
                if not IsAddOnLoaded("Blizzard_Calendar") then
                    LoadAddOn("Blizzard_Calendar")
                end
                if Calendar_Toggle then
                    Calendar_Toggle()
                end
            end
        end
    end)

    local addonVersion = GetAddonVersion()
    frame:SetScript("OnEnter", function(self)
        if not (CombatWarning and inCombat) then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -5)
            GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -10)
            GameTooltip:AddLine("ElvUI Clock")
            GameTooltip:AddLine("Left-click: " .. LeftClickFunctionality, 1, 1, 1)
            GameTooltip:AddLine("Right-click: " .. RightClickFunctionality, 1, 1, 1)
            GameTooltip:AddLine("Ctrl + Left-click: Show Settings", 1, 1, 1)
            GameTooltip:AddDoubleLine(" ", "Version: " .. addonVersion, nil, nil, nil, 1, 0.8, 0)
            GameTooltip:Show()
        end
    end)

    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Add sender information to the mail indicator tooltip
    mailIndicator:SetScript("OnEnter", function(self)
        if not inCombat then  -- Only show tooltip if not in combat
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 10, 0)  -- Move 10 pixels to the right
            GameTooltip:ClearLines()
            GameTooltip:AddLine(HasNewMail() and HAVE_MAIL_FROM or MAIL_LABEL, 1, 1, 1)
            GameTooltip:AddLine(' ')
            for _, sender in pairs(mailSenders) do
                if sender then
                    GameTooltip:AddLine(sender)
                else
                    GameTooltip:AddLine(UNKNOWN)
                end
            end
            GameTooltip:Show()
        end
    end)

    mailIndicator:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    local wasSettingsWindowOpen = false
    -- Handle combat state changes
    function TimeDisplayAddon:PLAYER_REGEN_DISABLED()
        inCombat = true
        mailIndicator:Hide()  -- Hide mail indicator in combat
        if CombatWarning then
            timeText:SetTextColor(1, 0, 0)
        end
        if SettingsWindowOpen then
            wasSettingsWindowOpen = true
            SettingsFrame:Hide()
            SettingsWindowOpen = false
        end
    end

    function TimeDisplayAddon:PLAYER_REGEN_ENABLED()
        inCombat = false
        UpdateMailIndicator()  -- Update mail indicator when exiting combat
        if CombatWarning then
            timeText:SetTextColor(GetColor(TimeColor))
        end
        if wasSettingsWindowOpen then
            OpenSettingsWindow()
            wasSettingsWindowOpen = false
        end
    end

    -- Handle mail events
    function TimeDisplayAddon:MAIL_INBOX_UPDATE()
        PlayerHasMail = HasNewMail()
        UpdateMailIndicator()
    end

    function TimeDisplayAddon:UPDATE_PENDING_MAIL()
        PlayerHasMail = HasNewMail()
        UpdateMailIndicator()
    end

    -- Handle taxi events
    function TimeDisplayAddon:TAXIMAP_OPENED()
        local numNodes = NumTaxiNodes()
        for i = 1, numNodes do
            if TaxiNodeGetType(i) == "REACHABLE" then
                local button = _G["TaxiButton" .. i]
                button:HookScript("OnClick", function()
                    destinationName = TaxiNodeName(i)
                end)
            end
        end
    end

    function TimeDisplayAddon:PLAYER_CONTROL_LOST()
        ShowFlyingWindow(destinationName)
    end

    function TimeDisplayAddon:PLAYER_CONTROL_GAINED()
        HideFlyingWindow()
    end

    -- Handle LFG events
    function TimeDisplayAddon:LFG_UPDATE()
        UpdateQueueTimes()
    end

    function TimeDisplayAddon:LFG_QUEUE_STATUS_UPDATE()
        UpdateQueueTimes()
    end

    -- Initial location and mail indicator update
    UpdateLocation()
    UpdateMailIndicator()
    UpdateTimeDisplay()
    UpdateQueueTimes()
end

function TimeDisplayAddon:SetDefaults()
    if Use24HourTime == nil then
        PrintMessage('setting use 24 hour time to false')
        Use24HourTime = false  -- Default to 12-hour format
    end

    if FramePosition == nil then
        FramePosition = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", xOfs = 0, yOfs = 0 }
    end

    if SettingsFramePosition == nil then
        SettingsFramePosition = { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", xOfs = 0, yOfs = 0 }
    end

    if ColorChoice == nil then
        PrintMessage('setting color choice to class color')
        ColorChoice = "Class Color"
    end

    if LeftClickFunctionality == nil then
        PrintMessage('setting left click functionality to calendar')
        LeftClickFunctionality = "Calendar"
    end

    if RightClickFunctionality == nil then
        PrintMessage('setting right click functionality to stopwatch')
        RightClickFunctionality = "Stopwatch"
    end

    if WindowWidth == nil or WindowWidth < 175 then
        PrintMessage('setting window width to 150')
        WindowWidth = 175  -- Default window width
    end

    if WindowHeight == nil then
        PrintMessage('setting window height to 25')
        WindowHeight = 25  -- Default window height
    end

    if CombatWarning == nil then
        CombatWarning = false  -- Default to combat warning off
    end

    if ShowLocation == nil then
        ShowLocation = false  -- Default to show location off
    end

    if ShowMail == nil then
        ShowMail = false  -- Default to show mail indicator off
    end

    if PlayerHasMail == nil then
        PlayerHasMail = false  -- Default to no mail
    end

    if SettingsWindowOpen == true then
        SettingsWindowOpen = false  -- Default to settings window closed
    end

    if WindowLocked == nil then
        WindowLocked = false  -- Default to window not locked
    end

    if ShowDate == nil then
        ShowDate = false  -- Default to show date off
    end

    if TimeColor == nil then
        PrintMessage('setting time color to white')
        TimeColor = "White"  -- Default time color
    end

    if TrackingXP == nil then
        TrackingXP = false  -- Default to XP tracking off
    end
end