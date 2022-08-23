DanesOfHonor = LibStub("AceAddon-3.0"):NewAddon("DanesOfHonor",
                                                "AceConsole-3.0", "AceEvent-3.0")
local version = 1.7
local defaults = {}

function DanesOfHonor:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DOHGADB", defaults)

    if (DOHGADB == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("DOHGA: Init saved variables")
        DOHGADB = {}
    end

    local realm = GetRealmName()
    if (DOHGADB[realm] == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("DOHGA: Init realm: " .. realm)
        DOHGADB[realm] = {}
    end

    local player = UnitName("player")
    if (DOHGADB[realm][player] == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("DOHGA: Init player: " .. player)
        DOHGADB[realm][player] = {}
    end

    local faction = UnitFactionGroup("player")
    DOHGADB[realm][player]["faction"] = faction

    local class = UnitClass("player")
    DOHGADB[realm][player]["class"] = class
    DOHGADB[realm][player]["level"] = UnitLevel("player")

    for p, d in pairs(DOHGADB[realm]) do
        DOHGADB[realm][p]["tradeskills"] = { }
    end

    DanesOfHonor:RegisterChatCommand('doh', 'HandleChatCommand')
    DanesOfHonor:RegisterEvent("TRADE_SKILL_SHOW")
    DanesOfHonor:RegisterEvent("TRADE_SKILL_UPDATE")
    DanesOfHonor:RegisterEvent("CRAFT_UPDATE")
    DanesOfHonor:RegisterEvent("PLAYER_GUILD_UPDATE")
    DanesOfHonor:RegisterEvent("GUILD_ROSTER_UPDATE")

end

function DanesOfHonor:PLAYER_GUILD_UPDATE()
    local realm, player = DanesOfHonor:GetPlayerInfo()
    local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
    DOHGADB[realm][player]["guildName"] = guildName
    DOHGADB[realm][player]["guildRankName"] = guildRankName
    DOHGADB[realm][player]["guildRankIndex"] = guildRankIndex
end

function DanesOfHonor:GUILD_ROSTER_UPDATE()
    local realm, player = DanesOfHonor:GetPlayerInfo()
    local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
    DOHGADB[realm][player]["guildName"] = guildName
    DOHGADB[realm][player]["guildRankName"] = guildRankName
    DOHGADB[realm][player]["guildRankIndex"] = guildRankIndex
end

function DanesOfHonor:HandleChatCommand(input) DanesOfHonor:CreateExportString() end

function DanesOfHonor:CreateExportString()
    local exportString = '{\"version\":' .. version .. ',\"data\":{'

    for realm, players in pairs(DOHGADB) do
        if (realm ~= "profileKeys") then
            exportString = exportString .. '\"' .. realm .. '\": {'
            for player, data in pairs(players) do
                exportString = exportString .. '\"' .. player .. '\": {'
                exportString = exportString .. '\"faction\": \"' ..
                                   data["faction"] .. '\",'
                exportString = exportString .. '\"class\": \"' ..
                                   FixNil(data["class"]) .. '\",'

                if (data["level"]) then
                    exportString = exportString .. '\"level\": ' ..
                                       data["level"] .. ','
                end

                if (data["guildName"]) then
                    exportString = exportString .. '\"guildName\": \"' ..
                                       data["guildName"] .. '\",'
                    exportString = exportString .. '\"guildRankName\": \"' ..
                                       data["guildRankName"] .. '\",'
                    exportString = exportString .. '\"guildRankIndex\": ' ..
                                       data["guildRankIndex"] .. ','
                end
                exportString = exportString ..
                                   DanesOfHonor:TradeskillsToJson(
                                       data["tradeskills"])
                -- other data types here
                exportString = exportString .. '},'
            end
            exportString = exportString .. '},'
        end
    end
    exportString = exportString .. '}}'

    exportString = exportString:gsub(",}", "}")
    exportString = exportString:gsub(",]", "]")
    DanesOfHonor:DisplayExportString(exportString)

end

function DanesOfHonor:TradeskillsToJson(tradeSkills, exportString)
    local exportString = '\"tradeskills\": {'
    if (tradeSkills) then
        for tradeskill, data in pairs(tradeSkills) do
            exportString = exportString .. '\"' .. tradeskill .. '\": {'
            exportString = exportString .. "\"max\":" .. data["max"] ..
                               ',\"current\":' .. data["current"] ..
                               ',\"recipies\":['

            for index, item in pairs(data["recipies"]) do
                exportString = exportString .. '{\"icon\":' .. item["icon"] ..
                                   ',\"link\":\"' .. item["link"] .. '\"},'
            end

            exportString = exportString .. '],'
            exportString = exportString .. '},'
        end
    end
    exportString = exportString .. '},'
    return exportString
end

function DanesOfHonor:DisplayExportString(exportString)

    local encoded = DanesOfHonor:encode(exportString)

    DohFrame:Show()
    DohFrameScroll:Show()
    DohFrameScrollText:Show()
    DohFrameScrollText:SetText(encoded)
    DohFrameScrollText:HighlightText()

    DohFrameButton:SetScript("OnClick", function(self) DohFrame:Hide() end)
end

function DanesOfHonor:TRADE_SKILL_SHOW()
    local realm, player = DanesOfHonor:GetPlayerInfo()

    if (DOHGADB[realm][player]["tradeskills"] == nil) then
        DEFAULT_CHAT_FRAME:AddMessage("DOHGA: Init tradeskills...")
        DOHGADB[realm][player]["tradeskills"] = {}
    end
end

function DanesOfHonor:CRAFT_UPDATE()
    local craftName = GetCraftName()
    if (craftName == 'Enchanting') then
        local realm, player = DanesOfHonor:GetPlayerInfo()
        local totalRecipies = GetNumCrafts()

        if (totalRecipies == 0) then return end

        local name, rank, maxRank = GetCraftDisplaySkillLine()
        local data = {}
        data["current"] = rank
        data["max"] = maxRank
        data["recipies"] = {}

        for i = 1, totalRecipies do
            local craftName, craftSubSpellName, craftType, numAvailable,
                  isExpanded, trainingPointCost, requiredLevel = GetCraftInfo(i);
            local creates = GetCraftItemLink(i);
            if (name and type ~= "header") then
                local itemLink = GetCraftItemLink(i);
                local itemIcon = 0
                table.insert(data["recipies"],
                             {link = itemLink, icon = itemIcon})
            end
        end

        DOHGADB[realm][player]["tradeskills"][craftName] = data
    end
end

function DanesOfHonor:TRADE_SKILL_UPDATE()
    local realm, player = DanesOfHonor:GetPlayerInfo()

    local totalRecipies = GetNumTradeSkills()
    local index = GetFirstTradeSkill()

    if (index == 0) then return end

    --	DEFAULT_CHAT_FRAME:AddMessage("DOHGA: number of skills "..totalRecipies)
    --	DEFAULT_CHAT_FRAME:AddMessage("DOHGA: first index "..index)

    local tradeskillName, currentLevel, maxLevel = GetTradeSkillLine()
    local data = {}
    data["current"] = currentLevel
    data["max"] = maxLevel
    data["recipies"] = {}

    local name, type
    for i = 1, GetNumTradeSkills() do
        name, type, _, _, _, _ = GetTradeSkillInfo(i)
        if (name and type ~= "header") then
            local itemLink = GetTradeSkillItemLink(i)
            local itemIcon = GetTradeSkillIcon(i)
            table.insert(data["recipies"], {link = itemLink, icon = itemIcon})
            --		DEFAULT_CHAT_FRAME:AddMessage("Found: "..name);
        end
    end

    DOHGADB[realm][player]["tradeskills"][tradeskillName] = data
end

function DanesOfHonor:GetPlayerInfo()
    local realm = GetRealmName()
    local player = UnitName("player")
    return realm, player
end

local extract = _G.bit32 and _G.bit32.extract
if not extract then
    if _G.bit then
        local shl, shr, band = _G.bit.lshift, _G.bit.rshift, _G.bit.band
        extract = function(v, from, width)
            return band(shr(v, from), shl(1, width) - 1)
        end
    elseif _G._VERSION >= "Lua 5.3" then
        extract = load [[return function( v, from, width )
			return ( v >> from ) & ((1 << width) - 1)
		end]]()
    else
        extract = function(v, from, width)
            local w = 0
            local flag = 2 ^ from
            for i = 0, width - 1 do
                local flag2 = flag + flag
                if v % flag2 >= flag then w = w + 2 ^ i end
                flag = flag2
            end
            return w
        end
    end
end

function FixNil(x)
    if (x == nil) then
        return ''
    else
        return x;
    end
end

local char, concat = string.char, table.concat

function DanesOfHonor:makeencoder(s62, s63, spad)
    local encoder = {}
    for b64code, char in pairs {
        [0] = 'A',
        'B',
        'C',
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'w',
        'x',
        'y',
        'z',
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        s62 or '+',
        s63 or '/',
        spad or '='
    } do encoder[b64code] = char:byte() end
    return encoder
end

function DanesOfHonor:encode(str)
    encoder = DanesOfHonor:makeencoder()
    local t, k, n = {}, 1, #str
    local lastn = n % 3
    for i = 1, n - lastn, 3 do
        local a, b, c = str:byte(i, i + 2)
        local v = a * 0x10000 + b * 0x100 + c

        t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)],
                    encoder[extract(v, 6, 6)], encoder[extract(v, 0, 6)])
        k = k + 1
    end
    if lastn == 2 then
        local a, b = str:byte(n - 1, n)
        local v = a * 0x10000 + b * 0x100
        t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)],
                    encoder[extract(v, 6, 6)], encoder[64])
    elseif lastn == 1 then
        local v = str:byte(n) * 0x10000
        t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)],
                    encoder[64], encoder[64])
    end
    return concat(t)
end

