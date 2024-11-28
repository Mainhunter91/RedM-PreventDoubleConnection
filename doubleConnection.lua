local connectedPlayers = {}
local Dev = false -- Activates Dev -prints

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
    local src = source
    local steamIdentifier = nil
    local licenseIdentifier = nil

    deferrals.defer()

    Citizen.Wait(100)
    
    deferrals.update("Checking player identifiers...")

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(identifier, 1, string.len("steam:")) == "steam:" then
            steamIdentifier = identifier
        elseif string.sub(identifier, 1, string.len("license:")) == "license:" then
            licenseIdentifier = identifier
        end
    end

    if not steamIdentifier and not licenseIdentifier then
        deferrals.done("Steam oder Rockstarlizenz nicht gefunden! Gehe sicher, dass du Steam und Rockstar geöffnet hast.")
        return
    end

    for playerId, identifiers in pairs(connectedPlayers) do
        if identifiers.steam == steamIdentifier or identifiers.license == licenseIdentifier then
            deferrals.done("Du bist bereits mit dem Server verbunden!")
            return
        end
    end

    connectedPlayers[src] = {
        steam = steamIdentifier,
        license = licenseIdentifier,
        lastActive = os.time()
    }

    deferrals.done()
end)

AddEventHandler("playerDropped", function(reason)
    local src = source

    if connectedPlayers[src] then
        print("Spieler getrennt: ", connectedPlayers[src].steam or connectedPlayers[src].license)
        connectedPlayers[src] = nil 
    end
end)

if Dev then
	RegisterCommand("listPlayers", function()
		print("Verbundene Spieler:")
		for playerId, identifiers in pairs(connectedPlayers) do
			print("Spieler ID: " .. playerId .. ", Steam: " .. (identifiers.steam or "Unbekannt") .. ", Lizenz: " .. (identifiers.license or "Unbekannt") .. ", Letzte Aktivität: " .. os.date("%Y-%m-%d %H:%M:%S", identifiers.lastActive))
		end
	end, true)
end

CreateThread(function()
    while true do
        Citizen.Wait(30000)
        local currentTime = os.time()
        for playerId, identifiers in pairs(connectedPlayers) do
            if currentTime - identifiers.lastActive > 30 then
				if Dev then
					print("Entferne inaktiven Spieler: ", identifiers.steam or identifiers.license)
				end
                connectedPlayers[playerId] = nil
            end
        end
    end
end)

RegisterServerEvent("playerActivity")
AddEventHandler("playerActivity", function()
    local src = source
    if connectedPlayers[src] then
        connectedPlayers[src].lastActive = os.time()
    end
end)