function FixNil(x)
    if (x == nil) then
        return ''
    else
        return x;
    end
end

function printTable(name, t)
    if (t) then
        print("Table data for " .. name)
        for k, v in pairs(t) do
            print(string.format("- %s = %s", k, tostring(v)));
        end
    else
        print(name .. " is not a table");
    end
end

--[[

        local bidData ={
            name = name,
            bidType = bidType,
            bid = bid,
            roll = roll,
            plusOne = plusOne
        };

                local bidData = {
            name = name,
            bidType = bidType,
            bid = bid,
            roll = roll,
            plusOne = plusOne,
            sortIndex = sortOrder
        };

]]

function BidComparer2(a, b)
    if (not a) then
        DanesOfHonor:Debug("BidComparer: a is nil");
        return 0;
    end

    if (not b) then
        DanesOfHonor:Debug("BidComparer: b is nil");
        return 0;
    end

    return a.sortOrder > b.sortOrder;
end

function BidComparer(a, b)
    if (not a) then
        DanesOfHonor:Debug("BidComparer: a is nil");
        return 0;
    end

    if (not b) then
        DanesOfHonor:Debug("BidComparer: b is nil");
        return 0;
    end

    if (a.bidType > b.bidType) then
        return 1;
    elseif (a.bidType < b.bidType) then
        return -1;
    else
        if (a.bid > b.bid) then
            return 1;
        elseif (a.bid < b.bid) then
            return -1;
        else
            if (a.roll > b.roll) then
                return 1;
            elseif (a.roll < b.roll) then
                return -1;
            else
                if (a.plusOne > b.plusOne) then
                    return -1;
                elseif (a.plusOne < b.plusOne) then
                    return 1;
                else
                    return 0;
                end
            end
        end
    end
end
