
addon.name      = 'petparty';
addon.author    = 'arosecra';
addon.version   = '1.0';
addon.desc      = 'Displays the health of all pets in the current party';
addon.link      = 'https://github.com/arosecra/ffxi-ashita4-petparty';

local imgui = require('imgui');
local common = require('common');
local jobs = require('org_github_arosecra/jobs');
local libs2imgui = require('org_github_arosecra/imgui');
local libs2config = require('org_github_arosecra/config');
local mechanics = require('org_github_arosecra/mechanics');

local petparty_window = {
    is_open                 = { true }
};

ashita.events.register('load', 'petparty_load_cb', function ()
    print("[petparty] 'load' event was called.");
end);

ashita.events.register('command', 'petparty_command_cb', function (e)
    if (not e.command:startswith('/petparty') and not e.command:startswith('/pp')) then
		return;
    end
    print("[petparty] Blocking '/pp' command!");
    e.blocked = true;
end);

ashita.events.register('plugin_event', 'petparty_plugin_event_cb', function (e)
    if (not e.name:startswith('/petparty') and not e.name:startswith('/pp')) then
		return;
    end
    print("[petparty] Blocking '/pp' command!");
    e.blocked = true;
end);

local once = false

ashita.events.register('d3d_present', 'petparty_present_cb', function ()

    local memoryManager = AshitaCore:GetMemoryManager();
	local party = memoryManager:GetParty();
	
	local pet_job_count = 0;
	for i=0,5 do
		local mainjob = jobs[party:GetMemberMainJob(i)]
		if mainjob == "Beastmaster" or
		   mainjob == "Puppetmaster" or
		   mainjob == "Summoner" or
		   mainjob == "Geomancer" or 
		   mainjob == "Dragoon" then
		   pet_job_count = pet_job_count + 1;
		end
	end
	
	if pet_job_count > 0 then
		local windowStyleFlags = libs2imgui.gui_style_table_to_var("imguistyle", addon.name, "window.style");
		local tableStyleFlags = libs2imgui.gui_style_table_to_var("imguistyle", addon.name, "table.style");
		libs2imgui.imgui_set_window(addon.name);
		if imgui.Begin(addon.name, petparty_window.is_open, windowStyleFlags) then
			if imgui.BeginTable('t2', 3, tableStyleFlags, 0, 0) then

				for i=0,5 do
					local name = party:GetMemberName(i);
					local entityId = party:GetMemberTargetIndex(i);
					local mainjob = jobs[party:GetMemberMainJob(i)];
					
					if mainjob == "Beastmaster" or
					   mainjob == "Puppetmaster" or
					   mainjob == "Summoner" or
					   mainjob == "Geomancer" or 
					   mainjob == "Dragoon" then
						imgui.TableNextColumn();
						imgui.Text(name);
						imgui.TableNextColumn();
						
						if entityId ~= 0 then
							local entity = GetEntity(entityId);
							if entity ~= nil then
								local petTargetIndex = entity.PetTargetIndex;
								if petTargetIndex ~= 0 then
									local petEntity = GetEntity(petTargetIndex);
									if petEntity ~= nil then
										imgui.Text(petEntity.Name);
										imgui.TableNextColumn();
										local percentage = petEntity.HPPercent / 100
										local color = libs2imgui.get_color('health', mechanics.health_percent_to_status(percentage));
										if not once then
											--print(color)
											--print(color.x)
											--print(color.y)
											--print(color.w)
											--print(color.z)
											once = true
										end
										
										imgui.PushStyleColor(ImGuiCol_PlotHistogram, color);
										imgui.ProgressBar(percentage, {-1.0, 0.0});
										imgui.PopStyleColor();
									end
								else
									imgui.Text("None");
									imgui.TableNextColumn();
									imgui.ProgressBar(0, {-1.0, 0.0});
								end
							end
						end
						imgui.TableNextRow(0,0);
					end
				end
			
				imgui.EndTable();
			end
			
		end
		imgui.End();
	end
end);