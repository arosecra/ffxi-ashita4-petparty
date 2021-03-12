

local imgui = require('imgui');
local common = require('common');

local helper = {};


helper.get_string_table = function(alias, section, key)
	local result = T{}
	local configManager = AshitaCore:GetConfigurationManager();
	local size = configManager:GetUInt16(alias, section, key .. ".size", 0);
	if size ~= 0 then
		for i=1,size do
			local s = configManager:GetString(alias, section, key .. "[" .. i .. "]")
			result = result:append(s)
		end
	else
		local s = configManager:GetString(alias, section, key)
		if s ~= nil then
			s = s:slice(2, #s-1);
			local parts = s:split(",", 0, false)
			for i,k in pairs(parts) do
				if k ~= nil then
					local trimmed = string.trim(k)
					result[i]=trimmed
				else
					result[i] = k
				end
			end
		end
	end
	return result
end

helper.gui_style_table_to_var = function(alias, section, key)
	local t = helper.get_string_table(alias, section, key)
	local result = 0
	t:each(function(v, i)
		if _G[v] ~= nil then
			result = bit.bor(result, _G[v]);
		end
	end);

	return result;
end

helper.imgui_set_window = function(section)
	local window_position_x = AshitaCore:GetConfigurationManager():GetFloat("imguistyle", section, "window.position.x", 0);
	local window_position_y = AshitaCore:GetConfigurationManager():GetFloat("imguistyle", section, "window.position.y", 0);
	local window_position_style = helper.gui_style_table_to_var("imguistyle", section, "window.position.style");
	if window_position_x ~= 0 or window_position_y ~= 0 then
		imgui.SetNextWindowPos({ window_position_x, window_position_y }, window_position_style);
	end
	
	local window_size_height = AshitaCore:GetConfigurationManager():GetFloat("imguistyle", section, "window.size.height", 0);
	local window_size_width = AshitaCore:GetConfigurationManager():GetFloat("imguistyle", section, "window.size.width", 0);
	local window_size_style = helper.gui_style_table_to_var("imguistyle", section, "window.size.style");
	if window_size_height ~= 0 or window_size_width ~= 0 then
		imgui.SetNextWindowSize({ window_size_width, window_size_height }, window_size_style);
	end

end


return helper;