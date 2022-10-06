local identifier = nil

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        versionCheck('kangoka/vyzo_giveaway')
    end
end)

RegisterCommand('cga', function(source)
    TriggerClientEvent("openDialogCreate", source)
end, true)

RegisterCommand('redeem', function(source)
    TriggerClientEvent("openDialogRedeem", source)
end, false)

ESX.RegisterServerCallback('vyzo_giveaway:createGiveaway', function(source, cb, data, code)
    if data == nil or data[3] == nil then
        return cb(false)
    end

    if data[1] ~= nil and data[1] ~= '' then
        -- Check if the code exists
        MySQL.query('SELECT code FROM vyzo_giveaway_code WHERE code = ?', {data[1]}, function(result)
            if #result > 0 then
                -- Update the data if the code is exists
                MySQL.update('UPDATE vyzo_giveaway_code SET code = ?, maxuse = ?, reward = ?, quantity = ? WHERE code = ?', {data[1], data[2], data[3], data[4], data[1]}, function(affectedRows)
                    if affectedRows then
                        return cb('updated')
                    end
                end)
            end
        end)
        MySQL.insert('INSERT INTO vyzo_giveaway_code (code, maxuse, reward, quantity) VALUES (?, ?, ?, ?)', {data[1], data[2], data[3], data[4]}, function(id)
            if type(id) == 'number' then
                return cb('success', data[1])
            end
        end)
    else
        data[1] = Config.CodeId .. string.upper(ESX.GetRandomString(Config.LengthNum))
        MySQL.insert('INSERT INTO vyzo_giveaway_code (code, maxuse, reward, quantity) VALUES (?, ?, ?, ?)', {data[1], data[2], data[3], data[4]}, function(id)
            if type(id) == 'number' then
                return cb('success', data[1])
            end
        end)
    end
end)

ESX.RegisterServerCallback('vyzo_giveaway:redeemGiveaway', function(source, cb, data)
    if data[1] == nil then
        return cb('empty')
    end

    -- Uncomment condition below if you want to use generated code all the time
    -- Check if the inputed code is matched with the format code
    -- if string.find(data[1], Config.CodeId) == nil or (string.len(Config.CodeId) + Config.LengthNum) ~= string.len(data[1]) then
    --     return cb('format')
    -- end

    -- Check if the code exist
    MySQL.query('SELECT code, maxuse, reward, quantity FROM vyzo_giveaway_code WHERE code = ?', {data[1]}, function(result)
        if #result > 0 then
            MySQL.query('SELECT code FROM vyzo_giveaway_log WHERE code = ?', {data[1]}, function(result2)
                -- Check the player redeeming will exceed the maximum code usage
                if #result2 + 1 > result[1].maxuse then
                    if Config.DeleteData then
                        deleteData(data[1])
                    end
                    return cb('limit')
                else
                    local xPlayer = ESX.GetPlayerFromId(source)
                    if result[1].reward == 'bank' or result[1].reward == 'money' then
                        xPlayer.addAccountMoney(result[1].reward, result[1].quantity)
                    else
                        if xPlayer.canCarryItem(result[1].reward, result[1].quantity) then
                            xPlayer.addInventoryItem(result[1].reward, result[1].quantity)
                        else
                            return cb('full')
                        end
                    end
                    MySQL.insert('INSERT INTO vyzo_giveaway_log (identifier, code) VALUES (?, ?)', {getPlayerIdentifier(source), data[1]}, function(id)
                        if type(id) == 'number' then
                            if Config.Log then
                                log(_U('log_message', xPlayer.getName(), data[1], result[1].quantity, result[1].reward))
                            end
                            if Config.DeleteData and #result2 + 1 >= result[1].maxuse then
                                deleteData(data[1])
                            end
                            return cb('success')
                        end
                    end)
                end
            end)
        else
            return cb('not_exist')
        end
    end)
end)

function getPlayerIdentifier(player)
    for k,v in pairs(GetPlayerIdentifiers(player))do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            identifier = string.sub(v, 9, string.len(v))
        end
    end
    return identifier
end

function log(message)
    local webHook = Config.DiscordWebhook
    local embedData = {{
        ['title'] = 'Code Claimed',
        ['color'] = Config.WebhookColor,
        ['description'] = message,
        ['author'] = {
            ['name'] = "Code Claim Logger",
            ['icon_url'] = "https://avatars.githubusercontent.com/u/51883097?v=4"
        }
    }}
    PerformHttpRequest(webHook, nil, 'POST', json.encode({
        username = 'Code Claim Logger',
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
		PerformHttpRequest(('https://api.github.com/repos/%s/releases/latest'):format(repository), function(status, response)
			if status ~= 200 then return end

			response = json.decode(response)
			if response.prerelease then return end

			local latestVersion = response.tag_name:match('%d%.%d+%.%d+')
			if not latestVersion or latestVersion == currentVersion then return end

			local cMajor, cMinor = string.strsplit('.', currentVersion, 2)
			local lMajor, lMinor = string.strsplit('.', latestVersion, 2)

			if tonumber(cMajor) < tonumber(lMajor) or tonumber(cMinor) < tonumber(lMinor) then
				return print(('^3An update is available for %s (current version: %s)\r\n%s^0'):format(resource, currentVersion, response.html_url))
			end
		end, 'GET')
	end)
end

function deleteData(code)
    local queries = {
        { query = 'DELETE FROM `vyzo_giveaway_code` WHERE `code` = (:code)', values = {['code'] = code}},
        { query = 'DELETE FROM `vyzo_giveaway_log` WHERE `code` = (:code)', values = {['code'] = code}}
    }

    MySQL.transaction(queries, function(success)
        print('Data code ' .. code .. ' deleted')
    end)
end
