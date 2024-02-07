local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/HugeGamesio/HugeGamesv3/main/Lib.lua"))()


local Settings = {}
Settings.Magnet = false;
Settings.SignalDebug = false;

Settings.HugeMinPrice = 2000000;
Settings.ExclusiveMinPrice = 20000;
Settings.TitanicMinPrice = 10000000;

Settings.blacklistedRemotes = {"Send Position", "Player Statues: Get Statue Data", "Orbs_ClaimMultiple", "Lootbags_Claim"};
Settings.blacklistedEvents =  {"Breakables_Ping", "Breakables_Created", "AutoClicker_Click", "Breakables_PlayerDealDamage", "PlayerGraphicsSetting_Get"};

Settings.TPedLootbags = {}

local UI = UILib:CreateUI()
UI:SetScale(1)

local Tab = UI:CreateTab("Rune | Web")
Tab:Label("Rune", {Color=Color3.fromRGB(0,155,255), Allignment=Enum.TextXAlignment.Center})
Tab:Label("#1 Exploit Provider", {Color=Color3.fromRGB(255,255,255), Allignment=Enum.TextXAlignment.Center})

local _L = require(game.ReplicatedStorage.ClientLibrary)
local _F = {}


local function ParseNumberSmart(num)
	return _L.Functions.ParseNumberSmart(num)
end


local screen_gui = Instance.new("ScreenGui")
screen_gui.IgnoreGuiInset = true
screen_gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
screen_gui.ResetOnSpawn = true
screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen_gui.Parent = game.Players.LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.BackgroundColor3 = Color3.new(1, 1, 1)
frame.BackgroundTransparency = 1
frame.BorderColor3 = Color3.new(0, 0, 0)
frame.BorderSizePixel = 0
frame.Position = UDim2.new(0.788735628, 0, 0.479085743, 0)
frame.Size = UDim2.new(0.211264297, 0, 0.520914257, 0)
frame.Visible = true
frame.Parent = screen_gui

local uilist_layout = Instance.new("UIListLayout")
uilist_layout.SortOrder = Enum.SortOrder.LayoutOrder
uilist_layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
uilist_layout.Parent = frame


local text_label = Instance.new("TextLabel")
text_label.Font = Enum.Font.FredokaOne
text_label.Text = "bought with 1m gems"
text_label.TextColor3 = Color3.new(0.937255, 1, 0.376471)
text_label.TextScaled = true
text_label.TextSize = 14
text_label.TextWrapped = true
text_label.BackgroundColor3 = Color3.new(1, 1, 1)
text_label.BackgroundTransparency = 1
text_label.BorderColor3 = Color3.new(0, 0, 0)
text_label.BorderSizePixel = 0
text_label.Position = UDim2.new(0, 0, 0.538005829, 0)
text_label.Size = UDim2.new(0.989869416, 0, 0.0769990236, 0)
text_label.Visible = true

local uistroke = Instance.new("UIStroke")
uistroke.Thickness = 2
uistroke.Parent = text_label

local runLogs = {}


local function Log(price, item, sellerUserId)
	local newLog = text_label:Clone()
	newLog.Text = "Bought " .. tostring(item) .. " for " .. _L.Functions.FormatAbbreviated(price) .. " Gems from " .. tostring(sellerUserId)
	newLog.Parent = frame

	if #runLogs >= 10 then
		runLogs[10]:Destroy()
		runLogs[10] = nil
	end
	table.insert(runLogs, 1, newLog)
	_L.Message.New("Bought " .. tostring(item) .. " for " .. _L.Functions.FormatAbbreviated(price) .. " Gems from " .. tostring(sellerUserId))
end


local Misc = UI:CreateTab("Util")
local SettingsSection = Misc:Section("Settings")
local DebugSection = Misc:Section("Debug")


local Remotes = {}
for i, v in next, game:GetService("ReplicatedStorage").Network:GetChildren() do
	table.insert(Remotes, v.Name)
end
table.sort(Remotes)

DebugSection:Toggle("Network Debug", false, function(NewState)
	Settings.NetworkDebug = NewState
end)

DebugSection:Toggle("Signal Debug", false, function(NewState)
	Settings.SignalDebug = NewState
end)


SettingsSection:Toggle("Sniper ENABLED", true, function(NewState)
	Settings.SniperEnabled = NewState
end)

SettingsSection:Input("Huge min price (Default 500k)", function(InputText)
	local amount = tonumber(ParseNumberSmart(InputText))

	if not amount then
		return
	end

	Settings.HugeMinPrice = amount
end)

SettingsSection:Input("Exclusive min price (Default 5k)", function(InputText)
	local amount = tonumber(ParseNumberSmart(InputText))

	if not amount then
		return
	end

	Settings.ExclusiveMinPrice = amount
end)


local InstanceToString = function(Instance)
	local splitted = string.split(Instance:GetFullName(), ".")
	local str = ("game:GetService(\"%s\")"):format(splitted[1])

	for i = 2, #splitted do
		if string.find(splitted[i], "%W") or string.find(splitted[i], "%s") then
			str = ("%s[\"%s\"]"):format(str, splitted[i])
		else
			str = ("%s.%s"):format(str, splitted[i])
		end
	end

	return str
end

local stringify
stringify = function(v, spaces, usesemicolon, depth)
	if type(v) == "string" then
		return ('"%s"'):format(v)
	elseif type(v) ~= 'table' then
		return tostring(v)
	elseif typeof(v) == "Instance" then
		return InstanceToString(v)
	elseif not next(v) then
		return '{}'
	end

	spaces = spaces or 4
	depth = depth or 1

	local space = (" "):rep(depth * spaces)
	local sep = usesemicolon and ";" or ","
	local concatenationBuilder = {"{"}

	for k, x in next, v do
		table.insert(concatenationBuilder, ("\n%s[%s] = %s%s"):format(space,type(k)=='number'and tostring(k) or('"%s"'):format(tostring(k)), stringify(x, spaces, usesemicolon, depth+1), sep))
	end

	local s = table.concat(concatenationBuilder)
	return ("%s\n%s}"):format(s:sub(1,-2), space:sub(1, -spaces-1))
end

local function ProcessBroadcast(seller, listings)
	if Settings.SniperEnabled == false then
		return
	end

	for offerUID, val in pairs(listings) do
		local cost = val.DiamondCost or 2^53
		if val and (val.ItemData.data or val.ItemData.id) then
			local purchase = false
			local id = (val.ItemData.data and val.ItemData.data.id) or val.ItemData.id

            if string.find(id:lower(), "titanic") and string.find(id:lower(), "present") then
                if cost <= 100000 then
                    purchase = true
                end
            end

			if (val.ItemData.class == "Pet" or _L.Directory.Pets[id]) and id:lower() ~= "banana" and id:lower() ~= "coin" then
				if string.find(id:lower(), "huge") then
					if cost <= Settings.HugeMinPrice then
						purchase = true
					end
				end

				if (_L.Directory.Pets[id].exclusiveLevel or 0) > 0 then
					if cost <= Settings.ExclusiveMinPrice then
						purchase = true
					end
				end
			end

			if purchase == true and Settings.SniperEnabled == true then
task.wait(3.3)
				local success, a = _L.Network.Invoke("Booths_RequestPurchase", seller.UserId, offerUID)
				warn("BOOTH PURCHASE STATUS:", success, a)
				if success then
					Log(cost, id, seller.UserId)
				end
			end
		else
			warn("FAILED GET ID", stringify(val))
		end
		--end	
	end
end

getfenv(0)._F = _F
getfenv(0)._L = _L


game.ReplicatedStorage.Network.Booths_Broadcast.OnClientEvent:Connect(function(player, data)
	if data and type(data) == "table" and data.Listings ~= nil then
		if player ~= game.Players.LocalPlayer then
			ProcessBroadcast(player, data.Listings)
		end
	end
end)




local ParseData = function(Data)
	local ParsedData = ""

	for i, v in next, Data do
		if type(v) == "table" then
			ParsedData = ParsedData .. stringify(v)
		elseif type(v) == "string" then
			ParsedData = ParsedData .. "\"" .. v .. "\""
		elseif typeof(v) == "Instance" then
			ParsedData = ParsedData .. InstanceToString(v)
		else
			ParsedData = ParsedData .. tostring(v)
		end

		if i ~= #Data then
			ParsedData = ParsedData .. ", "
		end
	end

	return ParsedData
end

if not getfenv().NetworkHook or true then
	getfenv().NetworkHook = true;

	local OldNetwork = _L.Network

	_L.Network = setmetatable({}, {
		__index = function(self, method)
			return function(...)
				local Args = {...}

				if Settings.NetworkDebug and (not table.find(Settings.blacklistedRemotes, Args[1])) then
					local BeautifiedArgs = ParseData(Args)

					print(
						string.format(
							"_L.Network.%s(%s)",
							method,
							BeautifiedArgs
						)
					)
				end

				return OldNetwork[method](...)
			end
		end
	})

	local OldSignal = _L.Signal

	_L.Signal = setmetatable({}, {
		__index = function(self, method)
			return function(...)
				local Args = {...}

				if Settings.SignalDebug and (not table.find(Settings.blacklistedEvents, Args[1])) then
					local BeautifiedArgs = ParseData(Args)

					print(
						string.format(
							"_L.Signal.%s(%s)",
							method,
							BeautifiedArgs
						)
					)
				end

				return OldSignal[method](...)
			end
		end
	})
end



