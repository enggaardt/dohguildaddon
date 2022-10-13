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
    ADDPLUSONE = true,
    BIDTYPES = {
        HALF = 5,
        [5] = "HALF",
        FIXED = 4,
        [4] = "FIXED",
        MAINSPEC = 3,
        [3] = "MAINSPEC",
        DUALSPEC = 2,
        [2] = "DUALSPEC",
        OFFSPEC = 1,
        [1] = "OFFSPEC"
    },
    UPDATE = {
        NONE = 0,
        READ = 1,
        WRITE = 2
    },
    BIDHELPMESSAGES = {"|cAAFF0000*|r To bid half your points: /doh bid half",
                       "|cAAFF0000*|r To bid the fixed price (100 points): /roll 100",
                       "|cAAFF0000*|r To roll for mainspec: /roll 99", "|cAAFF0000*|r To roll for dualspec: /roll 98",
                       "|cAAFF0000*|r To roll for offspec: /roll 97"},
    CLASSRGBACOLORS = {
        unknown = {
            r = 0.5,
            g = 0.5,
            b = 0.5,
            a = 1
        },
        druid = {
            r = 1,
            g = .48627,
            b = .0392,
            a = 1
        },
        hunter = {
            r = .6666,
            g = .827450,
            b = .44705,
            a = 1
        },
        mage = {
            r = .4078,
            g = .8,
            b = .93725,
            a = 1
        },
        paladin = {
            r = .95686,
            g = .5490,
            b = .72941,
            a = 1
        },
        priest = {
            r = 1,
            g = 1,
            b = 1,
            a = 1
        },
        rogue = {
            r = 1,
            g = .95686,
            b = .40784,
            a = 1
        },
        shaman = {
            r = 0,
            g = .44,
            b = .87,
            a = 1
        },
        warlock = {
            r = .57647,
            g = .5098,
            b = .788235,
            a = 1
        },
        warrior = {
            r = .77647,
            g = .607843,
            b = .42745,
            a = 1
        },
        ["death knight"] = {
            r = .77,
            g = .12,
            b = .23
        }
    }
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
    --          DEFAULT_CHAT_FRAME:AddMessage("Debug roster!");
    for name, data in pairs(DOHGADB.ROSTER) do
        local s = name;
        for k, v in pairs(DOHGADB.ROSTER[name]) do
            s = s .. string.format(" (%s => %s)", k, tostring(v))
        end
        --          DEFAULT_CHAT_FRAME:AddMessage(s);
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
                SendChatMessage(string.format("An auction started for %s!", itemLink), "RAID_WARNING")
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
    elseif (command == "reset") then
        if (DOHGADB.ROSTER[UnitName("PLAYER")].isML) then
            DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "reset 1", "RAID")
        end
    end
end

local mlTimeLeft = 0;
local mlTimerID = nil;

function DanesOfHonor:OnCommReceived(prefix, text, distribution, sender, e)
    if (prefix == DOHGlobals.COMMPREFIX) then
        local action, command, arg1 = DanesOfHonor:GetArgs(text, 3)
        if (action == "auction") then
            if (command == "start") then
                if (arg1) then
                    BidWindow.StartAuction(arg1)
                    if (DOHGADB.ROSTER[UnitName("PLAYER")].isML) then
                        mlTimeLeft = DOHGlobals.BIDTIMER
                        mlTimerID = DanesOfHonor:ScheduleRepeatingTimer(function()
                            mlTimeLeft = mlTimeLeft - 1
                            if (mlTimeLeft <= 0) then
                                DanesOfHonor:CancelTimer(mlTimerID)
                                SendChatMessage(string.format("Auction for %s ended!", arg1, mlTimeLeft), "RAID");
                            elseif (mlTimeLeft <= 5) then
                                SendChatMessage(string.format("Auction for %s ends in %d seconds!", arg1, mlTimeLeft),
                                    "RAID");
                            end
                        end, 1)
                        IncomingBidsWindow.StartAuction(arg1)
                    end
                end
            elseif (command == "bid") then
                if (arg1 == "half") then
                    local currentPoints = DOHGADB.ROSTER[sender].points
                    local halfPoints = math.ceil(currentPoints / 2)
                    if (halfPoints > DOHGlobals.MINIMUMBID) then
                        IncomingBidsWindow.AddBid(sender, DOHGlobals.BIDTYPES.HALF, halfPoints, 0)
                    end
                end
            end
        elseif (action == "dualspec") then

            if (command == "clear") then
                DOHGADB.DUALSPEC = {}
                DEFAULT_CHAT_FRAME:AddMessage(string.format("Dual spec list cleared!", arg1));
            elseif (command == "add") then
                DOHGADB.DUALSPEC[arg1] = true
                DEFAULT_CHAT_FRAME:AddMessage(string.format("%s was added to the allow dual spec list!", arg1));
            else
                DOHGADB.DUALSPEC[arg1] = false
                DEFAULT_CHAT_FRAME:AddMessage(string.format("%s was removed from the allow dual spec list!", arg1));
            end
        elseif (action == "reset") then
            DanesOfHonor:LoadPointsFromGuildRoster(command);
        elseif (action == "processRoster") then
            for name, data in pairs(DOHGADB.ROSTER) do
                DOHGADB.ROSTER[name].state = DOHGlobals.UPDATE.READ;
            end
            DanesOfHonor:ProcessRoster();
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
            IncomingBidsWindow.AddBid(name, DOHGlobals.BIDTYPES.FIXED, DOHGlobals.MINIMUMBID, roll)
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

    local f = AceGUI:Create("Window")
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
        local playerName = UnitName("PLAYER");
        local currentPoints = DOHGADB.ROSTER[playerName].points or 0;
        local halfPoints = math.ceil(currentPoints / 2);

        halfBidButton:SetText(string.format("HALF (%d)", halfPoints))
        halfBidButton:SetDisabled(halfPoints <= DOHGlobals.MINIMUMBID);

        minimumBidButton:SetText(string.format("FIXED (%d)", DOHGlobals.MINIMUMBID))
        minimumBidButton:SetDisabled(currentPoints < DOHGlobals.MINIMUMBID);

        dualSpecButton:SetDisabled(not DOHGADB.DUALSPEC[playerName])

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

function CreateAwardLootWindow()
    local f = AceGUI:Create("Window");
    f:SetCallback("OnClose", function(widget)
        f:Hide()
    end)
    f:SetTitle("Award Loot");
    f:SetHeight(100)
    f:SetWidth(400);
    f:EnableResize(false)
    f:SetLayout("Flow")

    local infoGroup = AceGUI:Create("SimpleGroup");
    f:AddChild(infoGroup);
    infoGroup:SetLayout("Flow");
    infoGroup:SetFullWidth(true);

    local label = AceGUI:Create("Label");
    infoGroup:AddChild(label);
    label:SetFullWidth(true);

    local buttonGroup = AceGUI:Create("SimpleGroup");
    f:AddChild(buttonGroup);
    buttonGroup:SetLayout("Flow");
    buttonGroup:SetFullWidth(true);

    local yesButton = AceGUI:Create("Button");
    buttonGroup:AddChild(yesButton);
    yesButton:SetRelativeWidth(0.5);
    yesButton:SetText("YES")
    yesButton:SetCallback("OnClick", function(widget)
        local bid = f:GetUserData("bid");
        if (DOHGADB.ROSTER[bid.name]) then
            DOHGADB.ROSTER[bid.name].points = DOHGADB.ROSTER[bid.name].points - bid.bid;
            DOHGADB.ROSTER[bid.name].state = DOHGlobals.UPDATE.WRITE;
            if (DOHGlobals.ADDPLUSONE and bid.bidType == DOHGlobals.BIDTYPES.MAINSPEC) then
                DOHGADB.ROSTER[bid.name].plusOne = DOHGADB.ROSTER[bid.name].plusOne + 1;
            end
            DanesOfHonor:ProcessRoster();
            DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "processRoster read " .. bid.name, "RAID")
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cAAFF0000DOHGA|r Could not find %s in roster!", bid.name));
        end

        f:SetUserData("bid", nil);
        f:Hide()
    end)

    local cancelButton = AceGUI:Create("Button");
    buttonGroup:AddChild(cancelButton);
    cancelButton:SetRelativeWidth(0.5);
    cancelButton:SetText("NO")
    cancelButton:SetCallback("OnClick", function(widget)
        f:SetUserData("bid", nil);
        f:Hide()
    end)

    f.AwardLoot = function(bid)
        f:SetUserData("bid", bid);

        local classColor = "11EE11";
        local text = string.format("Award %s to |cAA%s%s|r as |cAAFF0000%s|r?", bid.item, classColor, bid.name,
            DOHGlobals.BIDTYPES[bid.bidType])
        if (bid.bidType == DOHGlobals.BIDTYPES.HALF or bid.bidType == DOHGlobals.BIDTYPES.FIXED) then
            text = text ..
                       string.format("\nThis will subtract |cAAFF0000%d|r points from |cAA%s%s|r!", bid.bid, classColor,
                    bid.name);
        elseif (DOHGlobals.ADDPLUSONE and bid.bidType == DOHGlobals.BIDTYPES.MAINSPEC) then
            text = text .. string.format("\nThis will add |cAAFF0000+1|r to |cAA%s%s|r!", classColor, bid.name);
        end

        label:SetText(text);
        f:Show();
    end

    f:Hide();
    return f;
end
AwardLootWindow = CreateAwardLootWindow();

function CreateIncomingBidsWindow()
    local itemLinkOnAuction = nil;
    local f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        f:Hide()
    end)
    f:SetTitle("DoH Incoming Bids")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(350)
    f:SetHeight(290)

    local itemContainer = AceGUI:Create("InlineGroup")
    f:AddChild(itemContainer)
    itemContainer:SetLayout("Fill")
    itemContainer:SetFullWidth(true)
    itemContainer:SetHeight(25)

    local item = AceGUI:Create("InteractiveLabel")
    itemContainer:AddChild(item)
    item:SetFullWidth(true)

    local bidders = {}
    local bids = {}

    local scrollTable = LibStub("ScrollingTable");
    local columns = { --[[ Player name ]] {
        name = "Player",
        width = 120,
        align = "LEFT",
        color = DOHGlobals.CLASSRGBACOLORS.unknown,
        colorargs = nil
    }, {
        name = "Bid",
        width = 35,
        align = "RIGHT",
        color = DOHGlobals.CLASSRGBACOLORS.unknown,
        colorargs = nil
    }, {
        name = "Roll",
        width = 35,
        align = "RIGHT",
        color = DOHGlobals.CLASSRGBACOLORS.unknown,
        colorargs = nil
    }, {
        name = "+1",
        width = 15,
        align = "RIGHT",
        color = DOHGlobals.CLASSRGBACOLORS.unknown,
        colorargs = nil
    }, {
        name = "Type",
        width = 75,
        align = "LEFT",
        color = DOHGlobals.CLASSRGBACOLORS.unknown,
        colorargs = nil
    }, {
        name = "",
        width = 1,
        align = "LEFT",
        color = DOHGlobals.CLASSRGBACOLORS.unknown,
        colorargs = nil,
        sort = 2
    }};

    local Table = scrollTable:CreateST(columns, 10, 15, nil, f.frame);
    Table:SetWidth(340)
    Table:EnableSelection(false);
    Table.frame:SetPoint("TOP", itemContainer.frame, "BOTTOM", 0, -20);
    Table:RegisterEvents({
        ["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)

            printTable("data[realrow]", data[realrow]);
            printTable("data[realrow].cols[1]", data[realrow].cols[1]);
            local dataRow = data[realrow].cols;
            local bid = {
                name = dataRow[1].value,
                bid = dataRow[2].value,
                roll = dataRow[3].value,
                plusOne = dataRow[4].value,
                bidType = DOHGlobals.BIDTYPES[dataRow[5].value],
                item = itemLinkOnAuction
            };
            printTable("bid", bid);
            AwardLootWindow.AwardLoot(bid);
        end
    });

    Table:SetData(bids, true);

    f.StartAuction = function(itemLink)
        itemLinkOnAuction = itemLink;
        bidders = {}
        bids = {}

        item:SetText(itemLink)
        item:SetCallback("OnClick", function()
            SetItemRef(itemLink)
        end)

        Table:SetData(bids, true);
        Table:Refresh();
        IncomingBidsWindow:Show()
    end

    f.AddBid = function(name, bidType, bid, roll)
        if (bidders[name]) then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(" - %s already placed a bid", name));
            return
        end

        bidders[name] = true;
        local plusOne = 0;
        local plusOneSorter = 999;
        if (bidType == DOHGlobals.BIDTYPES.MAINSPEC) then
            plusOne = DOHGADB.ROSTER[name].plusOne or 0;
            plusOneSorter = plusOneSorter - plusOne;
        end

        local sortOrder = string.format("%02d %06d %03d %03d", bidType, bid, plusOneSorter, roll);
        local class = string.lower(DOHGADB.ROSTER[name].class or "unknown");
        local color = DOHGlobals.CLASSRGBACOLORS[class];

        local row = {
            cols = {{
                value = name,
                color = color
            }, {
                value = bid,
                color = color
            }, {
                value = roll,
                color = color
            }, {
                value = plusOne,
                color = color
            }, {
                value = DOHGlobals.BIDTYPES[bidType],
                color = color
            }, {
                value = sortOrder
            }}
        };

        table.insert(bids, row);
        Table:SetData(bids);
        Table:SortData();
    end

    f:Hide();
    return f;
end
IncomingBidsWindow = CreateIncomingBidsWindow()

function CreateMasterLooterWindow()
    local f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        f:Hide()
    end)
    f:SetTitle("DoH Master looter")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(300)
    f:SetHeight(150)
    --  f:Hide()

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

    local allowDualSpecButton = AceGUI:Create("Button");
    allowDualSpecButton:SetRelativeWidth(0.333);
    allowDualSpecButton:SetText("Allow DS")
    allowDualSpecButton:SetCallback("OnClick", function()
        local dsName = UnitName("TARGET")
        if (dsName) then
            DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "dualspec add " .. dsName, "RAID")
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000DOHGA|r Select a target to allow Dual spec for!")
        end
    end)
    f:AddChild(allowDualSpecButton);

    local disAllowDualSpecButton = AceGUI:Create("Button");
    disAllowDualSpecButton:SetRelativeWidth(0.333);
    disAllowDualSpecButton:SetText("Remove DS")
    disAllowDualSpecButton:SetCallback("OnClick", function()
        local dsName = UnitName("TARGET")
        if (dsName) then
            DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "dualspec remove " .. dsName, "RAID")
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000DOHGA|r Select a target to disallow Dual spec for!")
        end
    end)
    f:AddChild(disAllowDualSpecButton);

    local clearDualSpecButton = AceGUI:Create("Button");
    clearDualSpecButton:SetRelativeWidth(0.333);
    clearDualSpecButton:SetText("Clear DS")
    clearDualSpecButton:SetCallback("OnClick", function()
        DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "dualspec clear", "RAID")
    end)
    f:AddChild(clearDualSpecButton);

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

    local addPlusOneButton = AceGUI:Create("Button");
    addPlusOneButton:SetRelativeWidth(0.333);
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
    subtractPlusOneButton:SetRelativeWidth(0.333);
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

    local addTestBidbutton = AceGUI:Create("Button");
    addTestBidbutton:SetRelativeWidth(0.333);
    addTestBidbutton:SetText("Test Bid")
    addTestBidbutton:SetCallback("OnClick", function()
        DanesOfHonor:AddTestBid();
    end)
    f:AddChild(addTestBidbutton);
    f:Hide();
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
    DanesOfHonor:LoadPointsFromGuildRoster();
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
    DEFAULT_CHAT_FRAME:AddMessage("Backed up guild roster points.")
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
    DEFAULT_CHAT_FRAME:AddMessage("Restored guild roster points from backup.");
end

function DanesOfHonor:AddTestBid()
    local name = "Name" .. math.floor(GetTime());
    local bidType = math.random(DOHGlobals.BIDTYPES.OFFSPEC, DOHGlobals.BIDTYPES.HALF);
    local bid = 0;
    local roll = 0;
    if (bidType == DOHGlobals.BIDTYPES.HALF) then
        bid = math.random(DOHGlobals.MINIMUMBID * 2 + 1, 9000);
    elseif (bidType == DOHGlobals.BIDTYPES.FIXED) then
        bid = DOHGlobals.MINIMUMBID;
        roll = math.random(1, 100);
    elseif (bidType == DOHGlobals.BIDTYPES.MAINSPEC) then
        bid = 0;
        roll = math.random(1, 99);
    elseif (bidType == DOHGlobals.BIDTYPES.DUALSPEC) then
        bid = 0;
        roll = math.random(1, 98);
    elseif (bidType == DOHGlobals.BIDTYPES.OFFSPEC) then
        bid = 0;
        roll = math.random(1, 97);
    end

    IncomingBidsWindow.AddBid(name, bidType, bid, roll);

    local testBid = {
        name = name,
        bid = bid,
        roll = roll,
        plusOne = 0,
        bidType = bidType,
        item = "itemLinkOnAuction"
    };

    --  AwardLootWindow.AwardLoot(testBid);

end

-- /script DanesOfHonor:LoadPointsFromGuildRoster()
function DanesOfHonor:LoadPointsFromGuildRoster(resetRoster)
    if (resetRoster) then
        DOHGADB.ROSTER = {};
        DEFAULT_CHAT_FRAME:AddMessage("Raid roster cache cleared!");
    end
    for i = 1, MAX_RAID_MEMBERS do
        name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
        if (name) then
            if (DOHGADB.ROSTER[name]) then
                DOHGADB.ROSTER[name].state = DOHGlobals.UPDATE.READ;
                DOHGADB.ROSTER[name].class = class;
                DOHGADB.ROSTER[name].plusOne = DOHGADB.ROSTER[name].plusOne or 0;
                DOHGADB.ROSTER[name].points = DOHGADB.ROSTER[name].points or 0;
            else
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
    DanesOfHonor:GROUP_ROSTER_UPDATE(nil);
end
