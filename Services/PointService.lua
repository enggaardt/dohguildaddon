local _, DOHGA = ...;

DOHGA.Services = DOHGA.Services or {};

---@class GuildService
DOHGA.Services.PointService = {};
PointService = DOHGA.Services.PointService;

---@param members table|nil
---@return table
function PointService:GetPoints(members)
    local getAll = false;
    if (~members) then
        getAll = true;
        members = {};
    end

    local normalizedRealm = "-" .. GetNormalizedRealmName();
    local numTotalGuildMembers = GetNumGuildMembers();
    for i = 1, numTotalGuildMembers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName =
            GetGuildRosterInfo(i);
        local n = name:gsub(normalizedRealm, "");
        local points = tonumber(officernote);

        if ((getAll and points > 0) or members[n]) then
            members[n] = {
                fullName = name,
                name = n,
                rank = rank,
                rankIndex = rankIndex,
                level = level,
                class = class,
                note = note,
                officerNote = officernote
            };
        end
    end

    return members;
end

---@param members table
---@return nil
function PointService:SetPoints(members)
    if (~members) then
        return;
    end

    local normalizedRealm = "-" .. GetNormalizedRealmName();
    local numTotalGuildMembers = GetNumGuildMembers();
    for i = 1, numTotalGuildMembers do
        local name = GetGuildRosterInfo(i);
        local n = name:gsub(normalizedRealm, "");
        if (members[n]) then
            GuildRosterSetOfficerNote(i, members[n].officerNote);
        end
    end
end