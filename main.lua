-- Initialize the blacklistedItems table
blacklistedItems = blacklistedItems or {}

-- Initialize global UI elements early
openBlacklistButton = nil
blacklistButton = nil
linkItemsButton = nil

-- Initialize the main frame
local frame = CreateFrame("Frame", "EqualLootDistributor", UIParent, "BackdropTemplate")
frame:SetSize(400, 400)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetResizable(true)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint()
    EqualLootDistributorDB = {point = point, relativePoint = relativePoint, xOffset = xOffset, yOffset = yOffset}
end)

-- Apply backdrop
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- Restore position
frame:SetScript("OnShow", function(self)
    if EqualLootDistributorDB then
        self:ClearAllPoints()
        self:SetPoint(EqualLootDistributorDB.point, UIParent, EqualLootDistributorDB.relativePoint, EqualLootDistributorDB.xOffset, EqualLootDistributorDB.yOffset)
    end
end)

frame:Hide()

-- Header
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("Equal Loot Distributor")

-- Close button
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Player Count Input
local playerCountLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
playerCountLabel:SetPoint("TOPRIGHT", -100, -40)
playerCountLabel:SetText("Number of Players:")

local playerCountInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
playerCountInput:SetSize(50, 20)
playerCountInput:SetPoint("LEFT", playerCountLabel, "RIGHT", 10, 0)
playerCountInput:SetAutoFocus(false)
playerCountInput:SetNumeric(true)

-- Function to clear focus when Enter is pressed
playerCountInput:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
end)

-- Function to clear focus when clicking outside
local clickFrame = CreateFrame("Frame", nil, UIParent)
clickFrame:SetFrameStrata("TOOLTIP")
clickFrame:SetAllPoints(UIParent)
clickFrame:EnableMouse(true)
clickFrame:Hide()

clickFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not MouseIsOver(playerCountInput) then
        playerCountInput:ClearFocus()
    end
end)

playerCountInput:SetScript("OnEditFocusGained", function()
    clickFrame:Show()
end)

playerCountInput:SetScript("OnEditFocusLost", function()
    clickFrame:Hide()
end)

-- Item List Scroll Frame
local itemList = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
itemList:SetSize(360, 220)
itemList:SetPoint("TOPLEFT", 10, -80)

local itemListContent = CreateFrame("Frame")
itemListContent:SetSize(340, 220)
itemList:SetScrollChild(itemListContent)

-- Initialize itemListContent.items
itemListContent.items = {}

-- Function to populate item list from player's bags and combine stacks
function updateItemList()
    local items = {}
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                local itemLink = itemInfo.hyperlink
                local itemCount = itemInfo.stackCount
                local itemName = GetItemInfo(itemLink)
                if not blacklistedItems[itemName] then
                    if items[itemName] then
                        items[itemName].count = items[itemName].count + itemCount
                    else
                        items[itemName] = {name = itemName, count = itemCount, link = itemLink}
                    end
                end
            end
        end
    end

    -- Clear previous list
    for i = #itemListContent.items, 1, -1 do
        itemListContent.items[i]:Hide()
        table.remove(itemListContent.items, i)
    end

    -- Add items to list
    local i = 0
    for _, item in pairs(items) do
        local row = CreateFrame("CheckButton", nil, itemListContent, "UICheckButtonTemplate")
        row:SetPoint("TOPLEFT", 0, -20 * i)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row, "RIGHT", 5, 0)
        row.text:SetText(item.name .. " x" .. item.count)
        row.itemLink = item.link

        itemListContent.items = itemListContent.items or {}
        table.insert(itemListContent.items, row)
        i = i + 1
    end
end

-- Distribute Button
local distributeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
distributeButton:SetSize(100, 30)
distributeButton:SetPoint("BOTTOM", 0, 20)
distributeButton:SetText("Distribute")

-- Add Link Items Button
linkItemsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
linkItemsButton:SetSize(100, 30)
linkItemsButton:SetPoint("BOTTOM", distributeButton, "TOP", 0, 10)
linkItemsButton:SetText("Link Items")

-- Add Open Blacklist Button
openBlacklistButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
openBlacklistButton:SetSize(120, 30)
openBlacklistButton:SetPoint("RIGHT", distributeButton, "LEFT", -10, 0)
openBlacklistButton:SetText("Open Blacklist")

-- Add Blacklist Items Button
blacklistButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
blacklistButton:SetSize(120, 30)
blacklistButton:SetPoint("LEFT", distributeButton, "RIGHT", 10, 0)
blacklistButton:SetText("Blacklist Items")

-- Ensure the linking.lua and blacklist.lua scripts can access the main frame's references
C_Timer.After(0, function()
    SetMainFrameReferences(itemListContent)
end)

-- Function to handle distribution
distributeButton:SetScript("OnClick", function()
    distributeItems(playerCountInput, itemListContent, linkedItemsDetails)
end)

-- Function to handle blacklisting items
blacklistButton:SetScript("OnClick", function()
    for _, row in ipairs(itemListContent.items) do
        if row:GetChecked() then
            local itemName = GetItemInfo(row.itemLink)
            blacklistedItems[itemName] = true
        end
    end

    updateItemList()
    updateLinkItemList()
end)

-- Slash command to open the addon
SLASH_EQUALLOOTDISTRIBUTOR1 = "/eld"
SlashCmdList["EQUALLOOTDISTRIBUTOR"] = function()
    updateItemList()
    frame:Show()
end

-- Load blacklist and update UI on load
local function onAddonLoaded(arg1)
    if arg1 == "EqualLootDistributor" then
        LoadBlacklist()
        updateItemList()
        updateLinkItemList()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGOUT" then
        SaveBlacklist()
    elseif event == "ADDON_LOADED" then
        onAddonLoaded(arg1)
    end
end)
