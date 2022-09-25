local BiddingFrame = LibStub("AceGUI-3.0")
local f 

function biddingFrameShow(itemLink)
    -- Create a container frame

    local currentPoints = 0 -- DanesOfHonor:GetPlayerPoints(UnitName("PLAYER"));
    local halfPoints = math.ceil(currentPoints / 2);

    f = BiddingFrame:Create("Window")
    f:SetCallback("OnClose", function(widget) BiddingFrame:Release(widget) end)
    f:SetTitle("DoH Bidder")
    f:SetLayout("Flow")
    f:EnableResize(false)
    f:SetWidth(626)
    f:SetHeight(150)

    -- Create Item Container --
    local itemContainer = BiddingFrame:Create("InlineGroup")
    itemContainer:SetLayout("Fill")
    itemContainer:SetWidth(635)
    itemContainer:SetHeight(35)

    -- Create Item Link
    local item = BiddingFrame:Create("InteractiveLabel")
    item:SetWidth(120)
    item:SetText(itemLink)
    item:SetFontObject(GameFontNormalLarge)
    item:SetCallback("OnClick", function()
        SetItemRef(itemLink)
    end)
    itemContainer:SetWidth(635)
    itemContainer:AddChild(item)

    -- Create Buttons
    local btnHalf = BiddingFrame:Create("Button")
    btnHalf:SetWidth(120)
    btnHalf:SetText("BID " .. halfPoints)
    btnHalf:SetDisabled(halfPoints <= DOHGlobals.MINIMUMBID);

    btnHalf:SetCallback("OnClick", function()
        BiddingFrame:ManageBid(DOHGlobals.BIDTYPES.BIDHALF, halfPoints)
    end)

    local btnFixed = BiddingFrame:Create("Button")
    btnFixed:SetWidth(120)
    btnFixed:SetText("BID " .. DOHGlobals.MINIMUMBID)
    btnFixed:SetDisabled(currentPoints < DOHGlobals.MINIMUMBID);
    btnFixed:SetCallback("OnClick", function()
        BiddingFrame:ManageBid(DOHGlobals.BIDTYPES.BIDMIN, currentPoints)
    end)

    local btnMS = BiddingFrame:Create("Button")
    btnMS:SetWidth(120)
    btnMS:SetText("Main Spec")
    btnMS:SetCallback("OnClick", function()
        BiddingFrame:ManageBid(DOHGlobals.BIDTYPES.MAINSPEC, 0)
    end)

    local btnDS = BiddingFrame:Create("Button")
    btnDS:SetWidth(120)
    btnDS:SetText("Dual Spec")
    btnDS:SetCallback("OnClick", function()
        BiddingFrame:ManageBid(DOHGlobals.BIDTYPES.DUALSPEC, 0)
    end)

    local btnOS = BiddingFrame:Create("Button")
    btnOS:SetWidth(120)
    btnOS:SetText("Off Spec")
    btnOS:SetCallback("OnClick", function()
        BiddingFrame:ManageBid(DOHGlobals.BIDTYPES.OFFSPEC, 0)
    end)

    -- Add the button to the container
    f:AddChild(itemContainer)
    f:AddChild(btnHalf)
    f:AddChild(btnFixed)
    f:AddChild(btnMS)
    f:AddChild(btnDS)
    f:AddChild(btnOS)
end

function BiddingFrame:ManageBid(type, points)
    if (type == DOHGlobals.BIDTYPES.BIDHALF) then
        DanesOfHonor:SendCommMessage(DOHGlobals.COMMPREFIX, "auction bid half", "RAID")
    elseif (type == DOHGlobals.BIDTYPES.BIDMIN) then
        RandomRoll(1, 100)
    elseif (type == DOHGlobals.BIDTYPES.MAINSPEC) then
        RandomRoll(1, 99)
    elseif (type == DOHGlobals.BIDTYPES.DUALSPEC) then
        RandomRoll(1, 98)
    elseif (type == DOHGlobals.BIDTYPES.OFFSPEC) then
        RandomRoll(1, 97)
    end

    f:Hide()
end

