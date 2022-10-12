-- To get detailed error messages ingame 
-- /console scriptErrors 1
DanesOfHonor = LibStub("AceAddon-3.0"):NewAddon("DanesOfHonor", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0",
    "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

DOHGlobals = {
    COMMPREFIX = "DOHGA",
    AUCTIONINPROGRESS = false,
    MINIMUMBID = 100,
    BIDTIMER = 20,
    BIDTYPES = {
        BIDHALF = 1,
        [1] = "HALF",
        BIDMIN = 2,
        [2] = "FIXED",
        MAINSPEC = 3,
        [3] = "MAINSPEC",
        DUALSPEC = 4,
        [4] = "DUALSPEC",
        OFFSPEC = 5,
        [5] = "OFFSPEC"
    },
    UPDATE = {
        NONE = 0,
        READ = 1,
        WRITE = 2
    },
    BIDHELPMESSAGES = {"|cAAFF0000*|r To bid half your points: /doh bid half",
                       "|cAAFF0000*|r To bid the fixed price (100 points): /roll 100",
                       "|cAAFF0000*|r To roll for mainspec: /roll 99", "|cAAFF0000*|r To roll for dualspec: /roll 98",
                       "|cAAFF0000*|r To roll for offspec: /roll 97"}
}

function DanesOfHonor:OnInitialize()
    if not (DOHGADB) then
        DOHGADB = {}
    end
    if (not DOHGADB.ROSTER) then
        DOHGADB.ROSTER = {}
    end
    if (not DOHGADB.DUALSPEC) then
        DOHGADB.DUALSPEC = {}
    end

    DanesOfHonor:RegisterComm(DOHGlobals.COMMPREFIX)
    DanesOfHonor:RegisterChatCommand('doh', 'HandleChatCommand')
    DanesOfHonor:RegisterEvent("CHAT_MSG_SYSTEM")
    DanesOfHonor:RegisterEvent("RAID_ROSTER_UPDATE")
    DanesOfHonor:RegisterEvent("GROUP_ROSTER_UPDATE")
    DanesOfHonor:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
    DanesOfHonor:RegisterEvent("PLAYER_LOGOUT")

    DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000Danes|r |cAAFFFFFFof|r |cAAFF0000Honor|r guild addon loaded!")
end

function DanesOfHonor:PLAYER_LOGOUT(...)
    local guildRoster = {};
    local normalizedRealm = "-" .. GetNormalizedRealmName();
    local numTotalGuildMembers = GetNumGuildMembers();
    for i = 1, numTotalGuildMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote = GetGuildRosterInfo(i);
        if (name) then
            local n = name:gsub(normalizedRealm, "");

            tinsert(guildRoster, {
                fullName = name,
                name = n,
                rank = rank,
                rankIndex = rankIndex,
                level = level,
                class = class,
                note = note,
                officerNote = officernote
            });

        end
    end

    DOHGADB.GuildRoster = guildRoster;
end

function DanesOfHonor:PARTY_LOOT_METHOD_CHANGED(event)
    DanesOfHonor:GROUP_ROSTER_UPDATE(event)
end

function DanesOfHonor:RAID_ROSTER_UPDATE(event)
    DanesOfHonor:GROUP_ROSTER_UPDATE(event)
end

function DanesOfHonor:GROUP_ROSTER_UPDATE(event)
    for i = 1, MAX_RAID_MEMBERS do
        name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
        if (name) then
            if (not DOHGADB.ROSTER[name]) then
                DOHGADB.ROSTER[name] = {
                    points = 0,
                    state = DOHGlobals.UPDATE.READ,
                    class = class,
                    plusOne = 0
                }
            end
            DOHGADB.ROSTER[name].isML = isML
        end
    end
    DanesOfHonor:ProcessRoster()
end

-- /script DanesOfHonor:ProcessRoster() 
function DanesOfHonor:ProcessRoster()
    local normalizedRealm = "-" .. GetNormalizedRealmName()
    local numTotalGuildMembers = GetNumGuildMembers()
    for i = 1, numTotalGuildMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote = GetGuildRosterInfo(i);
        if (name) then
            local n = name:gsub(normalizedRealm, "")
            if (DOHGADB.ROSTER[n]) then
                if (DOHGADB.ROSTER[n].state == DOHGlobals.UPDATE.READ) then
                    DOHGADB.ROSTER[n].points = tonumber(officernote)
                    if (not DOHGADB.ROSTER[n].points) then
                        DOHGADB.ROSTER[n].points = 0
                    end
                elseif (DOHGADB.ROSTER[n].state == DOHGlobals.UPDATE.WRITE) then
                    if (CanEditOfficerNote()) then
                        GuildRosterSetOfficerNote(i, DOHGADB.ROSTER[n].points)
                    end
                end
                DOHGADB.ROSTER[n].state = DOHGlobals.UPDATE.NONE
            end
        end
    end
end

-- /script DanesOfHonor:PrintRoster()
function DanesOfHonor:PrintRoster()
    --  print("ROSTER:")
    for name, data in pairs(DOHGADB.ROSTER) do
        local s = name;
        for k, v in pairs(DOHGADB.ROSTER[name]) do
            s = s .. string.format(" (%s => %s)", k, tostring(v))
        end
        --    print(s)
    end
end

function DanesOfHonor:CHAT_MSG_SYSTEM(event, message)
    local name, roll, min, max = message:match('^(%S+) rolls (%d+) %((%d+)-(%d+)%)$')
    if (name) then
        DanesOfHonor:HandleRoll(name, tonumber(roll), tonumber(min), tonumber(max))
    end
end

function DanesOfHonor:HandleChatCommand(input)
    local command = string.lower(FixNil(DanesOfHonor:GetArgs(input)))
    if (command == "auction") then
        if (DOHGADB.ROSTER[UnitName("PLAYER")].isML) then
            local _, itemLink = DanesOfHonor:GetArgs(input, 2);
            if (itemLink) then
                DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "auction start " .. itemLink, "RAID")
                SendChatMessage(string.format("%s started an aution for %s!", UnitName("PLAYER"), itemLink),
                    "RAID_WARNING")
                for _, m in pairs(DOHGlobals.BIDHELPMESSAGES) do
                    SendChatMessage(m, "RAID")
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000/doh auction|r is missing item link parameter!")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000DOHGA|r: Only the master looter can start an auction!")
        end
    elseif (command == "bid") then
        if (not DOHGlobals.AUCTIONINPROGRESS) then
            DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000DOHGA|r: There are no active auctions!")
            return
        end

        local _, value = DanesOfHonor:GetArgs(input, 2);
        if (value == "half") then
            local currentPoints = DOHGADB.ROSTER[UnitName("PLAYER")].points
            local halfPoints = math.ceil(currentPoints / 2)
            if (halfPoints > DOHGlobals.MINIMUMBID) then
                DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "auction bid half", "RAID")
                BidWindow:Hide()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000DOHGA|r: You do not have enough points for this bid!")
            end
        else
            DanesOfHonor:PrintRollHelp()
        end
    elseif (command == "ml") then
        if (DOHGADB.ROSTER[UnitName("PLAYER")].isML) then
            if (MasterLooterWindow:IsVisible()) then
                MasterLooterWindow:Hide();
            else
                MasterLooterWindow:Show();
            end
        end
    end
end

function DanesOfHonor:OnCommReceived(prefix, text, distribution, sender, e)
    if (prefix == DOHGlobals.COMMPREFIX) then
        local action, command, arg1 = DanesOfHonor:GetArgs(text, 3)
        if (action == "auction") then
            if (command == "start") then
                if (arg1) then
                    BidWindow.StartAuction(arg1)
                    if (DOHGADB.ROSTER[UnitName("PLAYER")].isML) then
                        IncomingBidsWindow.StartAuction(arg1)
                    end
                end
            elseif (command == "bid") then
                if (arg1 == "half") then
                    local currentPoints = DOHGADB.ROSTER[sender].points
                    local halfPoints = math.ceil(currentPoints / 2)
                    if (halfPoints > DOHGlobals.MINIMUMBID) then
                        IncomingBidsWindow.AddBid(sender, DOHGlobals.BIDTYPES.BIDHALF, halfPoints, 0)
                    end
                end
            elseif (command == "cleardualspec") then
                DOHGADB.DUALSPEC = {}
            elseif (command == "adddualspec") then
                DOHGADB.DUALSPEC[arg1] = true
            elseif (command == "removedualspec") then
                DOHGADB.DUALSPEC[arg1] = false
            end
        end
    end
end

function DanesOfHonor:HandleRoll(name, roll, min, max)
    if (not DOHGlobals.AUCTIONINPROGRESS) then
        return
    end

    if (min ~= 1) then
        DanesOfHonor:PrintRollHelp()
        return
    end

    local bidType = DOHGlobals.BIDTYPES.OFFSPEC
    local bid = 0;
    if (max == 100) then
        local currentPoints = DOHGADB.ROSTER[name].points
        if (currentPoints >= DOHGlobals.MINIMUMBID) then
            IncomingBidsWindow.AddBid(name, DOHGlobals.BIDTYPES.BIDMIN, DOHGlobals.MINIMUMBID, roll)
        else
            DanesOfHonor:PrintRollHelp()
        end
    elseif (max == 99) then
        IncomingBidsWindow.AddBid(name, DOHGlobals.BIDTYPES.MAINSPEC, 0, roll)
    elseif (max == 98) then
        IncomingBidsWindow.AddBid(name, DOHGlobals.BIDTYPES.DUALSPEC, 0, roll)
    elseif (max == 97) then
        IncomingBidsWindow.AddBid(name, DOHGlobals.BIDTYPES.OFFSPEC, 0, roll)
    else
        DanesOfHonor:PrintRollHelp()
    end
end

function DanesOfHonor:AjustPoints(memberName, numberOfPoints)
    DOHGADB.ROSTER[memberName].points = DOHGADB.ROSTER[memberName].points + numberOfPoints
    DOHGADB.ROSTER[memberName].state = DOHGlobals.UPDATE.WRITE
end

function DanesOfHonor:PrintRollHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000Danes|r |cAAFFFFFFof|r |cAAFF0000Honor|r guild addon!\n" ..
                                      table.concat(DOHGlobals.BIDHELPMESSAGES, "\n"));
end

function CreateBidWindow()
    local frameWidth = 400
    local buttonWidth = (frameWidth - 25) / 5
    local buttonHeight = 40

    f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        widget:Hide()
    end)
    f:SetTitle("Danes of Honor")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(frameWidth)
    f:SetHeight(160)

    -- Create Item Container --
    local itemContainer = AceGUI:Create("InlineGroup")
    itemContainer:SetLayout("Fill")
    itemContainer:SetWidth(frameWidth - buttonWidth)
    itemContainer:SetHeight(35)

    local countDown = AceGUI:Create("Label")
    countDown:SetText(DOHGlobals.BIDTIMER)
    countDown:SetWidth(buttonWidth * 0.5)
    countDown:SetFontObject(GameFontNormalLarge)

    -- Create Item Link
    local item = AceGUI:Create("InteractiveLabel")
    item:SetFontObject(GameFontNormalLarge)
    f.StartAuction = function(itemLink)
        DOHGlobals.AUCTIONINPROGRESS = true;
        item:SetText(itemLink)
        item:SetCallback("OnClick", function()
            SetItemRef(itemLink)
        end)
        BidWindow:Show()
    end
    itemContainer:AddChild(item)

    local halfBidButton = AceGUI:Create("Button")
    halfBidButton:SetWidth(buttonWidth)
    halfBidButton:SetHeight(buttonHeight)
    halfBidButton:SetCallback("OnClick", function()
        DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "auction bid half", "RAID")
        BidWindow:Hide()
    end)

    local minimumBidButton = AceGUI:Create("Button")
    minimumBidButton:SetWidth(buttonWidth)
    minimumBidButton:SetHeight(buttonHeight)
    minimumBidButton:SetCallback("OnClick", function()
        RandomRoll(1, 100)
        BidWindow:Hide()
    end)

    local mainSpecButton = AceGUI:Create("Button")
    mainSpecButton:SetWidth(buttonWidth)
    mainSpecButton:SetHeight(buttonHeight)
    mainSpecButton:SetText("Main Spec")
    mainSpecButton:SetCallback("OnClick", function()
        RandomRoll(1, 99)
        BidWindow:Hide()
    end)

    local dualSpecButton = AceGUI:Create("Button")
    dualSpecButton:SetWidth(buttonWidth)
    dualSpecButton:SetHeight(buttonHeight)
    dualSpecButton:SetText("Dual Spec")
    dualSpecButton:SetCallback("OnClick", function()
        RandomRoll(1, 98)
        BidWindow:Hide()
    end)

    local offSpecButton = AceGUI:Create("Button")
    offSpecButton:SetWidth(buttonWidth)
    offSpecButton:SetHeight(buttonHeight)
    offSpecButton:SetText("Off Spec")
    offSpecButton:SetCallback("OnClick", function()
        RandomRoll(1, 97)
        BidWindow:Hide()
    end)

    -- Add the button to the container
    f:AddChild(itemContainer)
    f:AddChild(countDown)
    f:AddChild(halfBidButton)
    f:AddChild(minimumBidButton)
    f:AddChild(mainSpecButton)
    f:AddChild(dualSpecButton)
    f:AddChild(offSpecButton)

    local bidTimerID = nil
    local bidTimeLeft = 0
    f:SetCallback("OnShow", function(widget)
        deadline = GetTime() + DOHGlobals.BIDTIMER
        local currentPoints = DOHGADB.ROSTER[UnitName("PLAYER")].points
        local halfPoints = math.ceil(currentPoints / 2);

        halfBidButton:SetText(string.format("HALF (%d)", halfPoints))
        halfBidButton:SetDisabled(halfPoints <= DOHGlobals.MINIMUMBID);

        minimumBidButton:SetText(string.format("FIXED (%d)", DOHGlobals.MINIMUMBID))
        minimumBidButton:SetDisabled(currentPoints < DOHGlobals.MINIMUMBID);

        dualSpecButton:SetDisabled(not DOHGADB.DUALSPEC[UnitName("PLAYER")])

        bidTimeLeft = DOHGlobals.BIDTIMER
        bidTimerID = DanesOfHonor:ScheduleRepeatingTimer(function()
            bidTimeLeft = bidTimeLeft - 1
            countDown:SetText(tostring(bidTimeLeft))
            if (bidTimeLeft <= 0) then
                DanesOfHonor:CancelTimer(bidTimerID)
                BidWindow:Hide()
                DOHGlobals.AUCTIONINPROGRESS = false;
            end
        end, 1)
    end)

    f:Hide();
    return f;
end
BidWindow = CreateBidWindow()

function CreateIncomingBidsWindow()
    f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        f:Hide()
    end)
    f:SetTitle("DoH Incoming Bids")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(350)
    f:SetHeight(275)

    local itemContainer = AceGUI:Create("InlineGroup")
    itemContainer:SetLayout("Fill")
    itemContainer:SetWidth(635)
    itemContainer:SetHeight(35)

    local item = AceGUI:Create("InteractiveLabel")
    item:SetFontObject(GameFontNormalLarge)

    itemContainer:AddChild(item)
    f:AddChild(itemContainer)

    local bidders = {}
    local bids = {}

    local headerLabel = AceGUI:Create("Label")
    headerLabel:SetText("Recieved bids:")
    f:AddChild(headerLabel)

    f:SetCallback("OnShow", function(e)
    end)

    local scrollContainer = AceGUI:Create("ScrollFrame");
    scrollContainer:SetLayout("Flow")
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetHeight(300);

    local scrollContent = AceGUI:Create("MultiLineEditBox");
    scrollContent:SetFullWidth(true);
    scrollContent:SetNumLines(10);
    scrollContent:DisableButton(true);
    scrollContent:SetLabel("");
    scrollContent:SetDisabled(true);

    scrollContainer:AddChild(scrollContent);
    f:AddChild(scrollContainer);

    f.StartAuction = function(itemLink)
        bidders = {}
        bids = {}
        item:SetText(itemLink)
        item:SetCallback("OnClick", function()
            SetItemRef(itemLink)
        end)
        scrollContent:SetText("");
        IncomingBidsWindow:Show()
    end

    f.AddBid = function(name, bidType, bid, roll)
        if (bidders[name]) then
            --      print(string.format(" - %s already did a bid", name))
            return
        end

        if (bidType == DOHGlobals.BIDTYPES.DUALSPEC) then
            if (not DOHGADB.DUALSPEC[name]) then
                SendChatMessage(
                    "You are not on the dual spec allow list. Bid ignored! To bid for offspec type /roll 97", "WHISPER",
                    "Common", name);
                return;
            end
        end

        bidders[name] = true;
        table.insert(bids, {
            name = name,
            bid = bid,
            roll = roll,
            bidType = bidType,
            plusOne = DOHGADB.ROSTER[dsName].plusOne or 0
        })

        table.sort(bids, function(a, b)
            if (a.bidType < b.bidType) then
                return true
            elseif (a.bidType > b.bidType) then
                return false;
            else

                if (a.plusOne < b.plusOne) then
                    return true;
                elseif (a.plusOne > b.plusOne) then
                    return false;
                else

                    if (a.bid > b.bid) then
                        return true
                    elseif (a.bid < b.bid) then
                        return false
                    else
                        return a.roll > b.roll
                    end

                end

            end
        end)

        local bidsString = "";
        for k, v in pairs(bids) do
            bidsString = bidsString ..
                             (string.format("%d - %s bid %d points (%d) [%d] as %s\n", k, v.name, v.bid, v.roll,
                    v.plusOne, DOHGlobals.BIDTYPES[v.bidType]))
        end

        scrollContent:SetText(bidsString);

    end

    f:Hide();

    return f;
end
IncomingBidsWindow = CreateIncomingBidsWindow()

function CreateMasterLooterWindow()
    local frameWidth = 300;
    f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        f:Hide()
    end)
    f:SetTitle("DoH Master looter")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(frameWidth)
    f:SetHeight(150)
    f:Hide()

    local awardRaidPointsButton = AceGUI:Create("Button");
    awardRaidPointsButton:SetFullWidth(true);
    awardRaidPointsButton:SetText(string.format("Award %d points to raid", DOHGlobals.MINIMUMBID))
    awardRaidPointsButton:SetCallback("OnClick", function()
        for name, data in pairs(DOHGADB.ROSTER) do
            data.points = data.points + DOHGlobals.MINIMUMBID;
            data.state = DOHGlobals.UPDATE.WRITE;
        end
        DanesOfHonor:ProcessRoster()
        SendChatMessage(string.format("%s awarded %d points to raid!", UnitName("PLAYER"), DOHGlobals.MINIMUMBID),
            "RAID");
    end)
    f:AddChild(awardRaidPointsButton);

    local toggleDualSpecButton = AceGUI:Create("Button");
    toggleDualSpecButton:SetFullWidth(true);
    toggleDualSpecButton:SetText("Toggle dual spec for target")
    toggleDualSpecButton:SetCallback("OnClick", function()
        local dsName = UnitName("TARGET")
        if (dsName) then
            if (DOHGADB.DUALSPEC[dsName]) then
                DOHGADB.DUALSPEC[dsName] = false;
                DEFAULT_CHAT_FRAME:AddMessage(string.format("%s was removed from the allow dual spec list!", dsName));
            else
                DOHGADB.DUALSPEC[dsName] = true;
                DEFAULT_CHAT_FRAME:AddMessage(string.format("%s was added to the allow dual spec list!", dsName));
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000DOHGA|r Select a target to toggle allow Dual spec!")
        end
    end)
    f:AddChild(toggleDualSpecButton);

    local subtractBidButton = AceGUI:Create("Button");
    subtractBidButton:SetFullWidth(true);
    subtractBidButton:SetText("Subtract points from target")
    subtractBidButton:SetCallback("OnClick", function()
        local dsName = UnitName("TARGET")
        if (dsName) then
            if (DOHGADB.ROSTER[dsName]) then
                local oldP = DOHGADB.ROSTER[dsName].points;
                local newP = oldP - 100;
                DOHGADB.ROSTER[dsName].points = newP;
                DOHGADB.ROSTER[dsName].state = DOHGlobals.UPDATE.WRITE;

                SendChatMessage(string.format("%s updated %s points from %d to %d!", UnitName("PLAYER"), dsName, oldP,
                    newP), "RAID");
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000DOHGA|r Select a target to subtrach points!")
        end
    end)
    f:AddChild(subtractBidButton);

    local buttonWidth = math.floor(frameWidth / 3);

    local addPlusOneButton = AceGUI:Create("Button");
    addPlusOneButton:SetWidth(buttonWidth);
    addPlusOneButton:SetText("Add 1")
    addPlusOneButton:SetCallback("OnClick", function()
        local dsName = UnitName("TARGET")
        if (dsName) then
            if (DOHGADB.ROSTER[dsName]) then
                DOHGADB.ROSTER[dsName].plusOne = DOHGADB.ROSTER[dsName].plusOne + 1
                SendChatMessage(string.format("%s added +1 to %s!", UnitName("PLAYER"), dsName), "RAID");
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000DOHGA|r Select a target to add +1 to!")
        end
    end)
    f:AddChild(addPlusOneButton);

    local subtractPlusOneButton = AceGUI:Create("Button");
    subtractPlusOneButton:SetWidth(buttonWidth);
    subtractPlusOneButton:SetText("Subtract 1")
    subtractPlusOneButton:SetCallback("OnClick", function()
        local dsName = UnitName("TARGET")
        if (dsName) then
            if (DOHGADB.ROSTER[dsName]) then
                DOHGADB.ROSTER[dsName].plusOne = DOHGADB.ROSTER[dsName].plusOne - 1
                SendChatMessage(string.format("%s subtracted 1 to %s!", UnitName("PLAYER"), dsName), "RAID");
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000DOHGA|r Select a target to subtract 1 from!")
        end
    end)
    f:AddChild(subtractPlusOneButton);
    return f;
end

MasterLooterWindow = CreateMasterLooterWindow()
-- /script DanesOfHonor:ResetPoints()
function DanesOfHonor:ResetPoints()
    local normalizedRealm = "-" .. GetNormalizedRealmName();
    local numTotalGuildMembers = GetNumGuildMembers();
    for i = 1, numTotalGuildMembers do
        GuildRosterSetOfficerNote(i, 0);
    end
    DOHGADB.ROSTER = {};
    DanesOfHonor:GROUP_ROSTER_UPDATE(nil);
end

-- /script DanesOfHonor:BackupPoints()
function DanesOfHonor:BackupPoints()
    local backup = {};
    local normalizedRealm = "-" .. GetNormalizedRealmName();
    local numTotalGuildMembers = GetNumGuildMembers();
    for i = 1, numTotalGuildMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote = GetGuildRosterInfo(i);
        if (name) then
            local n = name:gsub(normalizedRealm, "");
            backup[n] = tonumber(officernote);
        end
    end

    DOHGADB.Backup = backup;
    print("Backed up guild roster points.");
end

-- /script DanesOfHonor:RestorePoints()
function DanesOfHonor:RestorePoints()
    if (not DOHGADB.Backup) then
        return;
    end

    local normalizedRealm = "-" .. GetNormalizedRealmName();
    local numTotalGuildMembers = GetNumGuildMembers();
    for i = 1, numTotalGuildMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote = GetGuildRosterInfo(i);
        if (name) then
            local n = name:gsub(normalizedRealm, "");
            if (DOHGADB.Backup[n]) then
                GuildRosterSetOfficerNote(i, DOHGADB.Backup[n])
            end
        end
    end
    print("Restored guild roster points from backup.");
end

