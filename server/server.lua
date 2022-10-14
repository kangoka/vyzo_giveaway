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

    local xPlayer = ESX.GetPlayerFromId(source)
    if data[1] ~= nil and data[1] ~= '' then
        -- Check if the code exists
        MySQL.query('SELECT code FROM vyzo_giveaway_code WHERE code = ?', { data[1] }, function(result)
            if #result > 0 then
                -- Update the data if the code is exists
                MySQL.update('UPDATE vyzo_giveaway_code SET code = ?, maxuse = ?, reward = ?, sameuser = ?, quantity = ? WHERE code = ?'
                    , { data[1], data[2], data[3], data[4], data[5], result[1].code }, function(affectedRows)
                    if affectedRows then
                        if Config.Log then
                            log(_U('log_message_create', xPlayer.getName(), data[1], data[5], data[3]))
                        end
                        return cb('updated')
                    end
                end)
            else
                MySQL.insert('INSERT INTO vyzo_giveaway_code (code, maxuse, reward, sameuser, quantity) VALUES (?, ?, ?, ?, ?)'
                    ,
                    { data[1], data[2], data[3], data[4], data[5] }, function(id)
                    if type(id) == 'number' then
                        if Config.Log then
                            log(_U('log_message_create', xPlayer.getName(), data[1], data[5], data[3]))
                        end
                        return cb('success', data[1])
                    end
                end)
            end
        end)
    else
        data[1] = Config.CodeId .. string.upper(ESX.GetRandomString(Config.LengthNum))
        MySQL.insert('INSERT INTO vyzo_giveaway_code (code, maxuse, reward, sameuser, quantity) VALUES (?, ?, ?, ?, ?)',
            { data[1], data[2], data[3], data[4], data[5] }, function(id)
            if type(id) == 'number' then
                if Config.Log then
                    log(_U('log_message_create', xPlayer.getName(), data[1], data[5], data[3]))
                end
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
    MySQL.query('SELECT code, maxuse, sameuser, reward, quantity FROM vyzo_giveaway_code WHERE code = ?', { data[1] },
        function(result)
            if #result > 0 then
                MySQL.query('SELECT identifier, code FROM vyzo_giveaway_log WHERE code = ?', { data[1] },
                    function(result2)
                        local player = getPlayerIdentifier(source)
                        -- Check if a player can redeem the same code more than one
                        if result[1].sameuser == 0 then
                            for k, v in pairs(result2) do
                                if player == v.identifier then
                                    return cb('same_user')
                                end
                            end
                        end
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
                            elseif string.match(result[1].reward, 'car_') then
                                -- Thanks to https://stackoverflow.com/a/65023405 for the split function. Lua have split function when?
                                local args = {}
                                for a in result[1].reward:gmatch("([^_]+)") do
                                    table.insert(args, a)
                                end

                                if args[3] == nil then
                                    args[3] = Config.Plate .. string.upper(ESX.GetRandomString(Config.PlateNum))
                                end

                                MySQL.insert('INSERT INTO owned_vehicles (owner, plate, vehicle, stored, parking) VALUES (?, ?, ?, ?, ?)'
                                    ,
                                    { player, args[3],
                                        json.encode({ model = joaat(args[2]), plate = args[3] }), 1, Config.DefaultGarage
                                    }, function(rowsChanged)
                                    if (rowsChanged) then
                                        return cb('success')
                                    end
                                end)
                            else
                                if xPlayer.canCarryItem(result[1].reward, result[1].quantity) then
                                    xPlayer.addInventoryItem(result[1].reward, result[1].quantity)
                                else
                                    return cb('full')
                                end
                            end
                            MySQL.insert('INSERT INTO vyzo_giveaway_log (identifier, code) VALUES (?, ?)',
                                { player, data[1] }, function(id)
                                if type(id) == 'number' then
                                    if Config.Log then
                                        log(_U('log_message_redeem', xPlayer.getName(), data[1], result[1].quantity,
                                            result[1].reward))
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
