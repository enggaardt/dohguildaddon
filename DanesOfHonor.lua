DanesOfHonor = LibStub("AceAddon-3.0"):NewAddon("DanesOfHonor", "AceConsole-3.0", "AceEvent-3.0")
local version = 1.9
local defaults = {    }


function DanesOfHonor:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DOHGADB", defaults)
    
    if (DOHGADB == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("DOHGA: Init saved variables")
        DOHGADB = {}
    end
    
    DanesOfHonor:RegisterChatCommand('doh', 'HandleChatCommand')

    DEFAULT_CHAT_FRAME:AddMessage("|cAAFF0000Danes|r |cAAFFFFFFof|r |cAAFF0000Honor|r guild addon loaded!")
end

function DanesOfHonor:HandleChatCommand(input)    
    DEFAULT_CHAT_FRAME:AddMessage("DOHGA: " .. input )
end
