Config = {}

Config.Locale = 'en'

Config.Log            = false
-- Make sure to put your Discord webhook if you set Config.Log to true
Config.DiscordWebhook = ''
Config.WebhookColor   = '14423100'
--[[
    More colors:
    default = 14423100
    blue = 255
    red = 16711680
    green = 65280
    white = 16777215
    black = 0
    orange = 16744192
    yellow = 16776960
    pink = 16761035
    lightgreen = 65309
]]
--

Config.CodeId    = 'VYZO-'
-- Better not to put more than 9
Config.LengthNum = 8
-- The code will be like VYZO-AN458NSI

-- Set to true if you want to delete the data after a code reached maximum usage
Config.DeleteData = false

-- This config will be used when no plate was given on the reward data
-- Note: Max plate length is 8 (including spaces)
Config.Plate = 'VYZO '
Config.PlateNum = 3
-- The vehicle reward will be stored in this garage
Config.DefaultGarage = 'SanAndreasAvenue'
