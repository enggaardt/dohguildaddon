DanesOfHonor = LibStub("AceAddon-3.0"):NewAddon("DanesOfHonor", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local version = 1.9
local defaults = {}
local COMMPREFIX = "dohga"

function DanesOfHonor:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DOHGADB", defaults)

    if (DOHGADB == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("DOHGA: Init saved variables")
        DOHGADB = {}
    end

    DanesOfHonor:RegisterComm(COMMPREFIX)
    DanesOfHonor:RegisterChatCommand('doh', 'HandleChatCommand')

    DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000Danes|r |cAAFFFFFFof|r |cAAFF0000Honor|r guild addon loaded!")
end

function DanesOfHonor:HandleChatCommand(input)
    local command = string.lower(FixNil(DanesOfHonor:GetArgs(input)))
    if (command == "auction") then
        local _, itemLink = DanesOfHonor:GetArgs(input, 2);
        if (itemLink) then
            DanesOfHonor:StartBid(itemLink)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Command |cAAFF0000/doh auction|r is missing item link parameter!")
        end
    end
end

function DanesOfHonor:StartBid(itemLink)
    print("StartBid:ItemLink = " .. itemLink)

    DanesOfHonor:SendCommMessage(COMMPREFIX, "auction start " .. itemLink, "RAID")

end

function DanesOfHonor:OnCommReceived(prefix, text, distribution, sender, e)
    print("TEXT: " .. text)
    if (prefix == COMMPREFIX) then
        local action, command, itemLink = DanesOfHonor:GetArgs(text, 3)
        if (action == "auction") then
            if (command == "start") then
                if (itemLink) then
                    DohBidFrame:Show()
                    print(sender .. " started an auction for " .. itemLink)
                end
            end
        end
    end
end
