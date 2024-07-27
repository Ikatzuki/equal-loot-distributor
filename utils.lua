function distributeItems(playerCountInput, itemListContent, linkedItemsDetails)
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
    distributionFrame:SetResizable(true)
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
end
