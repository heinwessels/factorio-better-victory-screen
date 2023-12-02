-- This GUI library is created by _CodeGreen

local mod_name = "__"..script.mod_name.."__/handlers"

local handler_funcs = {}
local handler_names = {}

local function error_def(def, s)
    error(s.."\n"..serpent.block(def, {maxlevel = 1, sortkeys = false}))
end

--- Adds one or more GUI elements to a parent GUI element.
--- @param parent LuaGuiElement The parent element to add new elements to.
--- @param def GuiElemDef The element definition(s) to add to the parent.
--- @param elems? table<string, LuaGuiElement> The table to add new element references to.
--- @return LuaGuiElement elem The topmost element added to the parent.
--- @return table<string, LuaGuiElement> elems The table of element references, indexed by element name.
local function add(parent, def, elems)
    elems = elems or {} --[[@as table<string, LuaGuiElement>]]
    local elem
    if def.args then
        local args = def.args
        local children = def.children
        if def[1] then
            if children then
                error_def(def, "Cannot define children in array portion and subtable simultaneously.")
            end
            children = {}
            for i = 1, #def do
                children[i] = def[i]
            end
        end
        local tags = args.tags
        if tags and tags[mod_name] then
            error_def(def, "Tag index \""..mod_name.."\" is reserved for GUI Library.")
        end
        local handlers = def.handlers
        if handlers then
            local handler_tags
            if type(handlers) == "table" then
                handler_tags = {}
                for event, handler in pairs(handlers) do
                    if type(event) == "string" then
                        event = defines.events[event]
                        if not event then error_def(def, "Event \"" .. event .. "does not exist.") end
                    end
                    handler_tags[tostring(event)] = handler_names[handler]
                end
            else
                handler_tags = handler_names[def.handlers]
            end
            args.tags = tags or {}
            args.tags[mod_name] = handler_tags
        end
        elem = parent.add(args) --[[@as LuaGuiElement]]
        if tags then
            args.tags[mod_name] = nil
        else
            args.tags = nil
        end
        if args.name and def.ref ~= false then
            local ref = def.ref or args.name --[[@as string]]
            elems[ref] = elem
        end
        if def.elem_mods then
            for k, v in pairs(def.elem_mods) do
                elem[k] = v
            end
        end
        if def.style_mods then
            for k, v in pairs(def.style_mods) do
                elem.style[k] = v
            end
        end
        if def.drag_target then
            local target = elems[def.drag_target]
            if not target then
                error_def(def, "Drag target \""..def.drag_target.."\" does not exist.")
            end
            elem.drag_target = target
        end
        if children then
            for _, child in pairs(children) do
                add(elem, child, elems)
            end
        end
    elseif def.tab and def.content then
        elems = elems or {}
        local tab = add(parent, def.tab, elems) --- @cast tab LuaGuiElement
        local content = add(parent, def.content, elems) --- @cast content LuaGuiElement
        parent.add_tab(tab, content)
    else
        error_def(def, "Invalid GUI element definition:")
    end
    return elem, elems
end

--- @param event GuiEventData
--- @return boolean
local function event_handler(event)
    local element = event.element
    if not element then return false end
    local tags = element.tags
    local handler_def = tags[mod_name]
    if not handler_def then return false end
    if type(handler_def) == "table" then
        handler_def = handler_def[tostring(event.name)]
    end
    if not handler_def then return false end
    local handler = handler_funcs[handler_def]
    if not handler then return false end
    handler(event)
    return true
end

for name, id in pairs(defines.events) do
    if name:find("on_gui_") then
        script.on_event(id, event_handler)
    end
end

---Adds event handlers for glib to call when an element has a `handlers` table specified.
---@param handlers table<string, fun(e:GuiEventData)> The table of handlers for glib to call.
---@param wrapper fun(e:GuiEventData, handler:function)? (Optional) The wrapper function to call instead of the event handler directly.
local function add_handlers(handlers, wrapper)
    for name, handler in pairs(handlers) do
        if type(handler) == "function" then
            if handler_funcs[name] then
                error("Attempt to register handler function with duplicate name \""..name.."\".")
            end
            if handler_names[handler] then
                error("Attempt to register duplicate handler function.")
            end
            handler_names[handler] = name
            if wrapper then
                handler_funcs[name] = function(e)
                    wrapper(e, handler)
                end
            else
                handler_funcs[name] = handler
            end
        end
    end
end

return {
    add = add,
    add_handlers = add_handlers,
}

---@diagnostic disable: duplicate-doc-field
---@class GuiElemDef
---@field args LuaGuiElement.add_param
---@field ref? string|false
---@field drag_target? string
---@field elem_mods? ElemMods
---@field style_mods? StyleMods
---@field handlers? GuiEventHandler
---@field children? GuiElemDef[]
---@field tab? GuiElemDef
---@field content? GuiElemDef

---@alias GuiEventHandler fun(e:GuiEventData)|table<string|defines.events, fun(event:GuiEventData)>
---@alias GuiEventData
---|EventData.on_gui_checked_state_changed
---|EventData.on_gui_click
---|EventData.on_gui_closed
---|EventData.on_gui_confirmed
---|EventData.on_gui_elem_changed
---|EventData.on_gui_hover
---|EventData.on_gui_leave
---|EventData.on_gui_location_changed
---|EventData.on_gui_opened
---|EventData.on_gui_selected_tab_changed
---|EventData.on_gui_selection_state_changed
---|EventData.on_gui_switch_state_changed
---|EventData.on_gui_text_changed
---|EventData.on_gui_value_changed

---@class ElemMods
---@field name? string
---@field caption? LocalisedString
---@field value? double
---@field style? string
---@field visible? boolean
---@field text? string
---@field state? boolean
---@field sprite? SpritePath
---@field resize_to_sprite? boolean
---@field hovered_sprite? SpritePath
---@field clicked_sprite? SpritePath
---@field tooltip? LocalisedString
---@field horizontal_scroll_policy? string
---@field vertical_scroll_policy? string
---@field items? LocalisedString[]
---@field selected_index? uint
---@field number? double
---@field show_percent_for_small_numbers? boolean
---@field location? GuiLocation
---@field auto_center? boolean
---@field badge_text? LocalisedString
---@field auto_toggle? boolean
---@field toggled? boolean
---@field game_controller_interaction? defines.game_controller_interaction
---@field position? MapPosition
---@field surface_index? uint
---@field zoom? double
---@field minimap_player_index? uint
---@field force? string
---@field elem_value? string|SignalID
---@field elem_filters? PrototypeFilter
---@field selectable? boolean
---@field word_wrap? boolean
---@field read_only? boolean
---@field enabled? boolean
---@field ignored_by_interaction? boolean
---@field locked? boolean
---@field draw_vertical_lines? boolean
---@field draw_horizontal_lines? boolean
---@field draw_horizontal_line_after_headers? boolean
---@field vertical_centering? boolean
---@field slider_value? double
---@field mouse_button_filter? MouseButtonFlags
---@field numeric? boolean
---@field allow_decimal? boolean
---@field allow_negative? boolean
---@field is_password? boolean
---@field lose_focus_on_confirm? boolean
---@field clear_and_focus_on_right_click? boolean
---@field drag_target? LuaGuiElement
---@field selected_tab_index? uint
---@field entity? LuaEntity
---@field anchor? GuiAnchor
---@field tags? Tags
---@field raise_hover_events? boolean
---@field switch_state? string
---@field allow_none_state? boolean
---@field left_label_caption? LocalisedString
---@field left_label_tooltip? LocalisedString
---@field right_label_caption? LocalisedString
---@field right_label_tooltip? LocalisedString

---@class StyleMods
---@field minimal_width? int
---@field maximal_width? int
---@field minimal_height? int
---@field maximal_height? int
---@field natural_width? int
---@field natural_height? int
---@field top_padding? int
---@field right_padding? int
---@field bottom_padding? int
---@field left_padding? int
---@field top_margin? int
---@field right_margin? int
---@field bottom_margin? int
---@field left_margin? int
---@field horizontal_align? string
---@field vertical_align? string
---@field font_color? Color
---@field font? string
---@field top_cell_padding? int
---@field right_cell_padding? int
---@field bottom_cell_padding? int
---@field left_cell_padding? int
---@field horizontally_stretchable? boolean
---@field vertically_stretchable? boolean
---@field horizontally_squashable? boolean
---@field vertically_squashable? boolean
---@field rich_text_setting? defines.rich_text_setting
---@field hovered_font_color? Color
---@field clicked_font_color? Color
---@field disabled_font_color? Color
---@field pie_progress_color? Color
---@field clicked_vertical_offset? int
---@field selected_font_color? Color
---@field selected_hovered_font_color? Color
---@field selected_clicked_font_color? Color
---@field strikethrough_color? Color
---@field horizontal_spacing? int
---@field vertical_spacing? int
---@field use_header_filler? boolean
---@field bar_width? uint
---@field color? Color
---@field single_line? boolean
---@field extra_top_padding_when_activated? int
---@field extra_bottom_padding_when_activated? int
---@field extra_left_padding_when_activated? int
---@field extra_right_padding_when_activated? int
---@field extra_top_margin_when_activated? int
---@field extra_bottom_margin_when_activated? int
---@field extra_left_margin_when_activated? int
---@field extra_right_margin_when_activated? int
---@field stretch_image_to_widget_size? boolean
---@field badge_font? string
---@field badge_horizontal_spacing? int
---@field default_badge_font_color? Color
---@field selected_badge_font_color? Color
---@field disabled_badge_font_color? Color
---@field width? int
---@field height? int
---@field size? int|int[]
---@field padding? int|int[]
---@field margin? int|int[]
---@field cell_padding? int
---@field extra_padding_when_activated? int|int[]
---@field extra_margin_when_activated? int|int[]