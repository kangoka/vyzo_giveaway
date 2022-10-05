<p align="center">
  <img width="300" height="300" src="https://i.imgur.com/meFc9Ie.gif">
</p>

This a script to make things easier when you want to host a giveaway on your roleplay server by creating a code and can be redeemed by the players.

# Dependency
1. [oxmysql](https://github.com/overextended/oxmysql)
2. [ox_lib](https://github.com/overextended/ox_lib)

# Installation
1. Git clone this repository or download the latest release
2. Configure `config.lua` 
3. Open `client.lua` and change the notification to yours
4. Import the sql `vyzo_giveaway.sql`
5. Add `ensure vyzo_giveaway` on `server.cfg` after oxmysql and oxlib

# Usage
- /cga to create a new giveaway
- /redeem to redeem a code

# Features
- 0.00ms resmon when idle and 0.001ms for a blink of an eye when executing the command
- Use your own code or auto generated code with flexible configuration
- Set how many a code can be redeemed by players
- Support logging to Discord using Discord webhook
- Check the code format before executing any queries (check `server.lua`, default are commented)
- Available in two languages English and Bahasa Indonesia
- Supported reward type: `money`, `bank`, `items` (for ox_inventory users, items are not attached to database so you can give weapons too)

# Preview
https://imgur.com/a/9GSIAzA

# Todo
- [ ] Add reward type: `car`
