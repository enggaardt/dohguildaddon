local BidsFrame = LibStub("AceGUI-3.0")
local pointContainer, msContainer, dsContainer, osContainer

function bidsFrameShow()
    -- Create a container frame
    local f = BidsFrame:Create("Window")
    f:SetCallback("OnClose", function(widget)
        BidsFrame:Release(widget)
    end)
    f:SetTitle("Incomming Bids")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(825)

    -- Create Item Container --
    pointContainer = BidsFrame:Create("InlineGroup")
    pointContainer:SetLayout("Fill")
    pointContainer:SetWidth(200)
    pointContainer:SetHeight(35)
    pointContainer:SetTitle("Point Bids");
    f:AddChild(pointContainer)

    -- Create Item Container --
    msContainer = BidsFrame:Create("InlineGroup")
    msContainer:SetLayout("Fill")
    msContainer:SetWidth(200)
    msContainer:SetHeight(35)
    msContainer:SetTitle("MS Bids");
    f:AddChild(msContainer)

    -- Create Item Container --
    dsContainer = BidsFrame:Create("InlineGroup")
    dsContainer:SetLayout("Fill")
    dsContainer:SetWidth(200)
    dsContainer:SetHeight(35)
    dsContainer:SetTitle("DS Bids");
    f:AddChild(dsContainer)

    -- Create Item Container --
    osContainer = BidsFrame:Create("InlineGroup")
    osContainer:SetLayout("Fill")
    osContainer:SetWidth(200)
    osContainer:SetHeight(35)
    osContainer:SetTitle("OS Bids");
    f:AddChild(osContainer)
end

function bidsFrameAddBid(name, type, bid, roll)

    if (type == DOHGlobals.BIDTYPES.BIDHALF) then
        local player = BidsFrame:Create("Label")
        player:SetText(name .. " " .. "(" .. bid .. ")")
        pointContainer:AddChild(player)
    end
    if (type == DOHGlobals.BIDTYPES.BIDMIN) then
        local player = BidsFrame:Create("Label")
        player:SetText(name .. " " .. "(" .. bid .. " / " .. roll .. ")")
        pointContainer:AddChild(player)
    end
    if (type == DOHGlobals.BIDTYPES.MAINSPEC) then
        local player = BidsFrame:Create("Label")
        player:SetText(name .. " " .. "(" .. roll .. ")")
        msContainer:AddChild(player)
    end
    if (type == DOHGlobals.BIDTYPES.DUALSPEC) then
        local player = BidsFrame:Create("Label")
        player:SetText(name .. " " .. "(" .. roll .. ")")
        dsContainer:AddChild(player)
    end
    if (type == DOHGlobals.BIDTYPES.OFFSPEC) then
        local player = BidsFrame:Create("Label")
        player:SetText(name .. " " .. "(" .. roll .. ")")
        osContainer:AddChild(player)
    end
end

