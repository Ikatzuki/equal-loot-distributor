-- Create the main frame
local frame = CreateFrame("Frame", "EqualLootDistributor", UIParent, "BackdropTemplate")
frame:SetSize(400, 400)  -- Increased height for more space
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetResizable(true)  -- Allow resizing
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
playerCountLabel:SetPoint("TOPRIGHT", -100, -40)  -- Adjusted position
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
itemList:SetSize(360, 220)  -- Adjusted width to fit within the UI
itemList:SetPoint("TOPLEFT", 10, -80)  -- Adjusted position

local itemListContent = CreateFrame("Frame")
itemListContent:SetSize(340, 220)  -- Adjusted width to match the scroll frame
itemList:SetScrollChild(itemListContent)

-- Initialize itemListContent.items
itemListContent.items = {}

-- Function to populate item list from player's bags and combine stacks
local function updateItemList()
    local items = {}
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                local itemLink = itemInfo.hyperlink
                local itemCount = itemInfo.stackCount
                local itemName = GetItemInfo(itemLink)
                if items[itemName] then
                    items[itemName].count = items[itemName].count + itemCount
                else
                    items[itemName] = {name = itemName, count = itemCount, link = itemLink}
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
distributeButton:SetPoint("BOTTOM", 0, 20)  -- Adjusted position for more space
distributeButton:SetText("Distribute")

-- Add Link Items Button
local linkItemsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
linkItemsButton:SetSize(100, 30)
linkItemsButton:SetPoint("BOTTOM", distributeButton, "TOP", 0, 10)
linkItemsButton:SetText("Link Items")

-- Create the Linking Frame
local linkingFrame = CreateFrame("Frame", "LinkingFrame", UIParent, "BackdropTemplate")
linkingFrame:SetSize(400, 400)
linkingFrame:SetPoint("CENTER")
linkingFrame:SetMovable(true)
linkingFrame:EnableMouse(true)
linkingFrame:RegisterForDrag("LeftButton")
linkingFrame:SetScript("OnDragStart", linkingFrame.StartMoving)
linkingFrame:SetScript("OnDragStop", linkingFrame.StopMovingOrSizing)
linkingFrame:Hide()

-- Apply backdrop
linkingFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- Linking Frame Title
local linkingTitle = linkingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
linkingTitle:SetPoint("TOP", 0, -10)
linkingTitle:SetText("Link Items")

-- Close button for Linking Frame
local closeLinkingButton = CreateFrame("Button", nil, linkingFrame, "UIPanelCloseButton")
closeLinkingButton:SetPoint("TOPRIGHT", -5, -5)

-- Item List Scroll Frame for Linking
local linkItemList = CreateFrame("ScrollFrame", nil, linkingFrame, "UIPanelScrollFrameTemplate")
linkItemList:SetSize(360, 320)
linkItemList:SetPoint("TOPLEFT", 10, -40)

local linkItemListContent = CreateFrame("Frame")
linkItemListContent:SetSize(340, 320)
linkItemList:SetScrollChild(linkItemListContent)

-- Initialize linkItemListContent.items
linkItemListContent.items = {}

-- Function to populate linking item list
local function updateLinkItemList()
    local items = {}
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                local itemLink = itemInfo.hyperlink
                local itemCount = itemInfo.stackCount
                local itemName = GetItemInfo(itemLink)
                if items[itemName] then
                    items[itemName].count = items[itemName].count + itemCount
                else
                    items[itemName] = {name = itemName, count = itemCount, link = itemLink}
                end
            end
        end
    end

    -- Clear previous list
    for i = #linkItemListContent.items, 1, -1 do
        linkItemListContent.items[i]:Hide()
        table.remove(linkItemListContent.items, i)
    end

    -- Add items to list
    local i = 0
    for _, item in pairs(items) do
        local row = CreateFrame("CheckButton", nil, linkItemListContent, "UICheckButtonTemplate")
        row:SetPoint("TOPLEFT", 0, -20 * i)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row, "RIGHT", 5, 0)
        row.text:SetText(item.name .. " x" .. item.count)
        row.itemLink = item.link

        linkItemListContent.items = linkItemListContent.items or {}
        table.insert(linkItemListContent.items, row)
        i = i + 1
    end
end

-- Link Items Logic
local linkedItems = {}
local linkedItemsCounter = 1
local linkedItemsDetails = {}

linkItemsButton:SetScript("OnClick", function()
    updateLinkItemList()
    linkingFrame:Show()
end)

closeLinkingButton:SetScript("OnClick", function()
    linkingFrame:Hide()
end)

-- Add a Button to Confirm Linking
local confirmLinkButton = CreateFrame("Button", nil, linkingFrame, "UIPanelButtonTemplate")
confirmLinkButton:SetSize(100, 30)
confirmLinkButton:SetPoint("BOTTOM", 0, 20)
confirmLinkButton:SetText("Confirm Linking")

local function updateMainItemListWithLinkedItems(linkedItems)
    -- Clear linked items from the main item list
    local newItemList = {}
    for _, row in ipairs(itemListContent.items) do
        local removeItem = false
        for _, linkedItem in ipairs(linkedItems) do
            if row.itemLink == linkedItem then
                removeItem = true
                break
            end
        end
        if not removeItem then
            table.insert(newItemList, row)
        else
            row:Hide()
        end
    end

    itemListContent.items = newItemList

    -- Add a new row for the linked items
    local linkedItemCount = 0
    local linkedItemDetailText = ""
    for _, row in ipairs(linkItemListContent.items) do
        if row:GetChecked() then
            local itemCount = tonumber(row.text:GetText():match("%d+$"))
            linkedItemCount = linkedItemCount + itemCount
            linkedItemDetailText = linkedItemDetailText .. row.text:GetText() .. "\n"
        end
    end

    local linkedRow = CreateFrame("CheckButton", nil, itemListContent, "UICheckButtonTemplate")
    linkedRow:SetPoint("TOPLEFT", 0, -20 * (#itemListContent.items + 1))
    linkedRow.text = linkedRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    linkedRow.text:SetPoint("LEFT", linkedRow, "RIGHT", 5, 0)
    linkedRow.text:SetText("Linked Items #" .. linkedItemsCounter .. " x" .. linkedItemCount)
    linkedRow.itemLink = "Linked Items #" .. linkedItemsCounter  -- A special identifier for linked items

    linkedItemsDetails["Linked Items #" .. linkedItemsCounter] = linkedItemDetailText

    linkedRow:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Linked Items")
        GameTooltip:AddLine(linkedItemsDetails[self.itemLink], 1, 1, 1)
        GameTooltip:Show()
    end)

    linkedRow:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    table.insert(itemListContent.items, linkedRow)
    linkedItemsCounter = linkedItemsCounter + 1

    -- Reposition the items
    for i, row in ipairs(itemListContent.items) do
        row:SetPoint("TOPLEFT", 0, -20 * (i - 1))
    end
end

confirmLinkButton:SetScript("OnClick", function()
    linkedItems = {}
    for _, row in ipairs(linkItemListContent.items) do
        if row:GetChecked() then
            table.insert(linkedItems, row.itemLink)
        end
    end

    if #linkedItems > 0 then
        updateMainItemListWithLinkedItems(linkedItems)
    end

    linkingFrame:Hide()
end)

-- Function to handle distribution
distributeButton:SetScript("OnClick", function()
    local playerCount = tonumber(playerCountInput:GetText())
    if not playerCount or playerCount <= 0 then
        print("Invalid number of players.")
        return
    end

    print("Player count: " .. playerCount)

    local selectedItems = {}
    for _, row in ipairs(itemListContent.items) do
        if row:GetChecked() then
            table.insert(selectedItems, row.itemLink)
        end
    end

    if #selectedItems == 0 then
        print("No items selected.")
        return
    end

    print("Selected items:")
    for _, itemLink in ipairs(selectedItems) do
        print(itemLink)
    end

    -- Combine item counts from all stacks and account for linked items
    local itemCounts = {}
    local linkedItemsToDistribute = {}

    for _, itemLink in ipairs(selectedItems) do
        -- Check if it's a linked item group
        if string.match(itemLink, "^Linked Items #") then
            print("Processing linked item group: " .. itemLink)
            local linkedGroup = linkedItemsDetails[itemLink]
            for linkedItemName, linkedItemCount in string.gmatch(linkedGroup, "([^\n]+) x(%d+)") do
                print("  Linked item: " .. linkedItemName .. ", Count: " .. linkedItemCount)
                for i = 1, tonumber(linkedItemCount) do
                    table.insert(linkedItemsToDistribute, linkedItemName)
                end
            end
        else
            local itemName = GetItemInfo(itemLink)
            itemCounts[itemName] = itemCounts[itemName] or 0
            for bag = 0, 4 do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                    if itemInfo and itemInfo.hyperlink == itemLink then
                        itemCounts[itemName] = itemCounts[itemName] + itemInfo.stackCount
                    end
                end
            end
        end
    end

    -- Debug print the combined item counts
    for itemName, itemCount in pairs(itemCounts) do
        print("Combined Item: " .. itemName .. ", Total Count: " .. itemCount)
    end

    -- Distribution logic
    local distribution = {}
    for i = 1, playerCount do
        distribution[i] = {}
    end

    -- Distribute normal items
    local playerIndex = 1
    for itemName, itemCount in pairs(itemCounts) do
        if itemCount <= playerCount then
            for i = 1, itemCount do
                table.insert(distribution[playerIndex], {name = itemName, count = 1})
                playerIndex = playerIndex + 1
                if playerIndex > playerCount then
                    playerIndex = 1
                end
            end
        else
            local itemsPerPlayer = math.floor(itemCount / playerCount)
            local leftovers = itemCount % playerCount

            print("Items per player: " .. itemsPerPlayer .. ", Leftovers: " .. leftovers)

            for i = 1, playerCount do
                table.insert(distribution[i], {name = itemName, count = itemsPerPlayer})
            end

            -- If there are leftovers, assign them to the organizer (index 0)
            if leftovers > 0 then
                distribution[0] = distribution[0] or {}
                table.insert(distribution[0], {name = itemName, count = leftovers})
            end
        end
    end

    -- Distribute linked items randomly
    playerIndex = 1
    for _, linkedItem in ipairs(linkedItemsToDistribute) do
        print("Distributing linked item: " .. linkedItem .. " to player " .. playerIndex)
        table.insert(distribution[playerIndex], {name = linkedItem, count = 1})
        playerIndex = playerIndex + 1
        if playerIndex > playerCount then
            playerIndex = 1
        end
    end

    -- Display results
    local distributionFrame = CreateFrame("Frame", "EQLD_DistributionFrame", UIParent, "BackdropTemplate")
    distributionFrame:SetSize(400, 300)
    distributionFrame:SetPoint("CENTER")
    distributionFrame:SetMovable(true)
    distributionFrame:EnableMouse(true)
    distributionFrame:RegisterForDrag("LeftButton")
    distributionFrame:SetResizable(true)  -- Allow resizing
    distributionFrame:SetResizeBounds(200, 200)

    distributionFrame:SetScript("OnDragStart", distributionFrame.StartMoving)
    distributionFrame:SetScript("OnDragStop", distributionFrame.StopMovingOrSizing)

    -- Apply backdrop
    distributionFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Declare playerList and playerListContent before using them
    local playerList = CreateFrame("ScrollFrame", nil, distributionFrame, "UIPanelScrollFrameTemplate")
    local playerListContent = CreateFrame("Frame")

    -- Add resize handle
    local resizeButton = CreateFrame("Button", nil, distributionFrame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT")
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            distributionFrame:StartSizing("BOTTOMRIGHT")
            self:SetScript("OnUpdate", function()
                local width = distributionFrame:GetWidth()
                local height = distributionFrame:GetHeight()
                playerList:SetSize(width - 30, height - 70)
                playerListContent:SetSize(width - 50, height - 70)
            end)
        end
    end)

    resizeButton:SetScript("OnMouseUp", function(self)
        distributionFrame:StopMovingOrSizing()
        self:SetScript("OnUpdate", nil)
    end)

    local distributionTitle = distributionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    distributionTitle:SetPoint("TOP", 0, -10)
    distributionTitle:SetText("Distribution Results")

    -- Close button
    local closeDistributionButton = CreateFrame("Button", nil, distributionFrame, "UIPanelCloseButton")
    closeDistributionButton:SetPoint("TOPRIGHT", -5, -5)

    playerList:SetSize(370, 220)
    playerList:SetPoint("TOPLEFT", 10, -40)

    playerListContent:SetSize(350, 220)
    playerList:SetScrollChild(playerListContent)

    for i, playerItems in pairs(distribution) do
        local row = playerListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row:SetPoint("TOPLEFT", 0, -20 * (i - 1))
        local itemText = ""
        if i == 0 then
            itemText = "Organizer keeps: "
        else
            itemText = "Player " .. i .. ": "
        end
        for _, item in ipairs(playerItems) do
            itemText = itemText .. item.name .. " x" .. item.count .. ", "
        end
        row:SetText(itemText:sub(1, -3))
    end

    distributionFrame:Show()
end)

-- Slash command to open the addon
SLASH_EQUALLOOTDISTRIBUTOR1 = "/eld"
SlashCmdList["EQUALLOOTDISTRIBUTOR"] = function()
    updateItemList()
    frame:Show()
end
