AddCSLuaFile()
if SERVER then
  include("discord/utils/logging.lua")
  include("discord/utils/messaging.lua")
  include("discord/utils/discord_connection.lua")
  include("discord/utils/http.lua")
  include("discord/utils/mute_helpers.lua")
  include("hooks/discord_muter_hooks.lua")
  include("discord/utils/discord_muter_globals.lua")
end

resource.AddFile("materials/icon256/mute.png")
if CLIENT then
  shouldDrawMute = false
  muteIconAsset = Material("materials/icon256/mute.png", "smooth mips")
  net.Receive("drawMute", function() shouldDrawMute = net.ReadBool() end)
  hook.Add("HUDPaint", "discord_HUDPaint", function()
    if not shouldDrawMute then return end
    surface.SetDrawColor(176, 40, 40, 255)
    surface.SetMaterial(muteIconAsset)
    surface.DrawTexturedRect(32, 32, 256, 256)
  end)
  return
end

util.AddNetworkString("drawMute")
util.AddNetworkString("connectDiscordID")
util.AddNetworkString("discordPlayerTable")
util.AddNetworkString("request_discordPlayerTable")
util.AddNetworkString("discordTestConnection")
util.AddNetworkString("request_discordTestConnection")
util.AddNetworkString("addonVersion")
util.AddNetworkString("request_addonVersion")
util.AddNetworkString("botVersion")
util.AddNetworkString("request_botVersion")
CreateConVar("discord_endpoint", "http://localhost:37405", 1, "Sets the node bot endpoint.")
CreateConVar("discord_api_key", "", 1, "Sets the node bot api-key.")
CreateConVar("discord_name", "Discord", 1, "Sets the Plugin Prefix for helpermessages.") --The name which will be displayed in front of any Message
CreateConVar("discord_server_link", "https://discord.gg/", 1, "Sets the Discord server your bot is present on (eg: https://discord.gg/aBc123).")
CreateConVar("discord_mute_round", 1, 1, "Mute the player until the end of the round.", 0, 1)
CreateConVar("discord_mute_duration", 5, 1, "Sets how long, in seconds, you are muted for after death. No effect if mute_round is on. ", 1, 60)
CreateConVar("discord_auto_connect", 0, 1, "Attempt to automatically match player name to discord name. This happens silently when the player connects. If it fails, it will prompt the user with the \"!discord NAME\" message.", 0, 1)

function joinMessage(target_ply)
  playerMessage("JOIN_DISCORD_PROMPT", target_ply, GetConVar("discord_server_link"):GetString())
  playerMessage("CONNECTION_INSTRUCTIONS", target_ply)
end

function botSync(callback)
  timer.Create("botSyncTimeout", 2.0, 0, function()
    local responseTable = {}
    responseTable["success"] = false
    responseTable["error"] = "host connection failure"
    responseTable["errorMsg"] = "host connection failure"
    responseTable["errorId"] = "HOST_MISSCONFIGURED"
    callback(responseTable)
    timer.Remove("botSyncTimeout")
  end)

  timer.Start("botSyncTimeout")
  httpFetch("sync", {}, function(res)
    timer.Remove("botSyncTimeout")
    callback(res)
  end)
end

net.Receive("connectDiscordID", function(len, calling_ply)
  if not calling_ply:IsSuperAdmin() then return end
  local target_ply = net.ReadEntity()
  local discordID = net.ReadString()
  addConnectionID(target_ply, discordID)
end)

net.Receive("request_discordPlayerTable", function(len, calling_ply)
  if not calling_ply:IsSuperAdmin() then return end
  local connectionsJSON = util.TableToJSON(_G.steamIDToDiscordIDConnectionTable)
  local compressedConnections = util.Compress(connectionsJSON)
  net.Start("discordPlayerTable")
  net.WriteUInt(#compressedConnections, 32)
  net.WriteData(compressedConnections, #compressedConnections)
  net.Send(calling_ply)
end)

net.Receive("request_discordTestConnection", function(len, calling_ply)
  if not calling_ply:IsSuperAdmin() then return end
  botSync(function(res)
    local connectionsJSON = util.TableToJSON(res)
    local compressedConnections = util.Compress(connectionsJSON)
    net.Start("discordTestConnection")
    net.WriteUInt(#compressedConnections, 32)
    net.WriteData(compressedConnections, #compressedConnections)
    net.Send(calling_ply)
  end)
end)

net.Receive("request_botVersion", function(len, calling_ply)
  if not calling_ply:IsAdmin() then return end
  botSync(function(res)
    local botVersion = res["version"]
    local compressedBotVersion = util.Compress(botVersion)
    net.Start("botVersion")
    net.WriteUInt(#compressedBotVersion, 32)
    net.WriteData(compressedBotVersion, #compressedBotVersion)
    net.Send(calling_ply)
  end)
end)

net.Receive("request_addonVersion", function(len, calling_ply)
  if not calling_ply:IsAdmin() then return end
  local addonVersion = "1.7.0"
  local compressedAddonVersion = util.Compress(addonVersion)
  net.Start("addonVersion")
  net.WriteUInt(#compressedAddonVersion, 32)
  net.WriteData(compressedAddonVersion, #compressedAddonVersion)
  net.Send(calling_ply)
end)