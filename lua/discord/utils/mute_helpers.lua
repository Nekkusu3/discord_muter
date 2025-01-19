if SERVER then
    include("discord/utils/messaging.lua")
end

function drawMuteIcon(target_ply, drawMute)
    net.Start("drawMute")
    net.WriteBool(drawMute)
    net.Send(target_ply)
end

function isMuted(target_ply)
    print("PLAYER IS MUTED")
    print(_G.mutedPlayerTable[target_ply])
    print("######")
    return _G.mutedPlayerTable[target_ply]
end

-- UnMute Player Alias (for compatability)
function unmute(target_ply)
    print("ALSO UNMUTING PLAYER")
    print(target_ply)
    unmutePlayer(target_ply)
end

function muteAll(duration)
    print("MUTE ALL")
    local players = player.GetAll()
    for _, ply in ipairs(players) do
        mutePlayer(ply, duration)
    end
end

function unmuteAll()
    print("UNMUTE ALL")
    local players = player.GetAll()
    for _, ply in ipairs(players) do
        unmutePlayer(ply, duration)
    end
end

function http_mute(muteStatus, target_ply, msg, duration)
    httpFetch("mute", {
        mute = muteStatus,
        id = _G.steamIDToDiscordIDConnectionTable[target_ply:SteamID()]
    }, function(res)
        if res and res.success then
            if duration then
                playerMessage(msg, target_ply, duration)
                timer.Simple(duration, function() unmutePlayer(target_ply) end)
            else
                playerMessage(msg, target_ply)
            end

            drawMuteIcon(target_ply, true)
            _G.mutedPlayerTable[target_ply] = true
        elseif res and res.errorMsg then
            announceMessage("ERROR_MESSAGE", res.errorMsg)
        end
    end)
end

function mutePlayer(target_ply, duration)
    print("MUTING PLAYER")
    print(target_ply)
    print(duration)
    print("########")

    if target_ply and _G.steamIDToDiscordIDConnectionTable[target_ply:SteamID()] and not isMuted(target_ply) then http_mute(true, target_ply, "MUTED_PLAYER", duration) end
end

-- Mute Player Alias (for compatability)
function mute(target_ply)
    print("ALSO MUTING PLAYER")
    mutePlayer(target_ply)
end

function commonRoundState()
    if (gmod.GetGamemode().Name == "Trouble in Terrorist Town" or gmod.GetGamemode().Name == "TTT2 (Advanced Update)") or gmod.GetGamemode().Name == "TTT2" then -- Round state 3 => Game is running
        return (GetRoundState() == 3) and 1 or 0
    end

    if gmod.GetGamemode().Name == "Murder" then -- Round state 1 => Game is running
        return (gmod.GetGamemode():GetRound() == 1) and 1 or 0
    end
    -- Round state could not be determined
    return -1
end

function getAlivePlayer()
    local players = player.GetAll()
    local alivePlayers = #players
    for _, ply in ipairs(players) do
        if not ply:Alive() and ply:IsSpec() then alivePlayers = alivePlayers - 1 end
    end
    return alivePlayers
end

function unmutePlayer(target_ply)
    print("TRYING TO UNMUTE PLAYER")
    if not target_ply then
        print("CANT UNMUTE PLAYER")
        print(target_ply)
        print("########")
        return
    end

    if target_ply and _G.steamIDToDiscordIDConnectionTable[target_ply:steamID()] and isMuted(target_ply) then 
        http_mute(false, target_ply, "UNMUTED_PLAYER")
    end
end