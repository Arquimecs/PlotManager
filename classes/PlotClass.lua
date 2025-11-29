local PlotClass = {}
PlotClass.__index = PlotClass

local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClientAssets = ReplicatedStorage.Assets
local sound = ClientAssets.Sound

local assets = ServerStorage.assets
local events = ServerStorage.events

local SetData = events.SetData

local brainrots = assets.brainrots

function PlotClass.new(Player: Player, Data, playerPlot)
	
	local self = setmetatable({}, PlotClass)
	
	self.Slots = {}
	self.Owner = Player.Name
	self.PlayerData = Data
	self.PlayerBrainrots = Data.Brainrots
	self.PlayerPlot = playerPlot
	self.Connections = {}
	self.DebounceTimer = 1
	self.Debouncing = false
	self.Debounces = {}
	
	for i = 1, Data.SlotCount, 1 do
		for Index, Brainrot in Data.Brainrots do
			if Brainrot.Slot == i then
				self.Slots[i] = {
					CollectableCash = Data.Brainrots[i].CollectableCash,
					CPS = Data.Brainrots[i].CPS
				}
			else
				continue
			end
		end
	end
	
	return self
end

function PlotClass:AssignToSlot(playerPlot, Properties)
	
	local BrainrotModel = brainrots[Properties.Type][Properties.Name]
	local SlotNumber = Properties.Slot
	local Slots = self.PlayerPlot.Slots
	local Slot = Slots[SlotNumber]
	local PlacementPart = Slot.Place
	
	local newModel = BrainrotModel:Clone()
	newModel.Name = Properties.ID
	newModel.Parent = Slot
	
	newModel.Position = PlacementPart.Position
	newModel.Orientation.Y = PlacementPart.Orientation.Y + 180
	
	self:SetUpConnection()
	
end

function PlotClass:RemoveAssignment(playerPlot, Properties)
	
	local SlotNumber = Properties.Slot
	local Slots = self.PlayerPlot.Slots
	local Slot = Slots[SlotNumber]
	local PlacementPart = Slot.Place
	local BrainrotModel = Slot[Properties.Name]
	
	BrainrotModel:Destroy()
	
end

function PlotClass:UpdateCash(playerPlot, Properties)
	
	local SlotNumber = Properties.Slot
	local Slots = self.PlayerPlot.Slots
	local Slot = Slots[SlotNumber]
	local ClaimPart = Slot.Claim
	local TouchPart = ClaimPart.Touch
	local BillboardGUI = ClaimPart.BillboardGui
	local CashLabel = BillboardGUI.CashDisplay
	local BrainrotModel = Slot[Properties.Name]
	
	local CashBoosts = 0 -- set as 0 for now, need to code this later
	
	self.Slots[tonumber(Slot.Name)].CollectableCash += self.Slots[tonumber(Slot.Name)].CPS * ((1 + CashBoosts/100) * (self.PlayerData.Rebirths + 1))
	CashLabel.Text = "$"..self.Slots[tonumber(Slot.Name)].CollectableCash
	
end

function PlotClass:SetUpConnections(Properties)
	
	local Slots = self.PlayerPlot.Slots

	for Index, Connection in self.Connections do
		if Index == "MainLoop" then
			continue
		else
			Connection:Disconnect()
			self.Connections[Index] = nil
		end
	end

	for Index, Slot in Slots do
		
		local ClaimPart = Slot.Claim
		local TouchPart = ClaimPart.Touch
		local BillboardGUI = ClaimPart.BillboardGui
		local CashLabel = BillboardGUI.CashDisplay
		
		self.Debounces[Index] = false
		
		print("setting up connection")
		self.Connections["Touched_"..Index] = TouchPart.Touched:Connect(function(Hit)
			
			print("touched")
			local Character = Hit.Parent
			local Player = Players[Character.Name]
			
			if Player.Name ~= self.Owner then return end
			
			if self.Debounces[Index] then return end
			self.Debounces[Index] = true
			
			local Info = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.In, 0, true, 0)
			local Tween = TweenService:Create(TouchPart, Info, { Position = TouchPart.Position - Vector3.new(0, 1, 0) })
			Tween:Play()
			
			TouchPart.Color = Color3.fromRGB(91, 93, 105)
			
			SetData:Fire(Players[self.Owner], "Cash", self.Data.Cash + self.Slots[tonumber(Slot.Name)].CollectableCash)
			self.Slots[tonumber(Slot.Name)].CollectableCash = 0
			
			task.wait(1)
			
			self.Debounces[Index] = false
			TouchPart.Color = Color3.fromRGB(74, 255, 42)

		end)
		
	end
	print(self.Connections)
end

function PlotClass:Initialize()
	
	print("init", self)
	
	for Brainrot, Properties in self.PlayerBrainrots do -- Brainrot being the name / brainrot, NOT AN ENTITY, and properties being the values
		print(self)
		self:AssignToSlot(Brainrot, Properties)
		print("assigned")
	end

	-- once we're done loading the brainrots, start the money making and collection process
	
	for Brainrot, Properties in self.PlayerBrainrots do -- Brainrot being the name / brainrot, NOT AN ENTITY, and properties being the values
		print("setting up connections")
		self:SetUpConnections(Properties)

	end
	
	print(self.PlayerPlot)
	print(self.PlayerPlot:GetChildren())
	
	local FirstFloor = self.PlayerPlot.FirstFloor
	local Sign = FirstFloor.Sign
	local SignPart = Sign.Part
	local SurfaceGui = SignPart.SurfaceGui
	local SignLabel = SurfaceGui.TextLabel
	
	SignLabel.Text = "@"..self.Owner
	
	self.Connections["MainLoop"] = RunService.Heartbeat:Connect(function()
		
		if self.Debouncing then return end
		self.Debouncing = true
		
		for Brainrot, Properties in self.PlayerBrainrots do -- Brainrot being the name / brainrot, NOT AN ENTITY, and properties being the values

			self:UpdateCash(Brainrot, Properties)

		end
		
		task.wait(self.Debounce)
		self.Debouncing = false
	end)
	
	
	
end

function PlotClass:Clean()
	
	for Brainrot, Properties in self.PlayerBrainrots do -- Brainrot being the name / brainrot, NOT AN ENTITY, and properties being the values

		self:RemoveAssignment(Brainrot, Properties)

	end
	
	for Index, Connection in self.Connections do
		Connection:Disconnect()
		self.Connections[Index] = nil
	end
	
	local FirstFloor = self.PlayerPlot.FirstFloor
	local Sign = FirstFloor.Sign
	local SignPart = Sign.Part
	local SurfaceGui = SignPart.SurfaceGui
	local SignLabel = SurfaceGui.TextLabel

	SignLabel.Text = "Empty Base"
	
	self.Connections = {}
	self.Slots = {}
	self.Owner = "None"
	
end

return PlotClass
