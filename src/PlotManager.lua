local PlotManager = {}

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Plots = game.Workspace.Plots

local assets = ServerStorage.assets
local brainrots = assets.brainrots

local main = ServerStorage.main
local src = main.src
local classes = main.classes

local events = ServerStorage.events

-- Dependencies 

local DataManager = require(src.DataManager)
-- local BrainrotManager = require(src.BrainrotManager)

-- Classes

local PlotClass = require(classes.PlotClass)

-- Events

local setData = events.SetData

PlotManager.PlotClasses = {
	--[[
	Example:
	["Arquimecs"] = PlotClass.new()
	]]
}

PlotManager.PlotOwners = {
	[1] = "None",
	[2] = "None",
	[3] = "None",
	[4] = "None",
	[5] = "None",
}

function PlotManager.SetPlotOwner(Player: Player)
	
	local playerData = DataManager.getData(Player)
	print(playerData)
	local playerBrainrots = playerData.Brainrots
	
	local playerPlot = "None"
	
	for PlotNumber, PlotOwner in PlotManager.PlotOwners do
		
		if PlotOwner == "None" then
			
			PlotManager.PlotOwners[PlotNumber] = Player.Name
			playerPlot = Plots[PlotNumber]
			
			break
		end
	end
	
	PlotManager.PlotClasses[Player.Name] = PlotClass.new(Player, playerData, playerPlot)
	PlotManager.PlotClasses[Player.Name]:Initialize()
	
	print("Finished loading player plot! Player: "..Player.Name)
end

function PlotManager.PlayerLeaving(Player: Player)
	
	print(PlotManager.PlotClasses)
	PlotManager.PlotClasses[Player.Name]:Clean()
end

Players.PlayerRemoving:Connect(PlotManager.PlayerLeaving)

return PlotManager
