local HCWatcher = CreateFrame("Frame")

-- Register events for interactions we want to track
HCWatcher:RegisterEvent("ADDON_LOADED")
HCWatcher:RegisterEvent("AUCTION_HOUSE_SHOW")
HCWatcher:RegisterEvent("TRADE_SHOW")
HCWatcher:RegisterEvent("TRADE_REQUEST")
HCWatcher:RegisterEvent("GROUP_ROSTER_UPDATE")
HCWatcher:RegisterEvent("PARTY_INVITE_REQUEST")
HCWatcher:RegisterEvent("MAIL_INBOX_UPDATE")
HCWatcher:RegisterEvent("MAIL_SHOW")

-- Allowed player names (all lowercase, fixed spelling)
local allowedPlayers = {
    ["sheist"] = true,
    ["recipe"] = true,
    ["blackfungus"] = true,
    ["zazabinks"] = true,
    ["milkedging"] = true,
    ["roachtfout"] = true
}

local allowedGuild = "Orgrimmar Bloods"

-- Ensure HCWatcherDB is initialized
local function EnsureDBInitialized()
    if not HCWatcherDB then
        HCWatcherDB = {} -- Create storage if missing
    end
end

-- 📜 UI Panel for Infraction Log
local HCWatcherFrame = CreateFrame("Frame", "HCWatcherUI", UIParent, "BasicFrameTemplateWithInset")
HCWatcherFrame:SetSize(400, 300)
HCWatcherFrame:SetPoint("CENTER")
HCWatcherFrame:SetMovable(true)
HCWatcherFrame:EnableMouse(true)
HCWatcherFrame:RegisterForDrag("LeftButton")
HCWatcherFrame:SetScript("OnDragStart", HCWatcherFrame.StartMoving)
HCWatcherFrame:SetScript("OnDragStop", HCWatcherFrame.StopMovingOrSizing)
HCWatcherFrame:Hide()

-- Title Text
HCWatcherFrame.title = HCWatcherFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
HCWatcherFrame.title:SetPoint("TOP", HCWatcherFrame, "TOP", 0, -5)
HCWatcherFrame.title:SetJustifyH("CENTER")
HCWatcherFrame.title:SetText("HCWatcher Infraction Log")

-- Scrollable Log
local scrollFrame = CreateFrame("ScrollFrame", nil, HCWatcherFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(360, 220)
scrollFrame:SetPoint("TOP", HCWatcherFrame, "TOP", 0, -40)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(360, 220)
scrollFrame:SetScrollChild(content)

-- Log Text
HCWatcherFrame.logText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
HCWatcherFrame.logText:SetPoint("TOPLEFT", 10, -10)
HCWatcherFrame.logText:SetJustifyH("LEFT")
HCWatcherFrame.logText:SetText("No infractions recorded.")

-- Close Button
local closeButton = CreateFrame("Button", nil, HCWatcherFrame, "UIPanelButtonTemplate")
closeButton:SetSize(80, 22)
closeButton:SetPoint("BOTTOM", 0, 10)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function() HCWatcherFrame:Hide() end)

-- 📌 Function to Update Log UI (Restored!)
local function UpdateLogUI()
    EnsureDBInitialized()

    local logText = ""
    for player, logs in pairs(HCWatcherDB) do
        logText = logText .. "|cffffcc00" .. player .. ":|r\n"
        for _, log in ipairs(logs) do
            logText = logText .. "   - " .. log .. "\n"
        end
    end

    if logText == "" then
        logText = "No infractions recorded."
    end

    HCWatcherFrame.logText:SetText(logText)
end

-- 📜 Infraction Banner System
local bannerFrame = CreateFrame("Frame", "HCWatcherBanner", UIParent)
bannerFrame:SetSize(600, 80)
bannerFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)
bannerFrame:Hide()

-- Banner Background
bannerFrame.texture = bannerFrame:CreateTexture(nil, "BACKGROUND")
bannerFrame.texture:SetAllPoints(true)
bannerFrame.texture:SetColorTexture(0, 0, 0, 0.7)

-- Banner Text
bannerFrame.text = bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
bannerFrame.text:SetPoint("CENTER", 0, 0)
bannerFrame.text:SetTextColor(1, 0.2, 0.2, 1)
bannerFrame.text:SetText("INFRACTION DETECTED!")

-- Function to Show the Banner and Play Sound
local function ShowInfractionBanner(player, action)
    bannerFrame.text:SetText("|cffffcc00" .. player .. "|r has committed an infraction: |cffff0000" .. action .. "!|r")
    bannerFrame:Show()
    PlaySound(8959, "Master") -- Play warning sound

    C_Timer.After(5, function()
        bannerFrame:Hide()
    end)
end

-- Function to Broadcast Infractions to Guild Chat
local function BroadcastInfraction(player, action)
    local message = "[HCWatcher] ALERT: " .. player .. " has " .. action .. "!"
    if IsInGuild() then
        SendChatMessage(message, "GUILD") -- Send infraction alert to guild chat
    end
end

-- Function to Log Violations and Trigger Banner
local function LogViolation(player, action)
    EnsureDBInitialized()
    local timestamp = date("%Y-%m-%d %H:%M:%S")
    local entry = string.format("[%s] %s - %s", timestamp, player, action)

    if not HCWatcherDB[player] then
        HCWatcherDB[player] = {}
    end
    table.insert(HCWatcherDB[player], entry)

    ShowInfractionBanner(player, action)
    print("|cffff0000[HCWatcher] ALERT: " .. player .. " has " .. action .. "!|r")

    -- 🚨 Broadcast to guild chat
    BroadcastInfraction(player, action)

    -- 🚨 Update log UI so it reflects the change
    UpdateLogUI()
end

-- Slash Command to Open Log UI (Fixed)
SLASH_HCWATCHER1 = "/hcwatcher"
SlashCmdList["HCWATCHER"] = function()
    UpdateLogUI()
    HCWatcherFrame:Show()
end

-- ✅ `/hcwatcherclear` - Clears the infraction log UI
SLASH_HCWATCHERCLEAR1 = "/hcwatcherclear"
SlashCmdList["HCWATCHERCLEAR"] = function()
    HCWatcherDB = {}
    print("|cffffcc00[HCWatcher] Infraction log cleared.|r")
end

local isInGuild = function(unit)
    local gname, _, _ = GetGuildInfo(unit)
    if gname == allowedGuild then
        return true
        end
    return false
end

-- 🔄 Event Handler (Everything Works Now)
HCWatcher:SetScript("OnEvent", function(self, event, ...)
    EnsureDBInitialized()

    if event == "ADDON_LOADED" and ... == "HCWatcher" then
        print("|cffffcc00[HCWatcher] Addon Loaded Successfully.|r")

    elseif event == "AUCTION_HOUSE_SHOW" then
        LogViolation(UnitName("player"), "Used the Auction House")
        C_Timer.After(0.1, function() CloseAuctionHouse() end)

    elseif event == "TRADE_SHOW" or event == "TRADE_REQUEST" then
        local target = UnitName("NPC")
        if target and not isInGuild(target) then
            LogViolation(UnitName("player"), "Attempted to trade with " .. target)
            CancelTrade()
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name and not allowedPlayers[string.lower(name)] then
                LogViolation(UnitName("player"), "Grouped with outsider " .. name)
                LeaveParty()
            end
        end

    elseif event == "PARTY_INVITE_REQUEST" then
        local inviter = ...
        if inviter and not allowedPlayers[string.lower(inviter)] then
            LogViolation(UnitName("player"), "Accepted a party invite from " .. inviter)
            DeclineGroup()
            StaticPopup_Hide("PARTY_INVITE")
        end
    end
end)
