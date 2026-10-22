---@meta _
---@diagnostic disable: lowercase-global

local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

_PLUGIN = _PLUGIN
game = rom.game
import_as_fallback(game)
modutil = mods['SGG_Modding-ModUtil']
sjson = mods['SGG_Modding-SJSON']

local package = rom.path.combine(_PLUGIN.plugins_data_mod_folder_path, _PLUGIN.guid)
local replacement_paths = import 'portrait_paths.lua'

local file_path_replacements = {}
for _, path in ipairs(replacement_paths) do
	file_path_replacements[path] = _PLUGIN.guid .. "\\" .. path
end

local function normalize_portrait_path(path)
	if path == nil then
		return nil
	end
	local start_index = string.find(path, "Portraits\\")
	if start_index ~= nil then
		return string.sub(path, start_index)
	end
	return path
end

local function patch_portrait_file_paths(data)
	if data == nil or data.Animations == nil then
		return data
	end

	local count = 0
	for _, animation in ipairs(data.Animations) do
		local replacement = file_path_replacements[normalize_portrait_path(animation.FilePath)]
		if replacement ~= nil then
			animation.FilePath = replacement
			count = count + 1
		end
	end

	print("[" .. _PLUGIN.guid .. "] Patched portrait FilePath entries: " .. tostring(count))
	return data
end

local function hook_portrait_sjson()
	local files = {
		"Game/Animations/GUI_Portraits_VFX.sjson",
		"Game/Animations/GUI_Screens_VFX.sjson",
	}

	for _, file in ipairs(files) do
		local path = rom.path.combine(rom.paths.Content, file)
		sjson.hook(path, patch_portrait_file_paths)
	end
	print("[" .. _PLUGIN.guid .. "] Registered portrait SJSON hooks")
end

local function on_ready()
	hook_portrait_sjson()

	local wrapper = nil
	if modutil.mod ~= nil and modutil.mod.Path ~= nil then
		wrapper = modutil.mod.Path.Wrap
	elseif ModUtil ~= nil and ModUtil.Path ~= nil then
		wrapper = ModUtil.Path.Wrap
	elseif modutil.Path ~= nil then
		wrapper = modutil.Path.Wrap
	end

	if wrapper == nil then
		print("[" .. _PLUGIN.guid .. "] ModUtil Path.Wrap is unavailable")
		return
	end

	wrapper("SetupMap", function(base)
		print("[" .. _PLUGIN.guid .. "] Loading package: " .. package)
		LoadPackages({ Name = package })
		base()
	end)
end

if modutil.once_loaded ~= nil and modutil.once_loaded.game ~= nil then
	modutil.once_loaded.game(on_ready)
else
	on_ready()
end
