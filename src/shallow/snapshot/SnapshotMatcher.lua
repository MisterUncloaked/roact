local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoactRoot = script.Parent.Parent.Parent

local Markers = require(script.Parent.Serialize.Markers)
local Serialize = require(script.Parent.Serialize)
local deepEqual = require(RoactRoot.deepEqual)
local ElementKind = require(RoactRoot.ElementKind)

local SnapshotFolderName = "RoactSnapshots"
local SnapshotFolder = ReplicatedStorage:FindFirstChild(SnapshotFolderName)

local SnapshotMatcher = {}
local SnapshotMetatable = {
	__index = SnapshotMatcher,
}

function SnapshotMatcher.new(identifier, snapshot)
	local snapshotMatcher = {
		_identifier = identifier,
		_snapshot = snapshot,
		_existingSnapshot = SnapshotMatcher._loadExistingData(identifier),
	}

	setmetatable(snapshotMatcher, SnapshotMetatable)

	return snapshotMatcher
end

function SnapshotMatcher:match()
	if self._existingSnapshot == nil then
		self:serialize()
		self._existingSnapshot = self._snapshot
		return
	end

	local areEqual, innerMessageTemplate = deepEqual(self._snapshot, self._existingSnapshot)

	if areEqual then
		return
	end

	local newSnapshot = SnapshotMatcher.new(self._identifier .. ".NEW", self._snapshot)
	newSnapshot:serialize()

	local innerMessage = innerMessageTemplate
		:gsub("{1}", "new")
		:gsub("{2}", "existing")

	local message = ("Snapshots do not match.\n%s"):format(innerMessage)

	error(message, 2)
end

function SnapshotMatcher:getSnapshotString()
	return Serialize.snapshotToString(self._snapshot)
end

function SnapshotMatcher:serialize()
	local folder = SnapshotMatcher.getSnapshotFolder()

	local snapshotSource = self:getSnapshotString()
	local existingData = folder:FindFirstChild(self._identifier)

	if not (existingData and existingData:IsA('StringValue')) then
		existingData = Instance.new("StringValue")
		existingData.Name = self._identifier
		existingData.Parent = folder
	end

	existingData.Value = snapshotSource
end

function SnapshotMatcher.getSnapshotFolder()
	SnapshotFolder = ReplicatedStorage:FindFirstChild(SnapshotFolderName)

	if not SnapshotFolder then
		SnapshotFolder = Instance.new("Folder")
		SnapshotFolder.Name = SnapshotFolderName
		SnapshotFolder.Parent = ReplicatedStorage
	end

	return SnapshotFolder
end

function SnapshotMatcher._loadExistingData(identifier)
	local folder = SnapshotMatcher.getSnapshotFolder()

	local existingData = folder:FindFirstChild(identifier)

	if not (existingData and existingData:IsA("ModuleScript")) then
		return nil
	end

	local loadSnapshot = require(existingData)

	return loadSnapshot({
		Roact = require(script.Parent.Parent),
		ElementKind = ElementKind,
		Markers = Markers,
	})
end

return SnapshotMatcher