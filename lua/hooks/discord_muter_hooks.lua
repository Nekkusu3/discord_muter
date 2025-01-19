print("RUNNING HOOKS.LUA")

if SERVER then
  include("discord/utils/logging.lua")
  include("discord/utils/messaging.lua")
  include("discord/utils/discord_connection.lua")
  include("discord/utils/http.lua")
  include("discord/utils/mute_helpers.lua")
end

hook.Add("PlayerSay", "discord_PlayerSay", function(target_ply, msg)
  print("PLAYER SAID SOMETHING")
  if string.sub(msg, 1, 9) ~= "!discord " then return end
  tag = string.sub(msg, 10)
  tag_utf8 = ""
  for p, c in utf8.codes(tag) do
    tag_utf8 = string.Trim(tag_utf8 .. " " .. c)
  end

  httpFetch("connect", {
    tag = tag_utf8
  }, function(res)
    if res.answer == 0 then playerMessage("NAME_NOT_FOUND", target_ply, tag) end
    if res.answer == 1 then playerMessage("MULTIPLE_NAMES_FOUND", target_ply, tag) end
    if res.tag and res.id then
      playerMessage("CONNECTION_SUCCESSFUL", target_ply, target_ply:Nick(), target_ply:SteamID(), res.tag)
      steamIDToDiscordIDConnectionTable[target_ply:SteamID()] = res.id
      writeConnectionIDs(steamIDToDiscordIDConnectionTable)
    end
  end)
  return ""
end)

hook.Add("PlayerInitialSpawn", "discord_PlayerInitialSpawn", function(target_ply)
  print("PLAYER SPWANED")
  if _G.steamIDToDiscordIDConnectionTable[target_ply:SteamID()] then
    playerMessage("WELCOME_CONNECTED", target_ply)
  else
    if GetConVar("discord_auto_connect"):GetBool() then
      tag = target_ply:Name()
      tag_utf8 = ""
      for p, c in utf8.codes(tag) do
        tag_utf8 = string.Trim(tag_utf8 .. " " .. c)
      end

      httpFetch("connect", {
        tag = tag_utf8
      }, function(res)
        -- playerMessage("AUTOMATIC_MATCH", target_ply, tag)
        if res.tag and res.id then
          playerMessage("Discord tag \"" .. res.tag .. "\" successfully bound to SteamID \"" .. target_ply:SteamID() .. "\"", target_ply)
          addConnectionID(target_ply, res.id)
        else
          joinMessage(target_ply)
        end
      end)
    else
      joinMessage(target_ply)
    end
  end
end)

hook.Add("ConnectPlayer", "discord_ConnectPlayer", function(target_ply, discordID) addConnectionID(target_ply, discordID) end)
hook.Add("DisconnectPlayer", "discord_DisconnectPlayer", function(target_ply) removeConnectionID(target_ply) end)

hook.Add("MutePlayer", "discord_MutePlayer", function(target_ply, duration)
  print("MUTING PLAYER")
  print(target_ply)
  print(duration)
  print("##########")
  if duration > 0 then
    mutePlayer(target_ply, duration)
  else
    mutePlayer(target_ply)
  end
end)

hook.Add("UnmutePlayer", "discord_UnmutePlayer", function(target_ply) unmutePlayer(target_ply) end)
hook.Add("PlayerSpawn", "discord_PlayerSpawn", function(target_ply) unmutePlayer(target_ply) end)
hook.Add("PlayerDisconnected", "discord_PlayerDisconnected", function(target_ply) unmutePlayer(target_ply) end)
hook.Add("ShutDown", "discord_ShutDown", function() unmutePlayer() end)
hook.Add("OnStartRound", "discord_OnStartRound", function() unmutePlayer() end)

hook.Add("PostPlayerDeath", "discord_PostPlayerDeath", function(target_ply)
  print("POST PLAYER DEATH")
  if getAlivePlayer() <= 1 then return end
  if commonRoundState() == 1 then
    if GetConVar("discord_mute_round"):GetBool() then
      mutePlayer(target_ply)
    else
      local duration = GetConVar("discord_mute_duration"):GetInt()
      mutePlayer(target_ply, duration)
    end
  end
end)

hook.Add("OnEndRound", "discord_OnEndRound", function()
  print("ROUND END")
  unmuteAll()
end)

hook.Add("OnStartRound", "discord_OnStartRound", function()
  print("ROUND START")
  unmuteAll()
end)

-- TTT Specific
hook.Add("TTTEndRound", "discord_TTTEndRound", function()
  print("ROUND END TTT")
  unmuteAll()
end)

hook.Add("TTTBeginRound", "discord_TTTBeginRound", function()
  print("ROUND START TTT")
  unmuteAll()
end)