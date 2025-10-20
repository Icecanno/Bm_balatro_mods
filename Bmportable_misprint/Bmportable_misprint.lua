--- STEAMODDED HEADER
--- MOD_NAME: Bmportable_misprint
--- MOD_ID: Bmportable_misprint
--- MOD_AUTHOR: [BaiMao Brookling]
--- MOD_DESCRIPTION: More convenient to view misprinted information
--- BADGE_COLOUR: 366999
--- VERSION: 1.0.1l
----------------------------------------------
------------MOD CODE -------------------------

Portable = SMODS.current_mod

Portable.config_tab = function()
    return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
        create_toggle({label = localize("k_instant_planet"), ref_table = Portable.config, ref_value = "instant_planet"}),
        create_toggle({label = localize("k_predict_random"), ref_table = Portable.config, ref_value = "predict_random"}),
        create_toggle({label = localize("k_predict_random_bonus"), ref_table = Portable.config, ref_value = "predict_random_bonus"}),
        create_toggle({label = localize("k_flash_load"), ref_table = Portable.config, ref_value = "flash_load"}),
        create_toggle({label = localize("b_manual_save"), ref_table = Portable.config, ref_value = "manual_save"}),
        create_toggle({label = localize("k_score_display"), ref_table = Portable.config, ref_value = "score_display"}),
    }}
end

function Portable.process_loc_text()
    G.localization.misc.dictionary = G.localization.misc.dictionary or {}
end

local Game_update_ref = Game.update
function Game:update(dt)
    Game_update_ref(self, dt)
    if Portable.config.score_display then update_preview(dt) end
    G.GAME.misprint_rank = G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.value or nil
    G.GAME.misprint_suit = G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit or nil
end

local G_UIDEF_deck_preview_ref = G.UIDEF.deck_preview
function G.UIDEF.deck_preview(args)
    local _minh, _minw = 0.35, 0.5
    local _colour = ((G.GAME.misprint_suit == 'Spades' or G.GAME.misprint_suit == 'Clubs') and G.C.WHITE or G.C.RED)
    local t = G_UIDEF_deck_preview_ref(args)
    local suit_labels = t.nodes[1].nodes[1].nodes[1].nodes
    local tt = {n=G.UIT.R, config={align = "cm", r = 0.1, padding = 0.04, minw = _minw, minh = 2*_minh+0.25}, nodes={
        G.GAME.misprint_rank and {n=G.UIT.T, config={text = localize('b_next')..': ', colour = G.C.WHITE, scale = 0.25, shadow = true}} or nil,
        G.GAME.misprint_suit and {n=G.UIT.T, config={text = localize(G.GAME.misprint_suit, 'suits_singular')..' '..localize(G.GAME.misprint_rank, 'ranks'), colour = _colour, scale = 0.25, shadow = true}} or nil,
    }}
    suit_labels[1] = tt
    return t
end

function G.UIDEF.current_stake()
    local rows_per_page = 1
    local cols_per_page = 1
    local bosses_options = {}
    local deck_tables = {}
    G.GAME.history_hands = G.GAME.history_hands or {}
    G.GAME.history_hands_long = next(G.GAME.history_hands) and #G.GAME.history_hands+0.9
    G.your_collection = {}
    G.your_boss = {}
    for k, v in pairs(G.P_BLINDS) do
        if v.boss and G.GAME.bosses_used[k] and G.GAME.bosses_used[k] > 0 and k ~= G.GAME.round_resets.blind_choices.Boss then
            table.insert(G.your_boss, k)
        end
    end
    table.sort(G.your_boss, function (a, b) return G.GAME.bosses_used[a] > G.GAME.bosses_used[b] end)
    table.insert(G.your_boss, 1, G.GAME.round_resets.blind_choices.Boss)
    if next(G.your_boss) then
        if #G.your_boss >= 6 then cols_per_page = 6
        else cols_per_page = #G.your_boss end
    end
    for j = 1, rows_per_page do
        local row = {n=G.UIT.R, config={colour = G.C.LIGHT}, nodes={}}
        for i = 1, cols_per_page do
            G.your_collection[i+(j-1)*4] = CardArea(G.ROOM.T.x, G.ROOM.T.h, G.CARD_W/1.3, G.CARD_W/1.3, {card_limit = 2, type = "title", highlight_limit = 0})
            table.insert(row.nodes, {n=G.UIT.O, config={object = G.your_collection[i+(j-1)*4]}})
        end
        table.insert(deck_tables, row)
    end
    for i = 1, math.ceil(#G.your_boss/(#G.your_collection)) do
        table.insert(bosses_options, localize("k_page").." "..tostring(i).."/"..tostring(math.ceil(#G.your_boss/(#G.your_collection))))
    end
    for j = 1, #G.your_collection do
        local center = G.P_BLINDS[G.your_boss[j]]
        if not center then break end
        local temp_blind = AnimatedSprite(G.your_collection[j].T.x, G.your_collection[j].T.y, G.CARD_W/1.5, G.CARD_W/1.5, G.ANIMATION_ATLAS[center.atlas or 'blind_chips'], center.pos)
        local card = Card(G.your_collection[j].T.x, G.your_collection[j].T.y, G.CARD_W/1.5, G.CARD_W/1.5, G.P_CARDS.empty, G.P_CENTERS.c_base)
        card.children.center = temp_blind
        card.config.blind = center
        temp_blind:set_role({major = card, role_type = 'Glued', draw_major = card})
        temp_blind:define_draw_steps({{shader = 'dissolve', shadow_height = 0.05}, {shader = 'dissolve'}})
        temp_blind.float = true
        card.set_sprites = function(...)
            local c = card.children.center
            Card.set_sprites(...)
            card.children.center = c
        end
        card.hover = function()
            if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
                if not card.hovering and card.states.visible then
                    card.hovering = true
                    card.hover_tilt = 3
                    card:juice_up(0.05, 0.02)
                    play_sound('chips1', math.random() * 0.1 + 0.55, 1.2)
                    card.config.h_popup = create_UIBox_blind_popup(center, true)
                    card.config.h_popup_config = card:align_h_popup()
                    Node.hover(card)
                end
            end
            card.stop_hover = function()
                card.hovering = false
                Node.stop_hover(card)
                card.hover_tilt = 0
            end
        end
        if G.GAME.bosses_used[G.your_boss[j]] >= 5 then
            card:set_edition({negative = true}, true)
        elseif G.GAME.bosses_used[G.your_boss[j]] >= 4 then
            card:set_edition({polychrome = true}, true)
        elseif G.GAME.bosses_used[G.your_boss[j]] >= 3 then
            card:set_edition({holo = true}, true)
        elseif G.GAME.bosses_used[G.your_boss[j]] >= 2 then
            card:set_edition({foil = true}, true)
        end
        G.your_collection[j]:emplace(card)
    end
    G.current_history = {}
    local rows_per_page_2 = 0
    local minus = 0
    if next(G.GAME.history_hands) then
        if #G.GAME.history_hands >= 4 then rows_per_page_2 = 4
        else rows_per_page_2 = #G.GAME.history_hands end
    end
    for j = 1, rows_per_page_2 do
        table.insert(G.current_history, create_UIBox_history_hand_row(G.GAME.history_hands[#G.GAME.history_hands-minus]))
        minus = minus + 1
    end
    INIT_COLLECTION_CARD_ALERTS()
    local t = {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {localize('ph_boss_hands')}, colours = {G.C.UI.TEXT_LIGHT}, bump = true, scale = 0.6})}}
        }},
        {n=G.UIT.R, config={align = "cm", minh = 0.5}, nodes={}},
        {n=G.UIT.R, config={align = "cm", colour = G.C.BLACK, r = 0.1, padding = 0.1, emboss = 0.05}, nodes={
            {n=G.UIT.R, config={align = "cm"}, nodes=deck_tables},
        }},
        {n=G.UIT.R, config={align = "cm"}, nodes={
            create_option_cycle({options = bosses_options, w = 3, cycle_shoulders = true, opt_callback = 'used_boss_page', focus_args = {snap_to = true, nav = 'wide'}, current_option = 1, colour = G.C.RED, no_pips = true})
        }},
        next(G.GAME.history_hands) and {n=G.UIT.R, config={align = "cm", padding = 0.04}, nodes={
            {n=G.UIT.O, config={id = math.floor(G.GAME.history_hands_long), func = "ROLL_history_hands", object = UIBox{definition = {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={{n=G.UIT.R, config={align = "cm", padding = 0.04}, nodes=G.current_history}}}, config = {offset = {x=0,y=0}}}}}
        }} or nil,
        next(G.GAME.history_hands) and #G.GAME.history_hands > 4 and {n=G.UIT.R, config={align = "cm"}, nodes={
            create_history_slider({w = 6, h = 0.4, ref_table = G.GAME, ref_value = 'history_hands_long', min = 4, max = #G.GAME.history_hands+0.9})
        }} or nil
    }}
    return t
end

G.FUNCS.used_boss_page = function(args)
    if not args or not args.cycle_config then return end
    for j = 1, #G.your_collection do
        for i = #G.your_collection[j].cards, 1, -1 do
            local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
            c:remove()
            c = nil
        end
    end
    for j = 1, #G.your_collection do
        local center = G.P_BLINDS[G.your_boss[j+(#G.your_collection*(args.cycle_config.current_option-1))]]
        if not center then break end
        local temp_blind = AnimatedSprite(G.ROOM.T.x+G.ROOM.T.w/2.5, G.your_collection[j].T.y, G.CARD_W/1.5, G.CARD_W/1.5, G.ANIMATION_ATLAS[center.atlas or 'blind_chips'], center.pos)
        local card = Card(G.ROOM.T.x+G.ROOM.T.w/2.5, G.your_collection[j].T.y, G.CARD_W/1.5, G.CARD_W/1.5, G.P_CARDS.empty, G.P_CENTERS.c_base)
        card.children.center = temp_blind
        card.config.blind = center
        temp_blind:set_role({major = card, role_type = 'Glued', draw_major = card})
        temp_blind:define_draw_steps({{shader = 'dissolve', shadow_height = 0.05}, {shader = 'dissolve'}})
        temp_blind.float = true
        card.set_sprites = function(...)
            local c = card.children.center
            Card.set_sprites(...)
            card.children.center = c
        end
        card.hover = function()
            if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
                if not card.hovering and card.states.visible then
                    card.hovering = true
                    card.hover_tilt = 3
                    card:juice_up(0.05, 0.02)
                    play_sound('chips1', math.random() * 0.1 + 0.55, 1.2)
                    card.config.h_popup = create_UIBox_blind_popup(center, true)
                    card.config.h_popup_config = card:align_h_popup()
                    Node.hover(card)
                end
            end
            card.stop_hover = function()
                card.hovering = false
                Node.stop_hover(card)
                card.hover_tilt = 0
            end
        end
        if G.GAME.bosses_used[G.your_boss[j+(#G.your_collection*(args.cycle_config.current_option-1))]] >= 5 then
            card:set_edition({negative = true}, true)
        elseif G.GAME.bosses_used[G.your_boss[j+(#G.your_collection*(args.cycle_config.current_option-1))]] >= 4 then
            card:set_edition({polychrome = true}, true)
        elseif G.GAME.bosses_used[G.your_boss[j+(#G.your_collection*(args.cycle_config.current_option-1))]] >= 3 then
            card:set_edition({holo = true}, true)
        elseif G.GAME.bosses_used[G.your_boss[j+(#G.your_collection*(args.cycle_config.current_option-1))]] >= 2 then
            card:set_edition({foil = true}, true)
        end
        G.your_collection[j]:emplace(card)
    end
    INIT_COLLECTION_CARD_ALERTS()
end

function create_UIBox_history_hand_row(args)
    local t = {n=G.UIT.R, config={align = "cm", padding = 0.05, r = 0.1, colour = darken(G.C.JOKER_GREY, 0.1), emboss = 0.05, hover = true, force_focus = true, on_demand_tooltip = {filler = {func = create_UIBox_history_hand_tip, args = args}}}, nodes={
        {n=G.UIT.C, config={align = "cl", padding = 0, minw = 4.5}, nodes={
            {n=G.UIT.C, config={align = "cm", padding = 0.01, r = 0.1, colour = G.C.HAND_LEVELS[math.min(7, args.level)], minw = 1.5, outline = 0.8, outline_colour = G.C.WHITE}, nodes={
                {n=G.UIT.T, config={text = localize('k_level_prefix')..args.level, scale = 0.5, colour = G.C.UI.TEXT_DARK}}
            }},
            {n=G.UIT.C, config={align = "cm", minw = 3.2}, nodes={
                {n=G.UIT.T, config={text = ' '..args.disp_handname, scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
            }}
        }},
        {n=G.UIT.C, config={align = "cm", padding = 0.05, colour = G.C.BLACK, r = 0.1}, nodes={
            {n=G.UIT.C, config={align = "cr", padding = 0.01, r = 0.1, colour = G.C.CHIPS, minw = 1.5, maxw = 1.5}, nodes={
                {n=G.UIT.T, config={text = number_format(args.chips, 1000000), lang = G.LANGUAGES['en-us'], scale = 0.45, colour = G.C.UI.TEXT_LIGHT}},
                {n=G.UIT.B, config={w = 0.08, h = 0.01}}
            }},
            {n=G.UIT.T, config={text = "X", scale = 0.45, colour = G.C.MULT}},
            {n=G.UIT.C, config={align = "cl", padding = 0.01, r = 0.1, colour = G.C.MULT, minw = 1.5, maxw = 1.5}, nodes={
                {n=G.UIT.B, config={w = 0.08, h = 0.01}},
                {n=G.UIT.T, config={text = number_format(args.mult, 1000000), lang = G.LANGUAGES['en-us'], scale = 0.45, colour = G.C.UI.TEXT_LIGHT}}
            }}
        }},
        {n=G.UIT.C, config={align = "cm"}, nodes={{n=G.UIT.B, config = {w = 0.1, h = 0.1}}}},
        {n=G.UIT.C, config={align = "cm", minw = 2.5, maxw = 2.5, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK}, nodes={
            {n=G.UIT.O, config={w = 0.4, h = 0.4, object = get_stake_sprite(G.GAME.stake or 1, 0.5), hover = true, can_collide = false}},
            {n=G.UIT.B, config={w = 0.08, h = 0.01}},
            {n=G.UIT.T, config={text = number_format(args.chip_total, 10000000), lang = G.LANGUAGES['en-us'], scale = 0.5, colour = args.filter and G.C.FILTER or G.C.WHITE, shadow = true}}
        }}
    }}
    return t
end

function create_UIBox_history_hand_tip(args)
    local cardarea = CardArea(2, 2, 3.5*G.CARD_W, 0.75*G.CARD_H, {card_limit = 5, type = 'title', highlight_limit = 0})
    for k, v in ipairs(args.cards) do
        local card = Card(0, 0, G.CARD_W, G.CARD_H, G.P_CENTERS.j_joker, G.P_CENTERS.c_base)
        G.CARD_H = G.CARD_H/2; G.CARD_W = G.CARD_W/2
        card:load(v)
        G.CARD_H = G.CARD_H*2; G.CARD_W = G.CARD_W*2
        if v.score then card:juice_up(0.3, 0.2) end
        if k == 1 then play_sound('paper1',0.95 + math.random()*0.1, 0.3) end
        ease_value(card.T, 'scale', v.score and 0.25 or -0.15, nil, 'REAL', true, 0.2)
        cardarea:emplace(card)
    end
    return {n=G.UIT.R, config={align = "cm", colour = G.C.WHITE, r = 0.1}, nodes={
        {n=G.UIT.C, config={align = "cm"}, nodes={
            {n=G.UIT.O, config={object = cardarea}}
        }}
    }}
end

function create_history_slider(args)
    args = args or {}
    args.colour = args.colour or G.C.BLUE
    args.w = args.w or 1
    args.h = args.h or 0.5
    args.min = args.min or 0
    args.max = args.max or 1
    args.decimal_places = args.decimal_places or 0
    args.text = string.format("%."..tostring(args.decimal_places).."f", args.ref_table[args.ref_value])
    local startval = args.w*(args.ref_table[args.ref_value] - args.min)/(args.max - args.min)
    local t = {n=G.UIT.C, config={align = "cm", minw = args.w, min_h = args.h, padding = 0.1, r = 0.1, colour = G.C.CLEAR, focus_args = {type = 'slider'}}, nodes={
        {n=G.UIT.C, config={align = "cl", minw = args.w, r = 0.1, min_h = args.h, collideable = true, hover = true, colour = G.C.BLACK, emboss = 0.05, func = 'slider', refresh_movement = true}, nodes={
            {n=G.UIT.B, config={w = startval, h = args.h, r = 0.1, colour = args.colour, ref_table = args, refresh_movement = true}},
        }},
    }}
    return t
end

G.FUNCS.ROLL_history_hands = function(e)
    if e.config.object and math.floor(G.GAME.history_hands_long) ~= e.config.id then
        G.current_history = {}
        local minus = 0
        for j = 1, 4 do
            table.insert(G.current_history, create_UIBox_history_hand_row(G.GAME.history_hands[math.floor(G.GAME.history_hands_long)-minus]))
            minus = minus + 1
        end
        e.config.object:remove()
        e.config.object = UIBox{definition = {n=G.UIT.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={{n=G.UIT.R, config={align = "cm", padding = 0.04}, nodes=G.current_history}}}, config = {offset = {x=0,y=0}, parent = e}}
        e.config.id = math.floor(G.GAME.history_hands_long)
    end
end

G.FUNCS.quick_load = function(e)
    if Portable.config.flash_load then
        G:delete_run()
        G.SAVED_GAME = get_compressed(G.SETTINGS.profile..'/'..'save.jkr')
        if G.SAVED_GAME ~= nil then G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME) end
        G:start_run({savetext = G.SAVED_GAME})
    else
        G.FUNCS.exit_overlay_menu()
        G.SAVED_GAME = get_compressed(G.SETTINGS.profile..'/'..'save.jkr')
        if G.SAVED_GAME ~= nil then G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME) end
        G.FUNCS.start_run(nil, {savetext = G.SAVED_GAME})
    end
end

G.FUNCS.to_save = function(e)
    if G.ARGS.save_run then
        G.ARGS.save_run.GAME.load_round = G.GAME.round; G.GAME.load_round = G.GAME.round
        compress_and_save(G.SETTINGS.profile..'/'..'portable.jkr', G.ARGS.save_run)
        play_sound('generic1')
    else
        play_sound('cancel')
    end
    G.FUNCS.exit_overlay_menu()
end

G.FUNCS.to_load = function(e)
    if Portable.config.flash_load then
        G:delete_run()
        G.SAVED_GAME = get_compressed(G.SETTINGS.profile..'/'..'portable.jkr')
        if G.SAVED_GAME ~= nil then G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME) end
        G:start_run({savetext = G.SAVED_GAME})
    else
        G.FUNCS.exit_overlay_menu()
        G.SAVED_GAME = get_compressed(G.SETTINGS.profile..'/'..'portable.jkr')
        if G.SAVED_GAME ~= nil then G.SAVED_GAME = STR_UNPACK(G.SAVED_GAME) end
        G.FUNCS.start_run(nil, {savetext = G.SAVED_GAME})
    end
end

local Game_start_run_ref = Game.start_run
function Game:start_run(args)
    if args.savetext then else love.filesystem.remove(G.SETTINGS.profile..'/'..'portable.jkr') end
    Game_start_run_ref(self, args)
end

function build_manual_save()
    local nodes = {
        simple_text_container("k_manual_save", {colour = G.C.UI.TEXT_LIGHT, scale = 0.5}),
        {n=G.UIT.R, config={align = "cm", minh = 0.2}, nodes={}},
        UIBox_button{ label = {localize('b_save')}, button = "to_save", colour = G.C.BLUE, minw = 2.3, minh = 0.8},
        love.filesystem.getInfo(G.SETTINGS.profile..'/'..'portable.jkr') and UIBox_button{ label = {localize{type = 'variable', key = 'a_load_round', vars = {G.GAME.load_round or 0}}}, button = "to_load", colour = G.C.ORANGE, minw = 2.3, minh = 0.8} or nil,
    }
    return nodes
end

local create_UIBox_options_ref = create_UIBox_options
function create_UIBox_options()
    local t = create_UIBox_options_ref()
    if G.STAGE == G.STAGES.RUN and Portable.config.manual_save then
        t.nodes[1] = {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
            {n=G.UIT.C, config={align = "cm"}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 1,r = 0.3, padding = 0.07, minw = 1, colour = G.C.JOKER_GREY, emboss = 0.1}, nodes={
                    {n=G.UIT.C, config={align = "cm", minh = 1, r = 0.2, padding = 0.2, minw = 1, colour = G.C.L_BLACK}, nodes=build_manual_save()},
                }},
            }},
            {n=G.UIT.C, config={align = "cm"}, nodes={
                t.nodes[1]
            }},
        }}
    end
    return t
end

local Card_generate_UIBox_ability_table_ref = Card.generate_UIBox_ability_table
function Card:generate_UIBox_ability_table(vars_only)
    local ret = Card_generate_UIBox_ability_table_ref(self, vars_only)
    if G.simulate_area or G.SETTINGS.paused or (G.play and #G.play.cards > 0) or (G.CONTROLLER.locked) or (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then else
        local vars = predict_random(self, ret)
        if vars and next(vars) then generate_card_ui({key = 'Preview', set = 'Other', vars = vars}, ret) end
    end
    return ret
end

local Card_stop_hover_ref = Card.stop_hover
function Card:stop_hover()
    Card_stop_hover_ref(self)
    if G.simulate_area then G.simulate_area:remove(); G.simulate_area = nil end
end

local Tag_get_uibox_table_ref = Tag.get_uibox_table
function Tag:get_uibox_table(tag_sprite, vars_only)
    local ret = Tag_get_uibox_table_ref(self, tag_sprite, vars_only)
    if G.simulate_area or G.SETTINGS.paused or (G.play and #G.play.cards > 0) or (G.CONTROLLER.locked) or (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then else
        predict_random(self, ret)
    end
    return ret
end

local Tag_generate_UI_ref = Tag.generate_UI
function Tag:generate_UI(_size)
    local tag_sprite_tab, tag_sprite = Tag_generate_UI_ref(self, _size)
    local tag_sprite_stop_hover_ref = tag_sprite.stop_hover
    tag_sprite.stop_hover = function(_self)
        tag_sprite_stop_hover_ref(_self)
        if G.simulate_area then G.simulate_area:remove(); G.simulate_area = nil end
    end
    return tag_sprite_tab, tag_sprite
end

local Blind_hover_ref = Blind.hover
function Blind:hover()
    Blind_hover_ref(self)
    if G.simulate_area or G.SETTINGS.paused or (G.play and #G.play.cards > 0) or (G.CONTROLLER.locked) or (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then else
        predict_random(self)
    end
end

local Blind_stop_hover_ref = Blind.stop_hover
function Blind:stop_hover()
    Blind_stop_hover_ref(self)
    if G.simulate_area then G.simulate_area:remove(); G.simulate_area = nil end
end

local UIElement_hover_ref = UIElement.hover
function UIElement:hover() 
    UIElement_hover_ref(self)
    if G.simulate_area or G.SETTINGS.paused or (G.play and #G.play.cards > 0) or (G.CONTROLLER.locked) or (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then else
        predict_random(self)
    end
end

local UIElement_stop_hover_ref = UIElement.stop_hover
function UIElement:stop_hover()
    UIElement_stop_hover_ref(self)
    if G.simulate_area then G.simulate_area:remove(); G.simulate_area = nil end
end

local Game_update_ref = Game.update
function Game:update(dt)
    if G.SETTINGS.paused or (G.play and #G.play.cards > 0) or (G.CONTROLLER.locked) or (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then
        if G.simulate_area then G.simulate_area:remove(); G.simulate_area = nil end
    end
    Game_update_ref(self, dt)
end

function shallow_copy(obj)
    local res = {}
    if type(obj) ~= "table" then
        return obj
    end
    for k, v in pairs(obj) do
        res[k] = v
    end
    return res
end

function simulate_create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append, ps)
    G.simulate_area = G.simulate_area or CardArea(-0.83, 5, 2.75*G.CARD_W, 0.5*G.CARD_H, {card_limit = 5, type = 'consumeable', highlight_limit = 0})
    local center = G.P_CENTERS.b_red   
    if G.FTP_LOCKED then soulable = nil end
    if not forced_key and soulable and (not G.GAME.banned_keys['c_soul']) then
        if (_type == 'Tarot' or _type == 'Spectral' or _type == 'Tarot_Planet') and
        not (G.GAME.used_jokers['c_soul'] and not next(find_joker("Showman")))  then
            if pseudorandom('soul_'.._type..G.GAME.round_resets.ante) > 0.997 then
                forced_key = 'c_soul'
            end
        end
        if (_type == 'Planet' or _type == 'Spectral') and
        not (G.GAME.used_jokers['c_black_hole'] and not next(find_joker("Showman")))  then 
            if pseudorandom('soul_'.._type..G.GAME.round_resets.ante) > 0.997 then
                forced_key = 'c_black_hole'
            end
        end
    end
    if _type == 'Base' then 
        forced_key = 'c_base'
    end
    if forced_key and not G.GAME.banned_keys[forced_key] then 
        center = G.P_CENTERS[forced_key]
        _type = (center.set ~= 'Default' and center.set or _type)
    else
        local _pool, _pool_key = get_current_pool(_type, _rarity, legendary, key_append)
        center = pseudorandom_element(_pool, pseudoseed(_pool_key))
        local it = 1
        while center == 'UNAVAILABLE' do
            it = it + 1
            center = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
        end
        center = G.P_CENTERS[center]
    end
    local front = ((_type == 'Base' or _type == 'Enhanced') and pseudorandom_element(G.P_CARDS, pseudoseed('front'..(key_append or '')..G.GAME.round_resets.ante))) or nil
    local card = Card(G.simulate_area.T.x + G.simulate_area.T.w/2, G.simulate_area.T.y, G.CARD_W/2, G.CARD_H/2, front, center)
    if card.ability.consumeable and not skip_materialize then card:start_materialize() end
    if _type == 'Joker' then
        if G.GAME.modifiers.all_eternal then
            card:set_eternal(true)
        end
        if (ps == 'shop') or (ps == 'pack') then
            local eternal_perishable_poll = pseudorandom((ps == 'pack' and 'packetper' or 'etperpoll')..G.GAME.round_resets.ante)
            if G.GAME.modifiers.enable_eternals_in_shop and eternal_perishable_poll > 0.7 then
                card:set_eternal(true)
            elseif G.GAME.modifiers.enable_perishables_in_shop and ((eternal_perishable_poll > 0.4) and (eternal_perishable_poll <= 0.7)) then
                card:set_perishable(true)
            end
            if G.GAME.modifiers.enable_rentals_in_shop and pseudorandom((ps == 'pack' and 'packssjr' or 'ssjr')..G.GAME.round_resets.ante) > 0.7 then
                card:set_rental(true)
            end
        end
        local edition = poll_edition('edi'..(key_append or '')..G.GAME.round_resets.ante)
        card:simulate_set_edition(edition)
    end
    G.simulate_area:emplace(card)
    return card
end

function simulate_copy_card(other, greyed, card_scale, playing_card, strip_edition)
    G.simulate_area = G.simulate_area or CardArea(-0.83, 5, 2.75*G.CARD_W, 0.5*G.CARD_H, {card_limit = 5, type = 'consumeable', highlight_limit = 0})
    local new_card = Card(G.simulate_area.T.x+G.simulate_area.T.w/2, G.simulate_area.T.y, G.CARD_W*0.5, G.CARD_H*0.5, G.P_CARDS.empty, G.P_CENTERS.c_base)
    remove_all(new_card.children)
    new_card.children = {}
    new_card.children.shadow = Moveable(0, 0, 0, 0)
    new_card:set_ability(other.config.center)
    new_card.ability.type = other.ability.type
    new_card:set_base(other.config.card)
    for k, v in pairs(other.ability) do
        if type(v) == 'table' then 
            new_card.ability[k] = copy_table(v)
        else
            new_card.ability[k] = v
        end
    end
    if not strip_edition then 
        new_card:simulate_set_edition(other.edition or {}, nil, true)
    end
    new_card:simulate_set_seal(other.seal, true)
    new_card.debuff = other.debuff
    new_card.greyed = greyed
    G.simulate_area:emplace(new_card)
    return new_card
end

function simulate_create_playing_card(card_init, area, skip_materialize, silent, colours)
    G.simulate_area = G.simulate_area or CardArea(-0.83, 5, 2.75*G.CARD_W, 0.5*G.CARD_H, {card_limit = 5, type = 'consumeable', highlight_limit = 0})
    card_init = card_init or {}
    card_init.front = card_init.front or pseudorandom_element(G.P_CARDS, pseudoseed('front'))
    if card_init.empty then card_init.front = G.P_CARDS.empty end
    card_init.center = card_init.center or G.P_CENTERS.c_base
    local card = Card(G.simulate_area.T.x+G.simulate_area.T.w/2, G.simulate_area.T.y, G.CARD_W/2, G.CARD_H/2, card_init.front, card_init.center)
    card.debuff = card_init.debuff
    if not skip_materialize then card:start_materialize(colours, silent) end
    G.simulate_area:emplace(card)
    return card
end

function simulate_create_blind(key)
    G.simulate_area = G.simulate_area or CardArea(-0.83, 5, 2.75*G.CARD_W, 0.5*G.CARD_H, {card_limit = 5, type = 'consumeable', highlight_limit = 0})
    local center = G.P_BLINDS[key]
    local temp_blind = AnimatedSprite(G.simulate_area.T.x+G.simulate_area.T.w/2, G.simulate_area.T.y, G.CARD_W/2, G.CARD_W/2, G.ANIMATION_ATLAS[center.atlas or 'blind_chips'], center.pos)
    local card = Card(G.simulate_area.T.x+G.simulate_area.T.w/2, G.simulate_area.T.y, G.CARD_W/2, G.CARD_W/2, G.P_CARDS.empty, G.P_CENTERS.c_base)
    card.children.center = temp_blind
    card.config.blind = center
    temp_blind:set_role({major = card, role_type = 'Glued', draw_major = card})
    temp_blind:define_draw_steps({{shader = 'dissolve', shadow_height = 0.05}, {shader = 'dissolve'}})
    temp_blind.float = true
    card.set_sprites = function(...)
        local c = card.children.center
        Card.set_sprites(...)
        card.children.center = c
    end
    G.simulate_area:emplace(card)
    return card
end

function Card:simulate_set_seal(_seal, silent, immediate)
    self.seal = nil
    if _seal then self.seal = _seal end
end

function Card:simulate_set_edition(edition, immediate, silent, delay)
    self:set_edition(edition, true, true, delay)
end

function predict_random(card)
    if not Portable.config.predict_random then return end
    local temp_p = shallow_copy(G.GAME.pseudorandom)
    local temp_b = shallow_copy(G.GAME.bosses_used)
    local temp_j = shallow_copy(G.GAME.used_jokers)
    local temp_v = shallow_copy(G.GAME.used_vouchers)
    local vars = {}
    if G.jokers and card.ability then
        if card.ability.name == "8 Ball" and Portable.config.predict_random_bonus then
            for i = 1, 5 do
                if pseudorandom("8ball") < G.GAME.probabilities.normal/card.ability.extra then
                    simulate_create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "8ba")
                else
                    simulate_copy_card(card, true)
                end
            end
        elseif card.ability.name == "Misprint" and Portable.config.predict_random_bonus then
            local _mult = pseudorandom("misprint", card.ability.extra.min, card.ability.extra.max)
            vars[#vars + 1] = "+".._mult
        elseif card.ability.name == "Gros Michel" and Portable.config.predict_random_bonus then
            if pseudorandom("gros_michel") < G.GAME.probabilities.normal/card.ability.extra.odds then
                simulate_copy_card(card, true)
            else
                simulate_copy_card(card)
            end
        elseif card.ability.name == "Business Card" and Portable.config.predict_random_bonus then
            for i = 1, 5 do
                if pseudorandom("business") < G.GAME.probabilities.normal/card.ability.extra then
                    simulate_copy_card(card)
                else
                    simulate_copy_card(card, true)
                end
            end
        elseif card.ability.name == "Space Joker" then
            if pseudorandom("space") < G.GAME.probabilities.normal/card.ability.extra then
                simulate_copy_card(card)
            else
                simulate_copy_card(card, true)
            end
        elseif card.ability.name == "Sixth Sense" and Portable.config.predict_random_bonus then
            simulate_create_card('Spectral', G.consumeables, nil, nil, nil, nil, nil, 'sixth')
        elseif card.ability.name == "Superposition" and Portable.config.predict_random_bonus then
            simulate_create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "sup")
        elseif card.ability.name == "To Do List" and Portable.config.predict_random_bonus then
            local _poker_hands = {}
            for k, v in pairs(G.GAME.hands) do
                if v.visible and k ~= card.ability.to_do_poker_hand then _poker_hands[#_poker_hands+1] = k end
            end
            local _hand = pseudorandom_element(_poker_hands, pseudoseed('to_do'))
            vars[#vars + 1] = localize(_hand, 'poker_hands')
        elseif card.ability.name == "Cavendish" and Portable.config.predict_random_bonus then
            if pseudorandom('cavendish') < G.GAME.probabilities.normal/card.ability.extra.odds then
                simulate_copy_card(card, true)
            else
                simulate_copy_card(card)
            end
        elseif card.ability.name == "Madness" and Portable.config.predict_random_bonus then
            local destructable_jokers = {}
            for i = 1, #G.jokers.cards do
                if G.jokers.cards[i] ~= card and not G.jokers.cards[i].ability.eternal and not G.jokers.cards[i].getting_sliced then destructable_jokers[#destructable_jokers + 1] = G.jokers.cards[i] end
            end
            local joker_to_destroy = #destructable_jokers > 0 and pseudorandom_element(destructable_jokers, pseudoseed('madness')) or nil
            if joker_to_destroy then simulate_copy_card(joker_to_destroy) end
        elseif card.ability.name == "Seance" and Portable.config.predict_random_bonus then
            simulate_create_card('Spectral', G.consumeables, nil, nil, nil, nil, nil, 'sea')
        elseif card.ability.name == "Riff-raff" and Portable.config.predict_random_bonus then
            for i = 1, 2 do
                simulate_create_card('Joker', G.jokers, nil, 0, nil, nil, nil, 'rif')
            end
        elseif card.ability.name == "Vagabond" and Portable.config.predict_random_bonus then
            simulate_create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'vag')
        elseif card.ability.name == "Reserved Parking" and Portable.config.predict_random_bonus then
            for i = 1, 5 do
                if pseudorandom('parking') < G.GAME.probabilities.normal/card.ability.extra.odds then
                    simulate_copy_card(card)
                else
                    simulate_copy_card(card, true)
                end
            end
        elseif card.ability.name == "Mail-In Rebate" and Portable.config.predict_random_bonus then
            local valid_mail_cards = {}
            for k, v in ipairs(G.playing_cards) do
                if v.ability.effect ~= 'Stone Card' then
                    valid_mail_cards[#valid_mail_cards + 1] = v
                end
            end
            if valid_mail_cards[1] then
                local mail_card = pseudorandom_element(valid_mail_cards, pseudoseed('mail'..G.GAME.round_resets.ante))
                vars[#vars + 1] = localize(mail_card.base.value, 'ranks')
            end
        elseif card.ability.name == "Hallucination" and Portable.config.predict_random_bonus then
            if pseudorandom('halu'..G.GAME.round_resets.ante) < G.GAME.probabilities.normal/card.ability.extra then
                simulate_create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'hal')
            else
                simulate_copy_card(card, true)
            end
        elseif card.ability.name == "Ancient Joker" and Portable.config.predict_random_bonus then
            local ancient_suits = {}
            for k, v in ipairs({'Spades','Hearts','Clubs','Diamonds'}) do
                if v ~= G.GAME.current_round.ancient_card.suit then ancient_suits[#ancient_suits + 1] = v end
            end
            local ancient_card = pseudorandom_element(ancient_suits, pseudoseed('anc'..G.GAME.round_resets.ante))
            vars[#vars + 1] = localize(ancient_card, 'suits_singular')
        elseif card.ability.name == "Castle" and Portable.config.predict_random_bonus then
            local valid_castle_cards = {}
            for k, v in ipairs(G.playing_cards) do
                if v.ability.effect ~= 'Stone Card' then
                    valid_castle_cards[#valid_castle_cards + 1] = v
                end
            end
            if valid_castle_cards[1] then
                local castle_card = pseudorandom_element(valid_castle_cards, pseudoseed('cas'..G.GAME.round_resets.ante))
                vars[#vars + 1] = localize(castle_card.base.suit, 'suits_singular')
            end
        elseif card.ability.name == "Certificate" and Portable.config.predict_random_bonus then
            local _card = simulate_create_playing_card({front = pseudorandom_element(G.P_CARDS, pseudoseed('cert_fr')), center = G.P_CENTERS.c_base}, G.hand, nil, nil, {G.C.SECONDARY_SET.Enhanced})
            _card:simulate_set_seal(SMODS.poll_seal({type_key = 'certsl', guaranteed = true}), nil, true)
        elseif card.ability.name == "Bloodstone" and Portable.config.predict_random_bonus then
            for i = 1, 5 do
                if pseudorandom('bloodstone') < G.GAME.probabilities.normal/card.ability.extra.odds then
                    simulate_copy_card(card)
                else
                    simulate_copy_card(card, true)
                end
            end
        elseif card.ability.name == "The Idol" and Portable.config.predict_random_bonus then
            local valid_idol_cards = {}
            for k, v in ipairs(G.playing_cards) do
                if v.ability.effect ~= 'Stone Card' then
                    valid_idol_cards[#valid_idol_cards+1] = v
                end
            end
            if valid_idol_cards[1] then
                local idol_card = pseudorandom_element(valid_idol_cards, pseudoseed('idol'..G.GAME.round_resets.ante))
                vars[#vars + 1] = localize(idol_card.base.suit, 'suits_plural').." "..localize(idol_card.base.value, 'ranks')
            end
        elseif card.ability.name == "Invisible Joker" then
            local jokers = {}
            for i=1, #G.jokers.cards do 
                if G.jokers.cards[i] ~= card then
                    jokers[#jokers+1] = G.jokers.cards[i]
                end
            end
            local chosen_joker = #jokers > 0 and pseudorandom_element(jokers, pseudoseed('invisible')) or nil
            if chosen_joker then simulate_copy_card(chosen_joker) end
        elseif card.ability.name == "Cartomancer" and Portable.config.predict_random_bonus then
            simulate_create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'car')
        elseif card.ability.name == "Perkeo" and Portable.config.predict_random_bonus then
            if G.consumeables.cards[1] then
                local copy_card = pseudorandom_element(G.consumeables.cards, pseudoseed('perkeo'))
                simulate_copy_card(copy_card)
            end
        elseif card.ability.name == "The High Priestess" then
            local _cards = {}
            for i = 1, 2 do
                simulate_create_card('Planet', G.consumeables, nil, nil, nil, nil, nil, 'pri')
            end
        elseif card.ability.name == "The Emperor" then
            local _cards = {}
            for i = 1, 2 do
                simulate_create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'emp')
            end
        elseif card.ability.name == "The Wheel of Fortune" then
            if pseudorandom('wheel_of_fortune') < G.GAME.probabilities.normal/card.ability.extra then
                if card.eligible_strength_jokers[1] then
                    local eligible_card = pseudorandom_element(card.eligible_strength_jokers, pseudoseed('wheel_of_fortune'))
                    local _card = simulate_copy_card(eligible_card)
                    local edition = poll_edition('wheel_of_fortune', nil, true, true)
                    _card:simulate_set_edition(edition, true)
                end
            else
                simulate_copy_card(card, true)
            end
        elseif card.ability.name == "Judgement" then
            simulate_create_card('Joker', G.jokers, nil, nil, nil, nil, nil, 'jud')
        elseif card.ability.name == "Familiar" then--
            local destroyed_cards = {}
            destroyed_cards[#destroyed_cards+1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
            for i = #destroyed_cards, 1, -1 do
                simulate_copy_card(destroyed_cards[i], true)
            end
            for i = 1, card.ability.extra do
                local _suit = pseudorandom_element(SMODS.Suits, pseudoseed('familiar_create')).card_key
                local _rank = pseudorandom_element({'J', 'Q', 'K'}, pseudoseed('familiar_create'))
                local cen_pool = {}
                for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                    if v.key ~= 'm_stone' then 
                        cen_pool[#cen_pool+1] = v
                    end
                end
                simulate_create_playing_card({front = G.P_CARDS[_suit..'_'.._rank], center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))}, G.hand, nil, i ~= 1, {G.C.SECONDARY_SET.Spectral})
            end
        elseif card.ability.name == "Grim" then--
            local destroyed_cards = {}
            destroyed_cards[#destroyed_cards+1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
            for i = #destroyed_cards, 1, -1 do
                simulate_copy_card(destroyed_cards[i], true)
            end
            for i = 1, card.ability.extra do
                local _rank = 'A'
                local _suit = pseudorandom_element(SMODS.Suits, pseudoseed('grim_create')).card_key
                local cen_pool = {}
                for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                    if v.key ~= 'm_stone' then 
                        cen_pool[#cen_pool+1] = v
                    end
                end
                simulate_create_playing_card({front = G.P_CARDS[_suit..'_'.._rank], center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))}, G.hand, nil, i ~= 1, {G.C.SECONDARY_SET.Spectral})
            end
        elseif card.ability.name == "Incantation" then--
            local destroyed_cards = {}
            destroyed_cards[#destroyed_cards+1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
            for i = #destroyed_cards, 1, -1 do
                simulate_copy_card(destroyed_cards[i], true)
            end
            for i = 1, card.ability.extra do
                local _suit = pseudorandom_element(SMODS.Suits, pseudoseed('incantation_create')).card_key
                local _rank = pseudorandom_element({'2', '3', '4', '5', '6', '7', '8', '9', 'T'}, pseudoseed('incantation_create'))
                local cen_pool = {}
                for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                    if v.key ~= 'm_stone' then 
                        cen_pool[#cen_pool+1] = v
                    end
                end
                simulate_create_playing_card({front = G.P_CARDS[_suit..'_'.._rank], center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))}, G.hand, nil, i ~= 1, {G.C.SECONDARY_SET.Spectral})
            end
        elseif card.ability.name == "Aura" then
            local edition = poll_edition('aura', nil, true, true)
            local aura_card = simulate_create_playing_card({front = G.P_CARDS.empty, center = G.P_CENTERS.c_base, empty = true})
            aura_card:simulate_set_edition(edition, true)
        elseif card.ability.name == "Wraith" then
            simulate_create_card('Joker', G.jokers, nil, 0.99, nil, nil, nil, 'wra')
        elseif card.ability.name == "Sigil" then--
            local _suit = pseudorandom_element(SMODS.Suits, pseudoseed('sigil')).card_key
            local _rank = "A"
            simulate_create_playing_card({front = G.P_CARDS[_suit..'_'.._rank], center = G.P_CENTERS.c_base})
        elseif card.ability.name == "Ouija" then
            local _suit = "S"
            local _rank = pseudorandom_element({'2','3','4','5','6','7','8','9','T','J','Q','K','A'}, pseudoseed('ouija'))
            simulate_create_playing_card({front = G.P_CARDS[_suit..'_'.._rank], center = G.P_CENTERS.c_base})
        elseif card.ability.name == "Ectoplasm" then
            if card.eligible_editionless_jokers[1] then
                local eligible_card = pseudorandom_element(card.eligible_editionless_jokers, pseudoseed('ectoplasm'))
                simulate_copy_card(eligible_card)
            end
        elseif card.ability.name == "Immolate" then
            local destroyed_cards = {}
            local temp_hand = {}
            for k, v in ipairs(G.hand.cards) do temp_hand[#temp_hand+1] = v end
            table.sort(temp_hand, function (a, b) return not a.playing_card or not b.playing_card or a.playing_card < b.playing_card end)
            pseudoshuffle(temp_hand, pseudoseed('immolate'))
            for i = 1, card.ability.extra.destroy do destroyed_cards[#destroyed_cards+1] = temp_hand[i] end
            for i = #destroyed_cards, 1, -1 do
                simulate_copy_card(destroyed_cards[i])
            end
        elseif card.ability.name == "Ankh" then
            local chosen_joker = pseudorandom_element(G.jokers.cards, pseudoseed('ankh_choice'))
            if chosen_joker then simulate_copy_card(chosen_joker) end
        elseif card.ability.name == "Hex" then
            if card.eligible_editionless_jokers[1] then
                local eligible_card = pseudorandom_element(card.eligible_editionless_jokers, pseudoseed('hex'))
                simulate_copy_card(eligible_card)
            end
        elseif card.ability.name == "The Soul" then
            simulate_create_card('Joker', G.jokers, true, nil, nil, nil, nil, 'sou')
        elseif card.ability.name == "Glass Card" then
            for i = 1, 5 do
                if pseudorandom('glass') < G.GAME.probabilities.normal/card.ability.extra then
                    simulate_copy_card(card, true)
                else
                    simulate_copy_card(card)
                end
            end
        elseif card.ability.name == "Lucky Card" then
            for i = 1, 5 do
                local _mult = nil
                local _money = nil
                if pseudorandom('lucky_mult') < G.GAME.probabilities.normal/5 then _mult = true end
                if pseudorandom('lucky_money') < G.GAME.probabilities.normal/15 then _money = true end
                local _card = simulate_create_playing_card({front = G.P_CARDS.empty, center = _mult and G.P_CENTERS.m_mult or G.P_CENTERS.c_base, empty = true})
                if _money then _card:simulate_set_seal('Gold', true) end
            end
        elseif ((card.ability.name == "Arcana Pack" or card.ability.name == "Jumbo Arcana Pack" or card.ability.name == "Mega Arcana Pack") or card.name == "Charm Tag") and Portable.config.predict_random_bonus then
            local _extra = card.name == "Charm Tag" and G.P_CENTERS.p_arcana_mega_1.config.extra or card.ability.extra
            for i = 1, _extra do
                if G.GAME.used_vouchers.v_omen_globe and pseudorandom('omen_globe') > 0.8 then
                    simulate_create_card("Spectral", G.pack_cards, nil, nil, true, true, nil, 'ar2')
                else
                    simulate_create_card("Tarot", G.pack_cards, nil, nil, true, true, nil, 'ar1')
                end
            end
        elseif ((card.ability.name == "Celestial Pack" or card.ability.name == "Jumbo Celestial Pack" or card.ability.name == "Mega Celestial Pack") or card.name == "Meteor Tag") and Portable.config.predict_random_bonus then
            local _extra = card.name == "Meteor Tag" and G.P_CENTERS.p_celestial_mega_1.config.extra or card.ability.extra
            for i = 1, _extra do
                if G.GAME.used_vouchers.v_telescope and i == 1 then
                    local _planet, _hand, _tally = nil, nil, 0
                    for k, v in ipairs(G.handlist) do
                        if G.GAME.hands[v].visible and G.GAME.hands[v].played > _tally then
                            _hand = v
                            _tally = G.GAME.hands[v].played
                        end
                    end
                    if _hand then
                        for k, v in pairs(G.P_CENTER_POOLS.Planet) do
                            if v.config.hand_type == _hand then
                                _planet = v.key
                            end
                        end
                    end
                    simulate_create_card("Planet", G.pack_cards, nil, nil, true, true, _planet, 'pl1')
                else
                    simulate_create_card("Planet", G.pack_cards, nil, nil, true, true, nil, 'pl1')
                end
            end
        elseif ((card.ability.name == "Spectral Pack" or card.ability.name == "Jumbo Spectral Pack" or card.ability.name == "Mega Spectral Pack") or card.name == "Ethereal Tag") and Portable.config.predict_random_bonus then
            local _extra = card.name == "Ethereal Tag" and G.P_CENTERS.p_spectral_normal_1.config.extra or card.ability.extra
            for i = 1, _extra do
                simulate_create_card("Spectral", G.pack_cards, nil, nil, true, true, nil, 'spe')
            end
        elseif ((card.ability.name == "Standard Pack" or card.ability.name == "Jumbo Standard Pack" or card.ability.name == "Mega Standard Pack") or card.name == "Standard Tag") and Portable.config.predict_random_bonus then
            local _extra = card.name == "Standard Tag" and G.P_CENTERS.p_standard_mega_1.config.extra or card.ability.extra
            for i = 1, _extra do
                local _card = simulate_create_card((pseudorandom(pseudoseed('stdset'..G.GAME.round_resets.ante)) > 0.6) and "Enhanced" or "Base", G.pack_cards, nil, nil, nil, true, nil, 'sta')
                local edition_rate = 2
                local edition = poll_edition('standard_edition'..G.GAME.round_resets.ante, edition_rate, true)
                _card:simulate_set_edition(edition)
                _card:simulate_set_seal(SMODS.poll_seal({mod = 10}), true, true)
            end
        elseif ((card.ability.name == "Buffoon Pack" or card.ability.name == "Jumbo Buffoon Pack" or card.ability.name == "Mega Buffoon Pack") or card.name == "Buffoon Tag") and Portable.config.predict_random_bonus then
            local _extra = card.name == "Buffoon Tag" and G.P_CENTERS.p_buffoon_mega_1.config.extra or card.ability.extra
            for i = 1, _extra do
                simulate_create_card("Joker", G.pack_cards, nil, nil, true, true, nil, 'buf', 'pack')
            end
        elseif card.name == "Uncommon Tag" and Portable.config.predict_random_bonus then
            simulate_create_card('Joker', G.shop_jokers, nil, 0.9, nil, nil, nil, 'uta', 'shop')
        elseif card.name == "Rare Tag" and Portable.config.predict_random_bonus then
            local rares_in_posession = {0}
            for k, v in ipairs(G.jokers.cards) do
                if v.config.center.rarity == 3 and not rares_in_posession[v.config.center.key] then
                    rares_in_posession[1] = rares_in_posession[1] + 1 
                    rares_in_posession[v.config.center.key] = true
                end
            end
            if #G.P_JOKER_RARITY_POOLS[3] > rares_in_posession[1] then
                simulate_create_card('Joker', G.shop_jokers, nil, 1, nil, nil, nil, 'rta', 'shop')
            end
        elseif card.name == "Top-up Tag" and Portable.config.predict_random_bonus then
            for i = 1, card.config.spawn_jokers do
                simulate_create_card('Joker', G.jokers, nil, 0, nil, nil, nil, 'top')
            end
        elseif card.name == "Boss Tag" and Portable.config.predict_random_bonus then
            simulate_create_blind(get_new_boss())
        elseif card.name == "Voucher Tag" and Portable.config.predict_random_bonus then
            for _, v in ipairs(G.GAME.current_round.voucher or {}) do
                G.GAME.used_vouchers[v] = true
            end
            G.simulate_area = G.simulate_area or CardArea(-0.83, 5, 2.75*G.CARD_W, 0.5*G.CARD_H, {card_limit = 5, type = 'consumeable', highlight_limit = 0})
            local voucher_key = get_next_voucher_key(true)
            local _card = Card(G.simulate_area.T.x+G.simulate_area.T.w/2, G.simulate_area.T.y, G.CARD_W/2, G.CARD_H/2, G.P_CARDS.empty, G.P_CENTERS[voucher_key])
            _card:start_materialize()
            G.simulate_area:emplace(_card)
        end
        if card.seal == "Purple" and Portable.config.predict_random_bonus then
            for i = 1, 3 do
                simulate_create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "8ba")
            end
        end
    elseif G.jokers then
        if card.name == "The Hook" and Portable.config.predict_random_bonus then
            local _cards = {}
            for k, v in ipairs(G.hand.cards) do
                if v.highlighted then else
                    _cards[#_cards+1] = v
                end
            end
            local _extra = math.min(2, #_cards)
            for i = 1, _extra do
                local selected_card, card_key = pseudorandom_element(_cards, pseudoseed('hook'))
                simulate_copy_card(selected_card)
                table.remove(_cards, card_key)
            end
        elseif card.name == "Crimson Heart" and Portable.config.predict_random_bonus then
            local jokers = {}
            for i = 1, #G.jokers.cards do
                if not G.jokers.cards[i].debuff or #G.jokers.cards < 2 then jokers[#jokers+1] = G.jokers.cards[i] end
            end
            if jokers[1] then
                local _card = pseudorandom_element(jokers, pseudoseed('crimson_heart'))
                simulate_copy_card(_card)
            end
        elseif card.config and card.config.button == "reroll_boss" and Portable.config.predict_random_bonus then
            simulate_create_blind(get_new_boss())
        elseif card.config and card.config.button == "reroll_shop" and Portable.config.predict_random_bonus then
            for i = #G.shop_jokers.cards, 1, -1 do
                if not next(SMODS.find_card(G.shop_jokers.cards[i].config.center.key, true)) then
                    G.GAME.used_jokers[G.shop_jokers.cards[i].config.center.key] = nil
                end
            end
            for i = 1, G.GAME.shop.joker_max do
                G.GAME.spectral_rate = G.GAME.spectral_rate or 0
                local total_rate = G.GAME.joker_rate + G.GAME.playing_card_rate
                for _, v in ipairs(SMODS.ConsumableType.ctype_buffer) do
                    total_rate = total_rate + G.GAME[v:lower()..'_rate']
                end
                local polled_rate = pseudorandom(pseudoseed('cdt'..G.GAME.round_resets.ante))*total_rate
                local check_rate = 0
                local rates = {
                    {type = 'Joker', val = G.GAME.joker_rate},
                    {type = 'Tarot', val = G.GAME.tarot_rate},
                    {type = 'Planet', val = G.GAME.planet_rate},
                    {type = (G.GAME.used_vouchers["v_illusion"] and pseudorandom(pseudoseed('illusion')) > 0.6) and 'Enhanced' or 'Base', val = G.GAME.playing_card_rate},
                    {type = 'Spectral', val = G.GAME.spectral_rate},
                }
                for _, v in ipairs(SMODS.ConsumableType.ctype_buffer) do
                    if not (v == 'Tarot' or v == 'Planet' or v == 'Spectral') then
                        table.insert(rates, {type = v, val = G.GAME[v:lower()..'_rate']})
                    end
                end
                for _, v in ipairs(rates) do
                    if polled_rate > check_rate and polled_rate <= check_rate + v.val then
                        local _card = simulate_create_card(v.type, G.shop_jokers, nil, nil, nil, nil, nil, 'sho', 'shop')
                        if (v.type == 'Base' or v.type == 'Enhanced') and G.GAME.used_vouchers["v_illusion"] and pseudorandom(pseudoseed('illusion')) > 0.8 then
                            _card:set_seal(SMODS.poll_seal({guaranteed = true, type_key = 'certsl'}))
                        end
                        if (v.type == 'Base' or v.type == 'Enhanced') and G.GAME.used_vouchers["v_illusion"] and pseudorandom(pseudoseed('illusion')) > 0.8 then 
                            _card:set_edition(poll_edition('illusion', nil, true, true))
                        end
                        break
                    end
                    check_rate = check_rate + v.val
                end
            end
        end
    end
    G.GAME.pseudorandom = temp_p
    G.GAME.bosses_used = temp_b
    G.GAME.used_jokers = temp_j
    G.GAME.used_vouchers = temp_v
    return vars
end

local Game_start_run_ref = Game.start_run
function Game:start_run(args)
    Game_start_run_ref(self, args)
    self.GAME.preview = {
        chip_target = 0,
        chip_trans = 0,
        chip_delta = 0,
        chip = 0,
        chip_text = '',
        dollar_target = 0,
        dollar_trans = 0,
        dollar_tran = 0,
        dollar_delta = 0,
        dollar = 0,
        dollar_text = ''
    }
    self.PHUD = UIBox{
        definition = {n=G.UIT.ROOT, config = {align = 'cm', minw = 0.001, minh = 0.001, padding = 0.03, r = 0.1, colour = copy_table(G.C.CLEAR)}, nodes={
            {n=G.UIT.T, config={ref_table = G.GAME.preview, ref_value = 'chip_text', lang = G.LANGUAGES['en-us'], scale = 0.9, colour = G.C.WHITE, id = 'preview_chip_UI', func = 'preview_chip_UI_set', shadow = true}},
            {n=G.UIT.T, config={ref_table = G.GAME.preview, ref_value = 'dollar_text', lang = G.LANGUAGES['en-us'], scale = 0.9, colour = G.C.MONEY, id = 'preview_dollar_UI', func = 'preview_dollar_UI_set', shadow = true}},
        }},
        config = {align = 'cm', offset = {x=0, y=-2.7}, major = G.play}
    }
end

local Game_delete_run_ref = Game.delete_run
function Game:delete_run()
    Game_delete_run_ref(self)
    if self.PHUD then self.PHUD:remove(); self.PHUD = nil end
end

G.FUNCS.preview_chip_UI_set = function(e)
    if G.GAME.preview.chip < 1 then
        G.GAME.preview.chip_text = ''
    else
        local new_preview_chip_text = number_format(G.GAME.preview.chip)
        if G.GAME.preview.chip_text ~= new_preview_chip_text then
            --e.config.scale = math.min(0.8, scale_number(G.GAME.chips, 1.2))
            e.config.colour = (G.GAME.chips + G.GAME.preview.chip_target >= G.GAME.blind.chips) and G.C.FILTER or G.C.WHITE
            G.GAME.preview.chip_text = new_preview_chip_text
        end
    end
end

G.FUNCS.preview_dollar_UI_set = function(e)
    if G.GAME.preview.dollar == 0 then
        G.GAME.preview.dollar_text = ''
    else
        local new_preview_dollar_text = ' '..localize('$')..number_format(G.GAME.preview.dollar)
        if G.GAME.preview.dollar_text ~= new_preview_dollar_text then
            --e.config.scale = math.min(0.8, scale_number(G.GAME.chips, 1.2))
            e.config.colour = G.GAME.preview.dollar_target > 0 and G.C.MONEY or G.C.RED
            G.GAME.preview.dollar_text = new_preview_dollar_text
        end
    end
end

function update_preview(dt)
    if G.GAME and G.GAME.preview and G.GAME.preview.chip ~= G.GAME.preview.chip_target then
        if G.GAME.preview.chip_trans ~= G.GAME.preview.chip_target then
            G.GAME.preview.chip_trans = G.GAME.preview.chip_target
            G.GAME.preview.chip_delta = (G.GAME.preview.chip_trans - G.GAME.preview.chip)*(G.SETTINGS.GAMESPEED or 1)
        end
        if G.GAME.preview.chip_delta > 0 then
            G.GAME.preview.chip = math.floor(G.GAME.preview.chip + math.max(G.GAME.preview.chip_delta*dt, 1))
            if G.GAME.preview.chip > G.GAME.preview.chip_target then G.GAME.preview.chip = G.GAME.preview.chip_target end
        else
            G.GAME.preview.chip = math.ceil(G.GAME.preview.chip + math.min(G.GAME.preview.chip_delta*dt, -1))
            if G.GAME.preview.chip < G.GAME.preview.chip_target then G.GAME.preview.chip = G.GAME.preview.chip_target end
        end
    end
    if G.GAME and G.GAME.preview and G.GAME.preview.dollar ~= G.GAME.preview.dollar_target then
        if G.GAME.preview.dollar_trans ~= G.GAME.preview.dollar_target then
            G.GAME.preview.dollar_trans = G.GAME.preview.dollar_target
            G.GAME.preview.dollar_delta = (G.GAME.preview.dollar_trans - G.GAME.preview.dollar)*(G.SETTINGS.GAMESPEED or 1)
        end
        if G.GAME.preview.dollar_delta > 0 then
            G.GAME.preview.dollar = math.floor(G.GAME.preview.dollar + math.max(G.GAME.preview.dollar_delta*dt, 1))
            if G.GAME.preview.dollar > G.GAME.preview.dollar_target then G.GAME.preview.dollar = G.GAME.preview.dollar_target end
        else
            G.GAME.preview.dollar = math.ceil(G.GAME.preview.dollar + math.min(G.GAME.preview.dollar_delta*dt, -1))
            if G.GAME.preview.dollar < G.GAME.preview.dollar_target then G.GAME.preview.dollar = G.GAME.preview.dollar_target end
        end
    end
end

local G_FUNCS_draw_from_play_to_discard_ref = G.FUNCS.draw_from_play_to_discard
G.FUNCS.draw_from_play_to_discard = function(e)
    G_FUNCS_draw_from_play_to_discard_ref(e)
    G.E_MANAGER:add_event(Event({func = function() G.GAME.preview.chip_target = 0; G.GAME.preview.dollar_target = 0 return true end}))
end

local ease_dollars_ref = ease_dollars
function ease_dollars(mod, instant)
    ease_dollars_ref(mod, instant)
    G.GAME.preview.dollar_tran = G.GAME.preview.dollar_tran + mod
end

local G_FUNCS_play_cards_from_highlighted = G.FUNCS.play_cards_from_highlighted
G.FUNCS.play_cards_from_highlighted = function(e)
    G_FUNCS_play_cards_from_highlighted(e)
end

----------------------------------------------
------------MOD CODE END----------------------