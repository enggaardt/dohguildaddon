-- To get detailed error messages ingame 
-- /console scriptErrors 1
DanesOfHonor = LibStub("AceAddon-3.0"):NewAddon("DanesOfHonor", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local AceGUI = LibStub("AceGUI-3.0")

DOHGlobals = {
    COMMPREFIX = "DOHGA",
    AUCTIONINPROGRESS = false,
    MINIMUMBID = 100,
    BIDTYPES = {
        BIDHALF = 1,
        BIDMIN = 2,
        MAINSPEC = 3,
        DUALSPEC = 4,
        OFFSPEC = 5
    },
    UPDATE = {
        NONE = 0,
        READ = 1,
        WRITE = 2
    }
}

function DanesOfHonor:OnInitialize()
    if not (DOHGADB) then
        DOHGADB = {}
    end
    if (not DOHGADB.ROSTER) then
        DOHGADB.ROSTER = {}
    end

    DanesOfHonor:RegisterComm(DOHGlobals.COMMPREFIX)
    DanesOfHonor:RegisterChatCommand('doh', 'HandleChatCommand')
    DanesOfHonor:RegisterEvent("CHAT_MSG_SYSTEM")
    DanesOfHonor:RegisterEvent("RAID_ROSTER_UPDATE")
    DanesOfHonor:RegisterEvent("GROUP_ROSTER_UPDATE")
    DanesOfHonor:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

    DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000Danes|r |cAAFFFFFFof|r |cAAFF0000Honor|r guild addon loaded!")
end

function DanesOfHonor:PARTY_LOOT_METHOD_CHANGED(event)
    DanesOfHonor:GROUP_ROSTER_UPDATE(event)
    if (DOHGADB.ROSTER[UnitName("PLAYER")].isML) then
        MasterLooterWindow:Show();
    else
        MasterLooterWindow:Hide();
    end
end

function DanesOfHonor:RAID_ROSTER_UPDATE(event)
    DanesOfHonor:GROUP_ROSTER_UPDATE(event)
end

function DanesOfHonor:GROUP_ROSTER_UPDATE(event)
    print(string.format("UPDATE ROSTER: %s", event))
    for i = 1, MAX_RAID_MEMBERS do
        name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
        if (name) then
            if (not DOHGADB.ROSTER[name]) then
                DOHGADB.ROSTER[name] = {
                    points = 0,
                    state = DOHGlobals.UPDATE.READ,
                    class = class
                }
            end
            DOHGADB.ROSTER[name].isML = isML
        end
    end
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
    print("ROSTER:")
    for name, data in pairs(DOHGADB.ROSTER) do
        local s = name;
        for k, v in pairs(DOHGADB.ROSTER[name]) do
            s = s .. string.format(" (%s => %s)", k, tostring(v))
        end
        print(s)
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
        local _, itemLink = DanesOfHonor:GetArgs(input, 2);
        if (itemLink) then
            DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "auction start " .. itemLink, "RAID")
            print("handle chat command " .. itemLink)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000/doh auction|r is missing item link parameter!")
        end
    end
end

function DanesOfHonor:OnCommReceived(prefix, text, distribution, sender, e)
    if (prefix == DOHGlobals.COMMPREFIX) then
        local action, command, arg1 = DanesOfHonor:GetArgs(text, 3)
        if (action == "auction") then
            if (command == "start") then
                if (arg1) then
                    DOHGlobals.AUCTIONINPROGRESS = true;
                    IncomingBidsWindow.SetItemLink(arg1)
                    IncomingBidsWindow:Show()

                    --     biddingFrameShow(arg1)
                    print(sender .. " started a bid for " .. arg1)
                end
            elseif (command == "bid") then
                if (arg1 == "half") then
                    local points = DanesOfHonor:GetPlayerPoints(sender);
                    local halfPoints = math.ceil(points / 2)
                    bidsFrameAddBid(sender, DOHGlobals.BIDTYPES.BIDHALF, halfPoints, 0)
                    print(sender .. " bid half his/her points (" .. halfPoints .. ")")
                end
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
        bidType = DOHGlobals.BIDTYPES.BIDMIN
        bid = DOHGlobals.MINIMUMBID
        print(name .. " bid the minimum points (" .. bid .. ")")
    elseif (max == 99) then
        bidType = DOHGlobals.BIDTYPES.MAINSPEC
        print(name .. " rolled " .. roll .. " as MAINSPEC")
    elseif (max == 98) then
        bidType = DOHGlobals.BIDTYPES.DUALSPEC
        print(name .. " rolled " .. roll .. " as DUALSPEC")
    elseif (max == 97) then
        bidType = DOHGlobals.BIDTYPES.OFFSPEC
        print(name .. " rolled " .. roll .. " as OFFSPEC")
    else
        DanesOfHonor:PrintRollHelp()
        return
    end

    bidsFrameAddBid(name, bidType, bid, roll)
end

function DanesOfHonor:AjustPoints(memberName, numberOfPoints)
    DOHGADB.ROSTER[memberName].points = DOHGADB.ROSTER[memberName].points + numberOfPoints
    DOHGADB.ROSTER[memberName].state = DOHGlobals.UPDATE.WRITE
end

function DanesOfHonor:PrintRollHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000Danes|r |cAAFFFFFFof|r |cAAFF0000Honor|r guild addon!\n" ..
                                      "|cAAFF0000*|r To bid half your points: /doh bid half\n" ..
                                      "|cAAFF0000*|r To bid the fixed price (100 points): /roll 100\n" ..
                                      "|cAAFF0000*|r To roll for mainspec: /roll 99\n" ..
                                      "|cAAFF0000*|r To roll for dualspec: /roll 98\n" ..
                                      "|cAAFF0000*|r To roll for offspec: /roll 97")
end

function CreateIncomingBidsWindow()
    f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        f:Hide()
    end)
    f:SetTitle("DoH Incoming Bids")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(300)
    f:SetHeight(150)

    local itemContainer = AceGUI:Create("InlineGroup")
    itemContainer:SetLayout("Fill")
    itemContainer:SetWidth(635)
    itemContainer:SetHeight(35)

    local item = AceGUI:Create("InteractiveLabel")
    item:SetFontObject(GameFontNormalLarge)

    itemContainer:AddChild(item)
    f:AddChild(itemContainer)

    f.SetItemLink = function(itemLink)
        item:SetText(itemLink)
        item:SetCallback("OnClick", function()
            SetItemRef(itemLink)
        end)
    end

    local headerLabel = AceGUI:Create("Label")
    headerLabel:SetText("Recieved bids:")
    headerLabel:SetLayout("Fill")
    f:AddChild(headerLabel)

    f:SetCallback("OnShow", function(e)
        print("show incoming bids windows")
    end)

    f:Hide();

    return f;
end
IncomingBidsWindow = CreateIncomingBidsWindow()

function CreateMasterLooterWindow()
    f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        f:Hide()
    end)
    f:SetTitle("DoH Master looter")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(300)
    f:SetHeight(150)
    f:Hide()

    return f;
end
MasterLooterWindow = CreateMasterLooterWindow()
