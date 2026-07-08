local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {},
	}, Maid)
end

function Maid:Give(taskItem)
	table.insert(self._tasks, taskItem)
	return taskItem
end

function Maid:Clean()
	for _, taskItem in ipairs(self._tasks) do
		if typeof(taskItem) == "RBXScriptConnection" then
			taskItem:Disconnect()
		elseif type(taskItem) == "function" then
			taskItem()
		elseif typeof(taskItem) == "Instance" then
			taskItem:Destroy()
		elseif type(taskItem) == "table" and taskItem.Destroy then
			taskItem:Destroy()
		end
	end
	table.clear(self._tasks)
end

function Maid:Destroy()
	self:Clean()
end

return Maid
