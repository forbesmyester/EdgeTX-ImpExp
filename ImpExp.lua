local toolName = "TNS|ImpExp|TNE"


local function init()
    lcd.clear()
end


-- function dump_table(o, escSpec, indent)
--   if type(o) == 'table' then
--      local s = '{ '
--      for k,v in pairs(o) do
--         if type(k) ~= 'number' then k = '"'..k..'"' end
--         local vout = ""
--         if type(o) == 'table' then
--             vout = dump_table(v, escSpec)
--         end
--         s = s .. '['..k..'] = ' .. vout .. ','
--      end
--      return s .. '} '
--   else
--      return tostring(o)
--   end
-- end


local function get_model()
    return model
end


function serialize_model_index_index(getter, count)
    local input = 0
    local r = {}
    while true do
        local rr = {}
        local tab = true
        local line = 0
        while tab ~= nil do
            tab = getter(input, line)
            if tab ~= nil then
                print("CONT " .. input .. " " .. line)
                table_insert(rr, tab)
                -- print("input="..input.."/".."line="..line.."  "..dump_table(tab))
            end
            line = line + 1
        end
        if (count == -1) and (table_length(rr) == 0) then
            return r
        end
        table_insert(r, rr)
        input = input + 1
        if (input >= count) then
            return r
        end
    end
    return r
end


function serialize_model_index(getter, model, count)
    local rr = {}
    local tab = true
    local line = 0
    while (count > -1) and (tab ~= nil) do
        tab = getter(line, 0)
        if tab ~= nil then
            -- print(dump_table(tab))
            table_insert(rr, tab)
        end
        line = line + 1
        if (line >= count) then
            return rr
        end
    end
    return rr
end


function to_char(c, str)
    local i
    i = string.find(str, c, 1, true)
    if i == nil then
        return str, ""
    end
    return string.sub(str, 1, i-1), string.sub(str, i+1)
end


function skip_first_spaces(str)
    local max = 1
    local i
    for i = 1, #str do
        if string.sub(str,i,i) ~= " " then
            return string.sub(str,i)
        end
    end
    return str
end


function table_length(tab)
    local c = 0
    local _
    for _ in pairs(tab) do c = c + 1 end
    return c
end


function typeify(s)
    if string.sub(s,1,1) == "n" then
        return tonumber(string.sub(s,2))
    end
    if string.sub(s,1,1) == "s" then
        return string.sub(s, 2)
    end
    if string.sub(s,1,1) == "b" then
        local v = string.sub(s,2)
        if (v == "T") or (v == "t") or (t == "1") then
            return true
        end
        return false
    end
end


function process_worker(str)
    local tab = {}
    local line
    while #str > 0 do
        line, str = to_char("\n", str)
        local k, v = to_char("=", skip_first_spaces(line))
        if skip_first_spaces(k) == "END" then
            return tab, str
        elseif skip_first_spaces(v) == "" then
            v, str = process_worker(str)
        end
        if string.match(k, '^[0-9]+$') then
            k = tonumber(k)
        end
        if type(v) == "table" then
            tab[k] = v
        else
            tab[k] = typeify(v)
        end
    end
    return tab, str
end


function process(str)
    local tab, _ = process_worker(str)
    return tab
end


function table_insert(tab, line)
    local n = table_length(tab)
    tab[n+1] = line
    return tab
end


function serialize_table_worker(tab, indent)
    local k, v
    local lines = {}
    for k, v in pairs(tab) do
        if type(v) == 'table' then
            local vv, _
            lines = table_insert(lines, indent .. k)
            for _, vv in pairs(serialize_table_worker(v, indent .. "  ")) do
                lines = table_insert(lines, vv)
            end
            lines = table_insert(lines, indent.."END")
        else
            local t = type(v)
            if t == "boolean" then
                if v then v = "bt" else v = "bf" end
            end
            if t == "string" then v = "s" .. v end
            if t == "number" then v = "n" .. v end
            -- lines.insert(indent .. k .. '=' .. v)
            lines = table_insert(lines, indent .. k .. '=' .. v)
        end
    end
    return lines
end

function serialize_table(tab)
    return serialize_table_worker(tab, "")
end

-- function print_serialized(serial)
--     local _, v
--     for _,v in pairs(serial) do
--         print(v)
--     end
-- end


function array_to_string(serial)
    local s = ""
    local first = true
    local _, v
    for _,v in pairs(serial) do
        if first ~= true then
            s = s .. "\n"
        end
        s = s .. v
        first = false
    end
    return s
end

function read_all(filename)
    local f = io.open(filename, "")
    local s = ""
    local read_data = "SOMETHING"
    while read_data ~= "" do
        read_data = io.read(f, 99)
        s = s .. read_data
    end
    io.close(f)
    return s
end

function write_all(filename, lines)
    local f = io.open(filename, "w")
    io.write(f, array_to_string(lines))
    io.close(f)
    return true
end

function model_input_getter(index_1, index_2)
    local model = get_model()
    print("GETTER: INPUT: " ..  index_1 .. "/" .. index_2)
    return model.getInput(index_1, index_2)
end

function model_global_variable_values_getter(index_1, index_2)
    local model = get_model()
    print("GETTER: GLOBAL_VARIABLE_VALUES: " ..  index_1 .. "/" .. index_2)
    return model.getGlobalVariable(index_1, index_2)
end

function model_global_variable_values_getter(index_1, index_2)
    local model = get_model()
    print("GETTER: GLOBAL_VARIABLE_DETAILS" ..  index_1 .. "/" .. index_2)
    return model.getGlobalVariable(index_1, index_2)
end

function model_mix_getter(index_1, index_2)
    local model = get_model()
    print("GETTER: MIX: " ..  index_1 .. "/" .. index_2)
    return model.getMix(index_1, index_2)
end

function model_single_meta_getter(f, desc, index_1, zero_or_nil_return)
    if zero_or_nil_return ~= 0 then return nil end
    local model = get_model()
    print("GETTER: " .. desc .. ": " ..  index_1)
    return f(index_1)
end

function model_output_getter(index_1, zero_or_nil_return)
    return model_single_meta_getter(
        function(index_1, zero_or_nil_return) return model.getOutput(index_1) end,
        "GETTER: OUTPUT",
        index_1,
        zero_or_nil_return
    )
end

function model_curve_getter(index_1, zero_or_nil_return)
    return model_single_meta_getter(
        function(index_1, zero_or_nil_return) return model.getCurve(index_1) end,
        "GETTER: CURVE",
        index_1,
        zero_or_nil_return
    )
end

function model_logical_switch_getter(index_1, zero_or_nil_return)
    return model_single_meta_getter(
        function(index_1, zero_or_nil_return) return model.getLogicalSwitch(index_1) end,
        "GETTER: LOGICAL_SWITCH",
        index_1,
        zero_or_nil_return
    )
end

function model_flight_mode_getter(index_1, zero_or_nil_return)
    return model_single_meta_getter(
        function(index_1, zero_or_nil_return) return model.getFlightMode(index_1) end,
        "GETTER: LOGICAL_SWITCH",
        index_1,
        zero_or_nil_return
    )
end

function model_custom_function_getter(index_1, zero_or_nil_return)
    return model_single_meta_getter(
        function(index_1, zero_or_nil_return) return model.getCustomFunction(index_1) end,
        "GETTER: CUSTOM_FUNCTION",
        index_1,
        zero_or_nil_return
    )
end

function model_global_variable_details_getter(index_1, zero_or_nil_return)
    return model_single_meta_getter(
        function(index_1, zero_or_nil_return) return model.getGlobalVariableDetails(index_1) end,
        "GETTER: GLOBAL_VARIABLE_DETAILS",
        index_1,
        zero_or_nil_return
    )
end

function dump_model_index_index(filename, getter, count)
    write_all(filename, serialize_table(serialize_model_index_index(getter, count)))
end

function dump_model_index(filename, getter)
    write_all(filename, serialize_table(serialize_model_index(getter, "")))
end

function load_inputs()
    print("LOAD INPUTS")
    local line, value, input_contents
    local inputs = process(read_all("inputs.dat"))

    local del_inputs = serialize_model_index_index(model_input_getter, 32)
    for input, input_contents in pairs(del_inputs) do
        print("" .. input .. "=" .. table_length(input_contents))
        local i = table_length(input_contents)
        while i > 0 do
                print("model.deleteInput(" .. input - 1 .. ", " .. i - 1 .. ")")
                model.deleteInput(input - 1, i - 1)
		i = i - 1
        end
    end

    for input, input_contents in pairs(inputs) do
        for line, value in pairs(input_contents) do
            model.insertInput(input - 1, line - 1, value)
        end
    end
end

function load_global_variable_value()
    print("LOAD GLOBAL_VARIABLE_VALUES")
    local line, value, input_contents
    local inputs = process(read_all("global_variable_values.dat"))

    for input, input_contents in pairs(inputs) do
        for line, value in pairs(input_contents) do
            model.setGlobalVariable(input - 1, line - 1, value)
        end
    end
end

function load_mixes()
    print("LOAD MIXES")
    local line, value, mix_contents, mix
    local mixes
    mixes = process(read_all("mixes.dat"))

    local del_mixes = serialize_model_index_index(model_mix_getter, 32)
    for mix, mix_contents in pairs(del_mixes) do
        print("" .. mix .. "=" .. table_length(mix_contents))
        local i = table_length(mix_contents)
        while i > 0 do
                print("model.deleteMix(" .. mix - 1 .. ", " .. i - 1 .. ")")
                model.deleteMix(mix - 1, i - 1)
		i = i - 1
        end
    end

    for mix, mix_contents in pairs(mixes) do
        for line, value in pairs(mix_contents) do
            model.insertMix(mix - 1, line - 1, value)
        end
    end
end

function load_global_variable_details(f, filename)
    print("LOAD " .. filename)
    local line, value, input_contents, idx, tab
    local inputs = process(read_all(filename))
    -- print(array_to_string(serialize_table(process(txt))))
    for idx, tab in pairs(inputs) do
        f(idx, tab)
    end
end

local sel_0 = 0
local sel_1 = 0
local mode = 0

local function maybe_to_upper(b, s)
    if (b) then
        return string.upper(s)
    end
    return s
end


local function run(event)
    local write_funcs = {
            function() return dump_model_index_index("inputs.dat", model_input_getter, 32) end,
            function() return dump_model_index_index("mixes.dat", model_mix_getter, 32) end,
            function() return dump_model_index("outputs.dat", model_output_getter, 32) end,
            function() return dump_model_index("curves.dat", model_curve_getter, 32) end,
            function() return dump_model_index_index("global_variable_values.dat", model_global_variable_values_getter, 9) end,
            function() return dump_model_index("custom_functions.dat", model_custom_function_getter, 64) end,
            function() return dump_model_index("logical_switches.dat", model_logical_switch_getter, 64) end,
            function() return dump_model_index("flight_modes.dat", model_flight_mode_getter, 8) end,
            function() return dump_model_index("global_variable_details.dat", model_global_variable_details_getter, 9) end,
        }
    local read_funcs = {
            load_inputs,
            load_mixes,
            function()
                return load_global_variable_details(
                    function(idx, tab) model.setOutput(idx - 1, tab) end,
                    "outputs.dat"
                )
            end,
            function()
                load_global_variable_details(
                    function(idx, tab)
                        print("set curve " .. idx)
                        -- print(dump_table(tab))
                        local r = model.setCurve(idx - 1, tab)
                        print("R=" .. r)
                    end,
                    "curves.dat"
                )
            end,
            load_global_variable_value,
            function()
                load_global_variable_details(
                    function(idx, tab) model.setCustomFunction(idx - 1, tab) end,
                    "custom_functions.dat"
                )
            end,
            function()
                load_global_variable_details(
                    function(idx, tab) model.setLogicalSwitch(idx - 1, tab) end,
                    "logical_switches.dat"
                )
            end,
            function()
                load_global_variable_details(
                    function(idx, tab) model.setFlightMode(idx - 1, tab) end,
                    "flight_modes.dat"
                )
            end,
            function()
                load_global_variable_details(
                    function(idx, tab) model.setGlobalVariableDetails(idx - 1, tab) end,
                    "global_variable_details.dat"
                )
            end,
        }

    local funcs = { write_funcs, read_funcs }


    if event == EVT_ENTER_BREAK then
        mode = mode + 1
    end

    if mode == 2 then
        print(sel_1 .. "/" .. sel_0)
        local f = funcs[sel_1 + 1][sel_0 + 1]
        print("call f ++" .. sel_1 .. "/" .. sel_0)
        print("t1=" .. table_length(funcs[1]))
        print("t2=" .. table_length(funcs[2]))
        f()
        print("call f --")
        return 1
    end

    if event == EVT_EXIT_BREAK then
        if mode == 0 then
            return 1
        end
        if mode == 1 then
            mode = 0
        end
    end

    if mode == 0 then
        local max_menu = 8
        if event == EVT_ROT_LEFT then
            sel_0 = sel_0 - 1
        end
        if event == EVT_ROT_RIGHT then
            sel_0 = sel_0 + 1
        end
        if (sel_0 < 0) then
            sel_0 = max_menu
        end
        if (sel_0 > max_menu) then
            sel_0 = 0
        end
    end

    if mode == 1 then
        local max_menu = 1
        if event == EVT_ROT_LEFT then
            sel_1 = sel_1 - 1
        end
        if event == EVT_ROT_RIGHT then
            sel_1 = sel_1 + 1
        end
        if (sel_1 < 0) then
            sel_1 = max_menu
        end
        if (sel_1 > max_menu) then
            sel_1 = 0
        end
    end

    lcd.clear()
    lcd.drawText(1, 1, maybe_to_upper(sel_0 == 0, 'inputs'), SMLSIZE)
    lcd.drawText(1, 9, maybe_to_upper(sel_0 == 1, 'mixes'), SMLSIZE)
    lcd.drawText(1, 18, maybe_to_upper(sel_0 == 2, 'outputs'), SMLSIZE)
    lcd.drawText(1, 27, maybe_to_upper(sel_0 == 3, 'curves'), SMLSIZE)
    lcd.drawText(1, 36, maybe_to_upper(sel_0 == 4, 'gvar values'), SMLSIZE)
    lcd.drawText(64, 1,  maybe_to_upper(sel_0 == 5, 'functions'), SMLSIZE)
    lcd.drawText(64, 9,  maybe_to_upper(sel_0 == 6, 'logical sw'), SMLSIZE)
    lcd.drawText(64, 18, maybe_to_upper(sel_0 == 7, 'flight modes'), SMLSIZE)
    lcd.drawText(64, 27, maybe_to_upper(sel_0 == 8, 'gvar details'), SMLSIZE)

    lcd.drawText(12, 55, maybe_to_upper((mode == 1) and (sel_1 == 0), '[export]'), SMLSIZE)
    lcd.drawText(76, 55, maybe_to_upper((mode == 1) and (sel_1 == 1), '[import]'), SMLSIZE)

    -- todo: timer

    return 0
end

run()

return {init = init, run = run}


