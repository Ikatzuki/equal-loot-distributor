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
function updateLinkItemList()
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
linkedItems = linkedItems or {}
linkedItemsCounter = linkedItemsCounter or 1
linkedItemsDetails = linkedItemsDetails or {}

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

-- Define the function to receive the main frame references
function SetMainFrameReferences(itemListContentReference)
    itemListContent = itemListContentReference
end
