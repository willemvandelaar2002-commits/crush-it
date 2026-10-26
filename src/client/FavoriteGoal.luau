--!strict
-- One owner-local Roblox prompt. No optimistic success on click/cancel/error.
-- Completion reports remain client assertions (see docs/Systems/Goals reward).
local F={}
F.__index=F
function F.new(api)
	local self=setmetatable({api=api,busy=false,generation=0,confirmed=false},F)
	self.connection=api.service.PromptSetFavoriteCompleted:Connect(function(result)
		if not self.promptToken then return end
		local token=self.promptToken self.promptToken=nil
		self:_finish(token,result==api.success)
	end)
	return self
end
function F:_finish(token,success)
	if self.destroyed then return end
	self.busy=false self.waiting=false self.generation+=1
	if success then
		self.api.act("FavoriteConfirmed",{token=token})
	else self.api.notice("Favorite wasn't confirmed. Press FAVORITE to try again.") end
end
function F:request()
	if self.destroyed or self.busy then return end
	if self.confirmed then self.api.notice("Favorite goal complete!") return end
	self.busy=true self.waiting=true self.generation+=1
	local generation=self.generation
	self.api.act("FavoriteStart")
	self.api.later(12,function()
		if not self.destroyed and self.generation==generation and self.waiting then
			self.waiting=false self.busy=false self.generation+=1
			self.api.notice("Couldn't start the favorite check. Please try again.")
		end
	end)
end
function F:update(goals)
	if self.destroyed or type(goals)~="table" then return end
	self.confirmed=goals.favorite==true
	if self.confirmed then
		self.busy=false self.waiting=false self.promptToken=nil self.generation+=1 return
	end
	if not self.waiting or type(goals.favoriteToken)~="string" then return end
	self.waiting=false
	local token=goals.favoriteToken local generation=self.generation
	self.api.spawn(function()
		-- Existing favorites can complete without asking the player to undo them.
		-- No inventory-permission prompt: if the read is unavailable, use the
		-- ordinary Roblox favorite prompt instead and wait for its real result.
		local ok,favorite=pcall(function() return self.api.service:GetFavoriteAsync(self.api.placeId,self.api.itemType) end)
		if self.destroyed or self.generation~=generation then return end
		if ok and favorite==true then self:_finish(token,true) return end
		self.promptToken=token
		local prompted=pcall(function() self.api.service:PromptSetFavorite(self.api.placeId,self.api.itemType,true) end)
		if not prompted and self.promptToken==token then self.promptToken=nil self:_finish(token,false) end
	end)
	self.api.later(110,function()
		if not self.destroyed and self.generation==generation then
			self.promptToken=nil self.busy=false self.waiting=false self.generation+=1
			self.api.notice("Favorite check timed out. Close the Roblox prompt and try again.")
		end
	end)
end
function F:Destroy()
	if self.destroyed then return end
	self.destroyed=true self.generation+=1 self.promptToken=nil self.busy=false
	self.connection:Disconnect()
end
return F
