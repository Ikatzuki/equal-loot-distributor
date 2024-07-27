-- Create the Blacklist Frame
local blacklistFrame = CreateFrame("Frame", "BlacklistFrame", UIParent, "BackdropTemplate")
blacklistFrame:SetSize(400, 400)
blacklistFrame:SetPoint("CENTER")
blacklistFrame:SetMovable(true)
blacklistFrame:EnableMouse(true)
blacklistFrame:RegisterForDrag("LeftButton")
blacklistFrame:SetScript("OnDragStart", blacklistFrame.StartMoving)
blacklistFrame:SetScript("OnDragStop", blacklistFrame.StopMovingOrSizing)
blacklistFrame:Hide()

-- Apply backdrop
blacklistFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- Blacklist Frame Title
local blacklistTitle = blacklistFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
blacklistTitle:SetPoint("TOP", 0, -10)
blacklistTitle:SetText("Blacklisted Items")

-- Close button for Blacklist Frame
local closeBlacklistButton = CreateFrame("Button", nil, blacklistFrame, "UIPanelCloseButton")
closeBlacklistButton:SetPoint("TOPRIGHT", -5, -5)

-- Item List Scroll Frame for Blacklist
local blacklistItemList = CreateFrame("ScrollFrame", nil, blacklistFrame, "UIPanelScrollFrameTemplate")
blacklistItemList:SetSize(360, 320)
blacklistItemList:SetPoint("TOPLEFT", 10, -40)

local blacklistItemListContent = CreateFrame("Frame")
blacklistItemListContent:SetSize(340, 320)
blacklistItemList:SetScrollChild(blacklistItemListContent)

-- Initialize the blacklist variable
blacklistedItems = blacklistedItems or {}
blacklistItemListContent.items = blacklistItemListContent.items or {} -- Initialize items field

-- Function to populate blacklist item list
function updateBlacklistItemList()
    -- Clear previous list
    for i = #blacklistItemListContent.items, 1, -1 do
        blacklistItemListContent.items[i]:Hide()
        table.remove(blacklistItemListContent.items, i)
    end

    -- Add items to list
    local i = 0
    for itemName, _ in pairs(blacklistedItems) do
        local row = CreateFrame("CheckButton", nil, blacklistItemListContent, "UICheckButtonTemplate")
        row:SetPoint("TOPLEFT", 0, -20 * i)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row, "RIGHT", 5, 0)
        row.text:SetText(itemName)
        row.itemName = itemName

        blacklistItemListContent.items = blacklistItemListContent.items or {}
        table.insert(blacklistItemListContent.items, row)
        i = i + 1
    end
end

-- Hook the button to open the blacklist
openBlacklistButton:SetScript("OnClick", function()
    updateBlacklistItemList()
    blacklistFrame:Show()
end)

closeBlacklistButton:SetScript("OnClick", function()
    blacklistFrame:Hide()
end)

-- Add a Button to Remove from Blacklist
local removeBlacklistButton = CreateFrame("Button", nil, blacklistFrame, "UIPanelButtonTemplate")
removeBlacklistButton:SetSize(150, 30)
removeBlacklistButton:SetPoint("BOTTOM", 0, 20)
removeBlacklistButton:SetText("Remove from Blacklist")

removeBlacklistButton:SetScript("OnClick", function()
    for _, row in ipairs(blacklistItemListContent.items) do
        if row:GetChecked() then
            blacklistedItems[row.itemName] = nil
        end
    end

    updateItemList()
    updateLinkItemList()
    updateBlacklistItemList()
end)

-- Function to save the blacklist
function SaveBlacklist()
    EqualLootDistributorBlacklistDB = blacklistedItems
end

-- Function to load the blacklist
function LoadBlacklist()
    if EqualLootDistributorBlacklistDB then
        blacklistedItems = EqualLootDistributorBlacklistDB
    else
        blacklistedItems = {}
    end
end
