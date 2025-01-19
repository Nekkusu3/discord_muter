_G.mutedPlayerTable = {}
_G.steamIDToDiscordIDConnectionTable = {}

if SERVER then
    include("discord/utils/discord_connection.lua")
    _G.steamIDToDiscordIDConnectionTable = getConnectionIDs()
end