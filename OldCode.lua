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
    print(k .. " " .. v)
end


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

function DanesOfHonor:DisplayExportString(exportString)

    local encoded = DanesOfHonor:encode(exportString)

    DohFrame:Show()
    DohFrameScroll:Show()
    DohFrameScrollText:Show()
    DohFrameScrollText:SetText(encoded)
    DohFrameScrollText:HighlightText()

    DohFrameButton:SetScript("OnClick", function(self) DohFrame:Hide() end)
end
