require("util")

-- Forward declarations
local machines
local exponent
local max_level = 1
local required_items_for_levels = {}
local current_tick_interval = 6  -- Track current interval for proper cleanup

script.on_init(function()
	storage.stored_products_finished_assemblers = { }
	storage.stored_products_finished_furnaces = { }
	-- Initialize settings-dependent variables
	init_settings_variables()
	get_built_machines()
	setup_tick_handler()
end)

script.on_configuration_changed(function()
	-- Refresh settings-dependent variables after configuration change
	init_settings_variables()
	get_built_machines()
	setup_tick_handler()
end)

script.on_load(function()
	-- Re-setup tick handler on load
	if storage.built_machines then
		setup_tick_handler()
	end
end)

function init_settings_variables()
	-- Initialize all settings-dependent variables here where settings are available
	machines = get_machines_table()
	exponent = settings.global["factory-levels-exponent"].value
	update_machine_levels(true)
end

function get_built_machines()
	storage.built_machines = storage.built_machines or {}
	for unit_number, machine in pairs(storage.built_machines) do
		-- Remove invalid machines from the storage table.
		if not machine.entity or not machine.entity.valid then
			storage.built_machines[unit_number] = nil
		end
	end
	local built_assemblers = {}
	for _, surface in pairs(game.surfaces) do
		local assemblers = surface.find_entities_filtered { type = { "assembling-machine", "furnace" } }
		for _, machine in pairs(assemblers) do
			if not storage.built_machines[machine.unit_number] then
				storage.built_machines[machine.unit_number] = { entity = machine, unit_number = machine.unit_number }
			end
			table.insert(built_assemblers, machine)
		end
	end
	replace_machines(built_assemblers)
end

function string_starts_with(str, start)
	return str:sub(1, #start) == start
end

function get_machine_max_level(machine_name)
	-- Determine machine tier and return appropriate max level from settings
	local tier_1_machines = {
		["assembling-machine-1"] = true,
		["stone-furnace"] = true,
		["electric-stone-furnace"] = true,
		["burner-ore-crusher"] = true,
		["ore-crusher"] = true,
		["liquifier"] = true,
		["liquifier-2"] = true,
		["angels-electrolyser"] = true,
		["angels-electrolyser-2"] = true,
		["angels-electrolyser-3"] = true,
		["algae-farm"] = true,
		["algae-farm-2"] = true,
		["algae-farm-3"] = true,
		["crusher1"] = true,
		["echamber1"] = true,
		["omnitractor-1"] = true
	}
	
	local tier_2_machines = {
		["assembling-machine-2"] = true,
		["ore-crusher-2"] = true,
		["liquifier-3"] = true,
		["crystallizer"] = true,
		["electric-furnace-2"] = true,
		["crusher2"] = true,
		["echamber2"] = true,
		["pchamber1"] = true
	}
	
	if tier_1_machines[machine_name] then
		return settings.startup["factory-levels-max-level-tier-1"].value
	elseif tier_2_machines[machine_name] then
		return settings.startup["factory-levels-max-level-tier-2"].value
	else
		return settings.startup["factory-levels-max-level-tier-3"].value
	end
end

function get_machines_table()
	local machines_table = {}
	
	-- Only add assembler machines if assembler leveling is enabled
	if settings.startup["factory-levels-enable-assembler-leveling"].value then
		machines_table["assembling-machine-1"] = {
			name = "assembling-machine-1",
			level_name = "assembling-machine-1-level-",
			max_level = get_machine_max_level("assembling-machine-1"),
			next_machine = "assembling-machine-2"
		}
		machines_table["assembling-machine-2"] = {
			name = "assembling-machine-2",
			level_name = "assembling-machine-2-level-",
			max_level = get_machine_max_level("assembling-machine-2"),
			next_machine = "assembling-machine-3"
		}
		machines_table["assembling-machine-3"] = {
			name = "assembling-machine-3",
			level_name = "assembling-machine-3-level-",
			max_level = get_machine_max_level("assembling-machine-3")
		}
		machines_table["electromagnetic-plant"] = {
			name = "electromagnetic-plant",
			level_name = "electromagnetic-plant-level-",
			max_level = get_machine_max_level("electromagnetic-plant")
		}
		machines_table["biochamber"] = {
			name = "biochamber",
			level_name = "biochamber-level-",
			max_level = get_machine_max_level("biochamber")
		}
	end
	
	-- Only add furnace machines if furnace leveling is enabled
	if settings.startup["factory-levels-enable-furnace-leveling"].value then
		machines_table["stone-furnace"] = {
			name = "stone-furnace",
			level_name = "stone-furnace-level-",
			max_level = get_machine_max_level("stone-furnace"),
			next_machine = "steel-furnace"
		}
		machines_table["steel-furnace"] = {
			name = "steel-furnace",
			level_name = "steel-furnace-level-",
			max_level = get_machine_max_level("steel-furnace")
		}
		machines_table["electric-furnace"] = {
			name = "electric-furnace",
			level_name = "electric-furnace-level-",
			max_level = get_machine_max_level("electric-furnace")
		}
		
		-- Electric Furnaces
		machines_table["electric-stone-furnace"] = {
			name = "electric-stone-furnace",
			level_name = "electric-stone-furnace-level-",
			max_level = get_machine_max_level("electric-stone-furnace"),
			next_machine = "electric-steel-furnace"
		}
		machines_table["electric-steel-furnace"] = {
			name = "electric-steel-furnace",
			level_name = "electric-steel-furnace-level-",
			max_level = get_machine_max_level("electric-steel-furnace")
		}
		machines_table["electric-furnace-2"] = {
			name = "electric-furnace-2",
			level_name = "electric-furnace-2-level-",
			max_level = get_machine_max_level("electric-furnace-2"),
			next_machine = "electric-furnace-3"
		}
		machines_table["electric-furnace-3"] = {
			name = "electric-furnace-3",
			level_name = "electric-furnace-3-level-",
			max_level = get_machine_max_level("electric-furnace-3")
		}
	end
	
	-- Only add refinery machines if refinery leveling is enabled
	if settings.startup["factory-levels-enable-refinery-leveling"].value then
		machines_table["chemical-plant"] = {
			name = "chemical-plant",
			level_name = "chemical-plant-level-",
			max_level = get_machine_max_level("chemical-plant")
		}
		machines_table["oil-refinery"] = {
			name = "oil-refinery",
			level_name = "oil-refinery-level-",
			max_level = get_machine_max_level("oil-refinery")
		}
		machines_table["centrifuge"] = {
			name = "centrifuge",
			level_name = "centrifuge-level-",
			max_level = get_machine_max_level("centrifuge")
		}
	end
	
	-- Omnimatter machines
	machines_table["burner-omnitractor"] = {
		name = "burner-omnitractor",
		level_name = "burner-omnitractor-level-",
		max_level = 10  -- Special case - keep original value
	}
	machines_table["omnitractor-1"] = {
		name = "omnitractor-1",
		level_name = "omnitractor-1-level-",
		max_level = get_machine_max_level("omnitractor-1")
	}
	
	-- Angels Refining machines
	machines_table["burner-ore-crusher"] = {
		name = "burner-ore-crusher",
		level_name = "burner-ore-crusher-level-",
		max_level = get_machine_max_level("burner-ore-crusher"),
		next_machine = "ore-crusher"
	}
	machines_table["ore-crusher"] = {
		name = "ore-crusher",
		level_name = "ore-crusher-level-",
		max_level = get_machine_max_level("ore-crusher"),
		next_machine = "ore-crusher-2"
	}
	machines_table["ore-crusher-2"] = {
		name = "ore-crusher-2",
		level_name = "ore-crusher-2-level-",
		max_level = get_machine_max_level("ore-crusher-2"),
		next_machine = "ore-crusher-3"
	}
	machines_table["ore-crusher-3"] = {
		name = "ore-crusher-3",
		level_name = "ore-crusher-3-level-",
		max_level = get_machine_max_level("ore-crusher-3")
	}
	machines_table["liquifier"] = {
		name = "liquifier",
		level_name = "liquifier-level-",
		max_level = get_machine_max_level("liquifier"),
		next_machine = "liquifier-2"
	}
	machines_table["liquifier-2"] = {
		name = "liquifier-2",
		level_name = "liquifier-2-level-",
		max_level = get_machine_max_level("liquifier-2"),
		next_machine = "liquifier-3"
	}
	machines_table["liquifier-3"] = {
		name = "liquifier-3",
		level_name = "liquifier-3-level-",
		max_level = get_machine_max_level("liquifier-3"),
		next_machine = "liquifier-4"
	}
	machines_table["liquifier-4"] = {
		name = "liquifier-4",
		level_name = "liquifier-4-level-",
		max_level = get_machine_max_level("liquifier-4")
	}
	machines_table["crystallizer"] = {
		name = "crystallizer",
		level_name = "crystallizer-level-",
		max_level = get_machine_max_level("crystallizer"),
		next_machine = "crystallizer-2"
	}
	machines_table["crystallizer-2"] = {
		name = "crystallizer-2",
		level_name = "crystallizer-2-level-",
		max_level = get_machine_max_level("crystallizer-2")
	}
	machines_table["angels-electrolyser"] = {
		name = "angels-electrolyser",
		level_name = "angels-electrolyser-level-",
		max_level = get_machine_max_level("angels-electrolyser")
	}
	machines_table["angels-electrolyser-2"] = {
		name = "angels-electrolyser-2",
		level_name = "angels-electrolyser-2-level-",
		max_level = get_machine_max_level("angels-electrolyser-2")
	}
	machines_table["angels-electrolyser-3"] = {
		name = "angels-electrolyser-3",
		level_name = "angels-electrolyser-3-level-",
		max_level = get_machine_max_level("angels-electrolyser-3")
	}
	machines_table["angels-electrolyser-4"] = {
		name = "angels-electrolyser-4",
		level_name = "angels-electrolyser-4-level-",
		max_level = get_machine_max_level("angels-electrolyser-4")
	}
	machines_table["algae-farm"] = {
		name = "algae-farm",
		level_name = "algae-farm-level-",
		max_level = get_machine_max_level("algae-farm")
	}
	machines_table["algae-farm-2"] = {
		name = "algae-farm-2",
		level_name = "algae-farm-2-level-",
		max_level = get_machine_max_level("algae-farm-2")
	}
	machines_table["algae-farm-3"] = {
		name = "algae-farm-3",
		level_name = "algae-farm-3-level-",
		max_level = get_machine_max_level("algae-farm-3")
	}
	machines_table["algae-farm-4"] = {
		name = "algae-farm-4",
		level_name = "algae-farm-4-level-",
		max_level = get_machine_max_level("algae-farm-4")
	}
	
	-- ev-refining machines
	machines_table["crusher1"] = {
		name = "crusher1",
		level_name = "crusher1-level-",
		max_level = get_machine_max_level("crusher1"),
		next_machine = "crusher2"
	}
	machines_table["crusher2"] = {
		name = "crusher2",
		level_name = "crusher2-level-",
		max_level = get_machine_max_level("crusher2"),
		next_machine = "crusher3"
	}
	machines_table["crusher3"] = {
		name = "crusher3",
		level_name = "crusher3-level-",
		max_level = get_machine_max_level("crusher3")
	}
	machines_table["echamber1"] = {
		name = "echamber1",
		level_name = "echamber1-level-",
		max_level = get_machine_max_level("echamber1"),
		next_machine = "echamber2"
	}
	machines_table["echamber2"] = {
		name = "echamber2",
		level_name = "echamber2-level-",
		max_level = get_machine_max_level("echamber2"),
		next_machine = "echamber3"
	}
	machines_table["echamber3"] = {
		name = "echamber3",
		level_name = "echamber3-level-",
		max_level = get_machine_max_level("echamber3")
	}
	machines_table["pchamber1"] = {
		name = "pchamber1",
		level_name = "pchamber1-level-",
		max_level = get_machine_max_level("pchamber1"),
		next_machine = "pchamber2"
	}
	machines_table["pchamber2"] = {
		name = "pchamber2",
		level_name = "pchamber2-level-",
		max_level = get_machine_max_level("pchamber2")
	}
	
	-- Add recycler if enabled
	if settings.startup["factory-levels-enable-recycler-leveling"].value then
		machines_table["recycler"] = {
			name = "recycler",
			level_name = "recycler-level-",
			max_level = get_machine_max_level("recycler")
		}
	end
	
	return machines_table
end

function update_machine_levels(overwrite)
	if overwrite then
		max_level = 1    -- Just in case another mod cuts the max level of this mods machines to something like 25.
		required_items_for_levels = {}
		exponent = settings.global["factory-levels-exponent"].value
		-- Refresh machines table to use current settings
		machines = get_machines_table()
		for _, machine in pairs(machines) do
			if max_level < machine.max_level then
				max_level = machine.max_level
			end
		end
	end
	local base_requirement = settings.global["factory-levels-base-requirement"].value
	for i = 1, (max_level + 1), 1 do
		-- Adding one more level for machine upgrade to next tier.
		if required_items_for_levels[i] == nil then
			table.insert(required_items_for_levels, math.floor(base_requirement + math.pow(i, exponent)))
		end
	end
end

remote.add_interface("factory_levels", {
	add_machine = function(machine)
		if machine.name == nil or machine.level_name == nil or machine.max_level == nil then
			return false
		else
			machines[machine.name] = machine
			if machine.max_level > max_level then
				max_level = machine.max_level
				update_machine_levels()
			end
			return true
		end
	end,
	update_machine = function(machine)
		if machine.name == nil or machines[machine.name] == nil then
			return false
		else
			machines[machine.name].level_name = machine.level_name or machines[machine.name].level_name
			machines[machine.name].max_level = machine.max_level or machines[machine.name].max_level
			machines[machine.name].next_machine = machine.next_machine or machines[machine.name].next_machine
			machines[machine.name].disable_mod_setting = machine.disable_mod_setting or machines[machine.name].disable_mod_setting
			if machines[machine.name].max_level > max_level then
				max_level = machines[machine.name].max_level
				update_machine_levels()
			end
			return true
		end
	end,
	remove_machine = function(machine_name)
		if machine_name == nil or machines[machine_name] == nil then
			return false
		end
		machines[machine_name] = nil
		return true
	end,
	get_machine = function(machine_name)
		if machine_name == nil then
			return nil
		end
		return machines[machine_name]
	end
})

function determine_level(finished_products_count)
	local should_have_level = 1

	for level, min_count_required_for_level in pairs(required_items_for_levels) do
		if finished_products_count >= min_count_required_for_level then
			should_have_level = level
		end
	end

	return should_have_level
end

function determine_machine(entity)
	if settings.global["factory-levels-disable-mod"].value then
		return nil
	end

	if entity == nil or not entity.valid or (entity.type ~= "assembling-machine" and entity.type ~= "furnace") then
		return nil
	end

	for _, machine in pairs(machines) do
		if entity.name == machine.name or string_starts_with(entity.name, machine.level_name) then
			return machine
		end
	end

	return nil
end

function get_inventory_contents(inventory)
	inventory_results = {}
	if inventory == nil then
		return inventory_results
	end

	inventory_contents = inventory.get_contents()
	for name, count in pairs(inventory_contents) do
		table.insert(inventory_results, { name = name, count = count })
	end
	return inventory_results
end

function upgrade_factory(surface, targetname, sourceentity)
	local finished_products_count = sourceentity.products_finished
	local box = sourceentity.bounding_box
	local item_requests = nil
	local recipe = nil
	local recipe_quality = nil
	local mirroring = sourceentity.mirroring

	local existing_requests = surface.find_entity("item-request-proxy", sourceentity.position)
	if existing_requests then
		-- Module requests do not survive the machine being replaced.  Preserve them before the machine is replaced.
		item_requests = {}
		for module_name, count in pairs(existing_requests.item_requests) do
			item_requests[module_name] = count
		end
		if next(item_requests, nil) == nil then
			item_requests = nil
		end
	end

	storage.built_machines[sourceentity.unit_number] = nil

	local created = surface.create_entity { name = targetname,
											source = sourceentity,
											direction = sourceentity.direction,
											quality = sourceentity.quality,
											raise_built = true,
											fast_replace = true,
											spill = false,
											create_build_effect_smoke = false,
											position = sourceentity.position,
											force = sourceentity.force }
	created.mirroring = mirroring

	storage.built_machines[created.unit_number] = { entity = created, unit_number = created.unit_number }
	-- #51 disable module requests for now
	--if item_requests then
	--	surface.create_entity({ name = "item-request-proxy",
	--						position = created.position,
	--						force = created.force,
	--						target = created,
	--						item-request-proxy = item_requests })
	--end

	sourceentity.destroy()

	created.products_finished = finished_products_count;

	local old_on_ground = surface.find_entities_filtered {
		area = {
			left_top = { x = box.left_top.x - 0.3, y = box.left_top.y - 0.3 },
			right_bottom = { x = box.right_bottom.x + 0.3, y = box.right_bottom.y + 0.3 }
		},
		name = 'item-on-ground'
	}

	for _, item in pairs(old_on_ground) do
		item.destroy()
	end

	return created
end

function replace_machines(entities)
	for _, entity in pairs(entities) do
		local should_have_level = determine_level(entity.products_finished)
		for _, machine in pairs(machines) do
			if (entity.name == machine.name and entity.products_finished > 0) then
				if not settings.global["factory-levels-disable-mod"].value then
					if not machine.disable_mod_setting or not settings.global[machine.disable_mod_setting].value then
						upgrade_factory(entity.surface, machine.level_name .. math.min(should_have_level, machine.max_level), entity)
					end
				end
				break
			elseif string_starts_with(entity.name, machine.level_name) then
				local current_level = tonumber(string.match(entity.name, "%d+$"))
				if (settings.global["factory-levels-disable-mod"].value) or (machine.disable_mod_setting and settings.global[machine.disable_mod_setting].value) then
					upgrade_factory(entity.surface, machine.name, entity)
					break
				elseif (should_have_level > current_level and current_level < machine.max_level) then
					upgrade_factory(entity.surface, machine.level_name .. math.min(should_have_level, machine.max_level), entity)
					break
				elseif (should_have_level > current_level and current_level >= machine.max_level and machine.next_machine ~= nil) then
					local created = upgrade_factory(entity.surface, machine.next_machine, entity)
					created.products_finished = 0
					break
				end
			end
		end
	end
end

function get_next_machine()
	if storage.current_machine == nil or storage.check_machines == nil then
		storage.check_machines = table.deepcopy(storage.built_machines)
	end
	storage.current_machine = next(storage.check_machines, storage.current_machine)
end

-- Use configurable check interval and machines per check
function setup_tick_handler()
	local check_interval = settings.global["factory-levels-check-interval"].value
	-- Remove the current specific handler first, if one exists
	if current_tick_interval then
		script.on_nth_tick(current_tick_interval, nil)
	end
	current_tick_interval = check_interval
	
	-- Set new handler with current interval
	script.on_nth_tick(check_interval, function(event)
		local assemblers = {}
		local machines_per_check = settings.global["factory-levels-machines-per-check"].value

		for i = 1, machines_per_check do
			get_next_machine()
			if i == 1 and storage.current_machine == nil then
				return
			end
			if storage.current_machine == nil then
				break
			end
			local entity = storage.check_machines[storage.current_machine]

			if entity and entity.entity and entity.entity.valid then
				table.insert(assemblers, entity.entity)
			else
				storage.built_machines[storage.current_machine] = nil
			end
		end

		replace_machines(assemblers)
	end)
end

function on_mined_entity(event)
	if (event.entity ~= nil and event.entity.products_finished ~= nil and event.entity.products_finished > 0) then
		storage.built_machines[event.entity.unit_number] = nil
		if event.entity.type == "furnace" then
			table.insert(storage.stored_products_finished_furnaces, event.entity.products_finished)
			table.sort(storage.stored_products_finished_furnaces)
		end

		if event.entity.type == "assembling-machine" then
			table.insert(storage.stored_products_finished_assemblers, event.entity.products_finished)
			table.sort(storage.stored_products_finished_assemblers)
		end
	end
end

script.on_event(
		defines.events.on_player_mined_entity,
		on_mined_entity,
		{ { filter = "type", type = "assembling-machine" },
		  { filter = "type", type = "furnace" } })

script.on_event(
		defines.events.on_robot_mined_entity,
		on_mined_entity,
		{ { filter = "type", type = "assembling-machine" },
		  { filter = "type", type = "furnace" } })

function replace_built_entity(entity, finished_product_count)
	storage.built_machines[entity.unit_number] = { entity = entity, unit_number = entity.unit_number }
	local machine = determine_machine(entity)

	if finished_product_count ~= nil then
		local should_have_level = determine_level(finished_product_count)
		entity.products_finished = finished_product_count

		if machine ~= nil then
			local created = upgrade_factory(entity.surface, machine.level_name .. math.min(should_have_level, machine.max_level), entity)
			created.products_finished = finished_product_count
		end
	else
		if machine ~= nil and machine.name ~= entity.name then
			upgrade_factory(entity.surface, machine.name, entity)
		end
	end
end

function on_built_entity(event)
	if (event.entity ~= nil and event.entity.type == "assembling-machine") then
		local finished_product_count = table.remove(storage.stored_products_finished_assemblers)
		replace_built_entity(event.entity, finished_product_count)
		return
	end

	if (event.entity ~= nil and event.entity.type == "furnace") then
		local finished_product_count = table.remove(storage.stored_products_finished_furnaces)
		replace_built_entity(event.entity, finished_product_count)
		return
	end
end

function on_runtime_mod_setting_changed(event)
	if event.setting == "factory-levels-disable-mod" then
		-- Refresh EVERY machine immediately.  User potentially wishes to remove this mod or some other mod that depends on this mod.
		get_built_machines()
	elseif event.setting == "factory-levels-exponent" or event.setting == "factory-levels-base-requirement" then
		update_machine_levels(true)
		if settings.global["factory-levels-debug-mode"].value then
			if required_items_for_levels[25] then
				game.print("Crafts for Level 25: " .. required_items_for_levels[25])
			end
			if required_items_for_levels[50] then
				game.print("Crafts for Level 50: " .. required_items_for_levels[50])
			end
			if required_items_for_levels[100] then
				game.print("Crafts for Level 100: " .. required_items_for_levels[100])
			end
			if max_level ~= 100 then
				game.print("Crafts for Max level of " .. max_level .. ": " .. required_items_for_levels[max_level])
			end
		end
	elseif event.setting == "factory-levels-check-interval" or event.setting == "factory-levels-machines-per-check" then
		-- Update tick handler with new performance settings
		setup_tick_handler()
	elseif event.setting:find("factory-levels-max-level-tier") or 
		   event.setting:find("factory-levels-enable-") then
		-- Refresh machines table and levels when machine type settings change
		update_machine_levels(true)
		get_built_machines()
	else
		update_machines = false
		for machine_name, machine in pairs(machines) do
			if event.setting == machine.disable_mod_setting then
				update_machines = true
			end
		end
		if update_machines then
			get_built_machines()
		end
	end
end

script.on_event(
		defines.events.on_robot_built_entity,
		on_built_entity,
		{ { filter = "type", type = "assembling-machine" },
		  { filter = "type", type = "furnace" } })

script.on_event(
		defines.events.on_built_entity,
		on_built_entity,
		{ { filter = "type", type = "assembling-machine" },
		  { filter = "type", type = "furnace" } })

script.on_event(
		defines.events.on_runtime_mod_setting_changed,
		on_runtime_mod_setting_changed)