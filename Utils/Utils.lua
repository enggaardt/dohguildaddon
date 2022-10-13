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
