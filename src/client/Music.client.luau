--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.SoundId = "rbxassetid://" .. Config.Music.Id
music.Volume = Config.Music.Volume
music.Looped = true
music.Parent = SoundService
music:Play()
