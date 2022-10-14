function getPlayerIdentifier(player)
    for k, v in pairs(GetPlayerIdentifiers(player)) do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            identifier = string.sub(v, 9, string.len(v))
        end
    end
    return identifier
end

function log(message)
    local webHook = Config.DiscordWebhook
    local embedData = { {
        ['title'] = 'Giveaway Logger',
        ['color'] = Config.WebhookColor,
        ['description'] = message,
        ['author'] = {
            ['name'] = "Giveaway Logger",
            ['icon_url'] = "https://avatars.githubusercontent.com/u/51883097?v=4"
        }
    } }
    PerformHttpRequest(webHook, nil, 'POST', json.encode({
        username = 'Giveaway Logger',
        embeds = embedData
    }), {
        ['Content-Type'] = 'application/json'
    })
end

-- Credits to ox_lib
function versionCheck(repository)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local currentVersion = GetResourceMetadata(resource, 'version', 0)

    if currentVersion then
        currentVersion = currentVersion:match('%d%.%d+%.%d+')
    end

    if not currentVersion then return print(("^1Unable to determine current resource version for '%s' ^0"):format(resource)) end

    SetTimeout(1000, function()
        PerformHttpRequest(('https://api.github.com/repos/%s/releases/latest'):format(repository),
            function(status, response)
                if status ~= 200 then return end

                response = json.decode(response)
                if response.prerelease then return end

                local latestVersion = response.tag_name:match('%d%.%d+%.%d+')
                if not latestVersion or latestVersion == currentVersion then return end

                local cMajor, cMinor = string.strsplit('.', currentVersion, 2)
                local lMajor, lMinor = string.strsplit('.', latestVersion, 2)

                if tonumber(cMajor) < tonumber(lMajor) or tonumber(cMinor) < tonumber(lMinor) then
                    return print(('^3An update is available for %s (current version: %s)\r\n%s^0'):format(resource,
                        currentVersion, response.html_url))
                end
            end, 'GET')
    end)
end

function deleteData(code)
    local queries = {
        { query = 'DELETE FROM `vyzo_giveaway_code` WHERE `code` = (:code)', values = { ['code'] = code } },
        { query = 'DELETE FROM `vyzo_giveaway_log` WHERE `code` = (:code)', values = { ['code'] = code } }
    }

    MySQL.transaction(queries, function(success)
        print('Data code ' .. code .. ' deleted')
    end)
end
