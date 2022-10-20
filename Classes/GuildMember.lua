local _, DOHGA = ...;

---@class GuildMember
DOHGA.GuildMember = {};

DOHGA.GuildMember.__index = DOHGA.GuildMember;

local GuildMember = DOHGA.GuildMember;

setmetatable(GuildMember, {
    __call = function(cls, ...)
        return cls.new(...)
    end
})

