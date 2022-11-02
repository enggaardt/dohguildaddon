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

table.sort(RecievedBids, function(a, b)
    if (a.bidType < b.bidType) then
        return true
    elseif (a.bidType > b.bidType) then
        return false
    else
        return a.bid > b.bid
    end
end)

for k, v in pairs(defaults) do
    print(k .. " " .. tostring(v))
end

function DanesOfHonor:CreateExportString()
    local exportString = '{\"version\":' .. version .. ',\"data\":{'

    for realm, players in pairs(DOHGADB) do
        if (realm ~= "profileKeys") then
            exportString = exportString .. '\"' .. realm .. '\": {'
            for player, data in pairs(players) do
                exportString = exportString .. '\"' .. player .. '\": {'
                exportString = exportString .. '\"faction\": \"' .. data["faction"] .. '\",'
                exportString = exportString .. '\"class\": \"' .. FixNil(data["class"]) .. '\",'

                if (data["level"]) then
                    exportString = exportString .. '\"level\": ' .. data["level"] .. ','
                end

                if (data["guildName"]) then
                    exportString = exportString .. '\"guildName\": \"' .. data["guildName"] .. '\",'
                    exportString = exportString .. '\"guildRankName\": \"' .. data["guildRankName"] .. '\",'
                    exportString = exportString .. '\"guildRankIndex\": ' .. data["guildRankIndex"] .. ','
                end
                exportString = exportString .. DanesOfHonor:TradeskillsToJson(data["tradeskills"])
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

function DanesOfHonor:DisplayExportString(exportString)

    local encoded = DanesOfHonor:encode(exportString)

    DohFrame:Show()
    DohFrameScroll:Show()
    DohFrameScrollText:Show()
    DohFrameScrollText:SetText(encoded)
    DohFrameScrollText:HighlightText()

    DohFrameButton:SetScript("OnClick", function(self)
        DohFrame:Hide()
    end)
end
