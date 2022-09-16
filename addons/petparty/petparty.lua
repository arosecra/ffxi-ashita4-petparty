
addon.name      = 'petparty';
addon.author    = 'arosecra';
addon.version   = '1.0';
addon.desc      = 'Displays the health of all pets in the current party';
addon.link      = 'https://github.com/arosecra/ffxi-ashita4-petparty';

local imgui = require('imgui');
local common = require('common');
local libs2imgui = require('org_github_arosecra/imgui');
local libs2config = require('org_github_arosecra/config');
local mechanics = require('org_github_arosecra/mechanics');
local char_jobs_extra = require('org_github_arosecra/packets/char_jobs_extra')

local petparty_window = {
    is_open                 = { true }
};

local runtime_config = {
	next_notification_tic_time = 0,
	show = false
}

ashita.events.register('load', 'petparty_load_cb', function ()
    print("[petparty] 'load' event was called.");
end);


ashita.events.register('packet_in', 'gambits_in_callback1', function (e)
    if (e.id == 0x44) then
		local pkt = char_jobs_extra.parse(e.data)
		local att = ''
		if pkt.auto.name ~= nil then
			for i = 1, 12 do
				att = att .. ' ' .. pkt.auto.slots[i]
			end
			-- print(att)
		end
		--runtime_config.party_status_effects = status_effect_packet.parse(e.data)
		--print('parsed 0x76')
    end
	
end);

ashita.events.register('command', 'petparty_command_cb', function (e)
    if (not e.command:startswith('/petparty') and not e.command:startswith('/pp')) then
		return;
    end
    local args = e.command:argsquoted();

	if args[2] == 'show' then
		runtime_config.show = true
	end
		
	if args[2] == 'petstats' then
		local petStats = {
			pet = true
		}
		petStats.master = args[3]
		if args[4] == 'nopet' then
			petStats.pet = false
		else
			petStats.name = args[4]
			petStats.hp = tonumber(args[5])
			petStats.mp = tonumber(args[6])
			petStats.tp = tonumber(args[7])
		end
		runtime_config[petStats.master] = petStats

	end
	
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

	if runtime_config.next_notification_tic_time < os.time() then

		local petStats = {
			pet = false,
			master = party:GetMemberName(0)
		}
		local player = GetPlayerEntity();
		if (player ~= nil) then
			local pet = GetEntity(player.PetTargetIndex);
			if (pet ~= nil and pet.Name ~= nil) then
				petStats.pet = true
				petStats.name = pet.Name
				petStats.hp = pet.HPPercent;
				petStats.mp = AshitaCore:GetMemoryManager():GetPlayer():GetPetMPPercent();
				petStats.tp = AshitaCore:GetMemoryManager():GetPlayer():GetPetTP()
			end
		end
		
		if petStats.pet then
			AshitaCore:GetChatManager():QueueCommand(1, "/ms send /petparty petstats " 
				.. petStats.master .. ' '
				.. petStats.name .. ' '
				.. petStats.hp .. ' ' 
				.. petStats.mp .. ' ' 
				.. petStats.tp)

		else
			AshitaCore:GetChatManager():QueueCommand(1, "/ms send /petparty petstats " .. petStats.master .. ' nopet')
		end
		
		runtime_config.next_notification_tic_time = os.time() + 3
	end

	--every 3 seconds, send pet information via multisend


	if runtime_config.show then
		local windowStyleFlags = libs2imgui.gui_style_table_to_var("imguistyle", addon.name, "window.style");
		local tableStyleFlags = libs2imgui.gui_style_table_to_var("imguistyle", addon.name, "table.style");
		libs2imgui.imgui_set_window(addon.name);
		if imgui.Begin(addon.name, petparty_window.is_open, windowStyleFlags) then
			if imgui.BeginTable('t6', 5, tableStyleFlags, 0, 0) then

				for i = 0, 5 do
					local name = party:GetMemberName(i);
					local entityId = party:GetMemberTargetIndex(i);
					local mainjob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", party:GetMemberMainJob(i));

					if runtime_config[name] then
						local petStats = runtime_config[name]
						imgui.TableNextColumn();
						imgui.Text(name);

						--pet name
						imgui.TableNextColumn();
						if petStats.pet then
							imgui.Text(petStats.name);
						else
							imgui.Text("None");
						end
						imgui.TableNextColumn();

						--pet hp
						if petStats.pet then
							local percentage = petStats.hp / 100
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
							imgui.ProgressBar(percentage, { -1.0, 0.0 });
							imgui.PopStyleColor();
						else
							imgui.ProgressBar(0, { -1.0, 0.0 });
						end
							-- imgui.Text("None");
						imgui.TableNextColumn();

						--pet mp
						if petStats.pet then
							local percentage = petStats.mp / 100
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
							imgui.ProgressBar(percentage, { -1.0, 0.0 });
							imgui.PopStyleColor();
						else
							imgui.ProgressBar(0, { -1.0, 0.0 });
						end
							-- imgui.Text("None");
						imgui.TableNextColumn();

						--pet tp
						if petStats.pet then
							imgui.Text(tostring(petStats.tp));
						else
							imgui.Text("0");
						end

						imgui.TableNextRow(0, 0);
					end
				end

				imgui.EndTable();
			end

		end
		imgui.End();
	end
end);