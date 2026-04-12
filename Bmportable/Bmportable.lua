--- STEAMODDED HEADER
--- MOD_NAME: Bmportable
--- MOD_ID: Bmportable
--- MOD_AUTHOR: [BaiMao Brookling]
--- MOD_DESCRIPTION: More convenient function and information
--- BADGE_COLOUR: 366999
--- VERSION: 1.0.1q
----------------------------------------------
------------MOD CODE -------------------------

Portable = SMODS.current_mod

Portable.update = {
    dollar_UI = false,
    discard_UI = false,
    hand_UI = false
}

Portable.config_tab = function()
    return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
        create_toggle({label = localize("k_misprint_display"), ref_table = Portable.config, ref_value = "misprint_display"}),
        create_toggle({label = localize("k_flip_sort"), ref_table = Portable.config, ref_value = "flip_sort"}),
        create_toggle({label = localize("k_predict_random"), ref_table = Portable.config, ref_value = "predict_random"}),
        create_toggle({label = localize("k_predict_random_bonus"), ref_table = Portable.config, ref_value = "predict_random_bonus"}),
        create_toggle({label = localize("k_flash_load"), ref_table = Portable.config, ref_value = "flash_load"}),
        create_toggle({label = localize("b_manual_save"), ref_table = Portable.config, ref_value = "manual_save"}),
        create_toggle({label = localize("k_score_parse"), ref_table = Portable.config, ref_value = "score_parse"}),
        create_toggle({label = localize("k_score_display"), ref_table = Portable.config, ref_value = "score_display"}),
        create_toggle({label = localize("k_reduce_animation"), ref_table = Portable.config, ref_value = "reduce_animation"}),
    }}
end

function Portable.process_loc_text()
    G.localization.misc.dictionary = G.localization.misc.dictionary or {}
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

function copy_parse(obj, visited)
    visited = visited or {}
    if type(obj) ~= "table" then
        return obj
    end
    if visited[obj] then
        return visited[obj]
    end
    local copy = {}
    visited[obj] = copy
    for k, v in pairs(obj) do
        copy[k] = copy_parse(v, visited)
    end
    return copy
end

function restore_parse(target, copy)
    if not target or not copy then return end
    for k, v in pairs(copy) do
        if type(v) == "table" then
            if type(target[k]) == "table" then
                restore_parse(target[k], v)
            else
                target[k] = copy_parse(v)
            end
        else
            target[k] = v
        end
    end
end

local Game_update_ref = Game.update
function Game:update(dt)
    Game_update_ref(self, dt)
    if Portable.config.score_display or Portable.config.score_parse then update_preview(dt) end
    if Portable.update.dollar_UI then 
        local dollar_UI = G.HUD:get_UIE_by_ID('dollar_text_UI')
        dollar_UI.config.object:update()
        G.HUD:recalculate()
        Portable.update.dollar_UI = false
    end
    if Portable.update.discard_UI then 
        local discard_UI = G.HUD:get_UIE_by_ID('discard_UI_count')
        discard_UI.config.object:update()
        G.HUD:recalculate()
        Portable.update.discard_UI = false
    end
    if Portable.update.hand_UI then 
        local hand_UI = G.HUD:get_UIE_by_ID('hand_UI_count')
        hand_UI.config.object:update()
        G.HUD:recalculate()
        Portable.update.hand_UI = false
    end
    if can_parse() and has_order_changed() then
        local parse = main_parse()
        G.GAME.preview.chip_target = parse.global.chip_total
        G.GAME.preview.dollar_target = parse.global.money
    end
    G.GAME.misprint_rank = G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.value or nil
    G.GAME.misprint_suit = G.deck and G.deck.cards[1] and G.deck.cards[#G.deck.cards].base.suit or nil
end

local G_UIDEF_deck_preview_ref = G.UIDEF.deck_preview
function G.UIDEF.deck_preview(args)
    local t = G_UIDEF_deck_preview_ref(args)
    if Portable.config.misprint_display then
        local _minh, _minw = 0.35, 0.5
        local _colour = ((G.GAME.misprint_suit == 'Spades' or G.GAME.misprint_suit == 'Clubs') and G.C.WHITE or G.C.RED)
        local suit_labels = t.nodes[1].nodes[1].nodes[1].nodes
        local tt = {n=G.UIT.R, config={align = "cm", r = 0.1, padding = 0.04, minw = _minw, minh = 2*_minh+0.25}, nodes={
            G.GAME.misprint_rank and {n=G.UIT.T, config={text = localize('b_next')..': ', colour = G.C.WHITE, scale = 0.25, shadow = true}} or nil,
            G.GAME.misprint_suit and {n=G.UIT.T, config={text = localize(G.GAME.misprint_suit, 'suits_singular')..' '..localize(G.GAME.misprint_rank, 'ranks'), colour = _colour, scale = 0.25, shadow = true}} or nil,
        }}
        suit_labels[1] = tt
    end
    return t
end

function record_history_hands(args)
    G.GAME.history_hands = G.GAME.history_hands or {}
    local current_hand = {}
    current_hand.handname = args.text
    current_hand.disp_handname = args.disp_handname
    current_hand.level = G.GAME.hands[args.text].level
    current_hand.chips = args.chips
    current_hand.mult = args.mult
    current_hand.chip_total = math.floor(args.chips*args.mult)
    if Portable.config.score_display then
        G.GAME.preview.chip_target = current_hand.chip_total 
        G.GAME.preview.dollar_target = G.GAME.preview.dollar_tran
    end
    current_hand.cards = {}
    for k, v in pairs(G.play.cards) do
        local score = nil
        for kk, vv in pairs(args.scoring_hand) do
            if v == vv then score = true break end
        end
        local cardTable = v:save()
        if score then cardTable.score = true end
        table.insert(current_hand.cards, cardTable)
    end
    if G.GAME.chips + current_hand.chip_total - G.GAME.blind.chips >= 0 then current_hand.filter = true end
    table.insert(G.GAME.history_hands, current_hand)
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
                {n=G.UIT.T, config={text = ' '..localize(args.disp_handname, 'poker_hands'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
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
        chip_trans = {
            begin = 0,
            final = 0,
        },
        chip_proportion = 0,
        chip = 0,
        chip_text = '',
        dollar_target = 0,
        dollar_trans = {
            begin = 0,
            final = 0,
        },
        dollar_tran = 0,
        dollar_proportion = 0,
        dollar = 0,
        dollar_text = '',
        deck_text = '',
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
            e.config.colour = G.GAME.preview.dollar_target >= 0 and G.C.MONEY or G.C.RED
            G.GAME.preview.dollar_text = new_preview_dollar_text
        end
    end
end

function update_preview(dt)
    if G.GAME and G.GAME.preview and G.GAME.preview.chip ~= G.GAME.preview.chip_target then
        if G.GAME.preview.chip_trans.final ~= G.GAME.preview.chip_target then
            G.GAME.preview.chip_trans.final = G.GAME.preview.chip_target
            G.GAME.preview.chip_trans.begin = G.GAME.preview.chip
            G.GAME.preview.chip_proportion = 1 - dt*(G.SETTINGS.GAMESPEED or 1)
        end
        G.GAME.preview.chip = math.floor(G.GAME.preview.chip_proportion*G.GAME.preview.chip_trans.begin + (1-G.GAME.preview.chip_proportion)*G.GAME.preview.chip_trans.final)
        if G.GAME.preview.chip == math.huge and G.GAME.preview.chip_target ~= math.huge then G.GAME.preview.chip = G.GAME.preview.chip_target end
        G.GAME.preview.chip_proportion = math.max(G.GAME.preview.chip_proportion - dt*(G.SETTINGS.GAMESPEED or 1), 0)
    end
    if G.GAME and G.GAME.preview and G.GAME.preview.dollar ~= G.GAME.preview.dollar_target then
        if G.GAME.preview.dollar_trans.final ~= G.GAME.preview.dollar_target then
            G.GAME.preview.dollar_trans.final = G.GAME.preview.dollar_target
            G.GAME.preview.dollar_trans.begin = G.GAME.preview.dollar
            G.GAME.preview.dollar_proportion = 1 - dt*(G.SETTINGS.GAMESPEED or 1)
        end
        G.GAME.preview.dollar = math.floor(G.GAME.preview.dollar_proportion*G.GAME.preview.dollar_trans.begin + (1-G.GAME.preview.dollar_proportion)*G.GAME.preview.dollar_trans.final)
        if G.GAME.preview.dollar == math.huge and G.GAME.preview.dollar_target ~= math.huge then G.GAME.preview.dollar = G.GAME.preview.dollar_target end
        G.GAME.preview.dollar_proportion = math.max(G.GAME.preview.dollar_proportion - dt*(G.SETTINGS.GAMESPEED or 1), 0)
    end
end

local G_FUNCS_draw_from_play_to_discard_ref = G.FUNCS.draw_from_play_to_discard
G.FUNCS.draw_from_play_to_discard = function(e)
    G_FUNCS_draw_from_play_to_discard_ref(e)
    G.E_MANAGER:add_event(Event({func = function()
        G.GAME.preview.chip_target = 0; G.GAME.preview.dollar_target = 0
    return true end}))
end

local ease_dollars_ref = ease_dollars
function ease_dollars(mod, instant)
    G.GAME.preview.dollar_tran = G.GAME.preview.dollar_tran + mod
    if Portable.config.reduce_animation then
        G.GAME.dollars = G.GAME.dollars + (mod or 0)
        Portable.update.dollar_UI = true
    else
        ease_dollars_ref(mod, instant)
    end
end

local Card_set_edition_ref = Card.set_edition
function Card:set_edition(edition, immediate, silent, delay)
    if Portable.config.reduce_animation then silent = true end
    Card_set_edition_ref(self, edition, immediate, silent, delay)
end

local Card_set_seal_ref = Card.set_seal
function Card:set_seal(_seal, silent, immediate)
    if Portable.config.reduce_animation then silent = true end
    Card_set_seal_ref(self, _seal, silent, immediate)
end

local Card_juice_up_ref = Card.juice_up
function Card:juice_up(...)
    if Portable.config.reduce_animation then
    else
        return Card_juice_up_ref(self, ...)
    end
end

local ease_chips_ref = ease_chips
function ease_chips(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local mod = args[1] or 0
        G.GAME.chips = mod
    else
        ease_chips_ref(...)
    end
end

local ease_discard_ref = ease_discard
function ease_discard(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local mod = args[1] or 0
        mod = math.max(-G.GAME.current_round.discards_left, mod)
        G.GAME.current_round.discards_left = G.GAME.current_round.discards_left + mod
        Portable.update.discard_UI = true
    else
        ease_discard_ref(...)
    end
end

local ease_hands_played_ref = ease_hands_played
function ease_hands_played(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local mod = args[1] or 0
        G.GAME.current_round.hands_left = G.GAME.current_round.hands_left + mod
        Portable.update.hand_UI = true
    else
        ease_hands_played_ref(...)
    end
end

local level_up_hand_ref = level_up_hand
function level_up_hand(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local hand = args[2]
        local amount = args[4] or 1
        if hand then
            G.GAME.hands[hand].level = math.max(0, G.GAME.hands[hand].level + amount)
            G.GAME.hands[hand].mult = math.max(G.GAME.hands[hand].s_mult + G.GAME.hands[hand].l_mult*(G.GAME.hands[hand].level - 1), 1)
            G.GAME.hands[hand].chips = math.max(G.GAME.hands[hand].s_chips + G.GAME.hands[hand].l_chips*(G.GAME.hands[hand].level - 1), 0)
        end
    else
        level_up_hand_ref(...)
    end
end

local update_hand_text_ref = update_hand_text
function update_hand_text(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local vals = args[2] or {}
        if vals.handname and G.GAME.current_round.current_hand.handname ~= vals.handname then
            G.GAME.current_round.current_hand.handname = vals.handname
        end
        if vals.level and G.GAME.current_round.current_hand.hand_level ~= ' '..localize('k_lvl')..tostring(vals.level) then
            if vals.level == '' then
                G.GAME.current_round.current_hand.hand_level = vals.level
            else
                G.GAME.current_round.current_hand.hand_level = ' '..localize('k_lvl')..tostring(vals.level)
                if type(vals.level) == 'number' then 
                    G.hand_text_area.hand_level.config.colour = G.C.HAND_LEVELS[math.min(vals.level, 7)]
                else
                    G.hand_text_area.hand_level.config.colour = G.C.HAND_LEVELS[1]
                end
            end
        end
    else
        return update_hand_text_ref(...)
    end
end

local card_eval_status_text_ref = card_eval_status_text
function card_eval_status_text(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local extra = args[6]
        if extra and extra.playing_cards_created then
            playing_card_joker_effects(extra.playing_cards_created)
        end
    else
        return card_eval_status_text_ref(...)
    end
end

local juice_card_ref = juice_card
function juice_card(...)
    if Portable.config.reduce_animation then
    else
        return juice_card_ref(...)
    end
end

local SMODS_calculate_effect_ref = SMODS.calculate_effect
SMODS.calculate_effect = function(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local effect = args[1]
        if effect.juice_card then effect.juice_card = nil end
    end
    return SMODS_calculate_effect_ref(...)
end

local SMODS_calculate_individual_effect_ref = SMODS.calculate_individual_effect
SMODS.calculate_individual_effect = function(...)
    if Portable.config.reduce_animation then
        local args = {...}
        local effect = args[1]
        if effect then effect.remove_default_message = true end
    end
    return SMODS_calculate_individual_effect_ref(...)
end

G.FUNCS.achievement_list = function(e)
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{
        definition = G.UIDEF.achievement_list(),
    }
end

function G.UIDEF.achievement_list()
    if not G.ACHIEVEMENTS then fetch_achievements() end
    G.ACHIEVEMENT_PAGE_SIZE = 4
    local achievement_pages = {}
    G.achievement_list = {}
    for k, v in pairs(G.ACHIEVEMENTS) do
        v.name = k
        G.achievement_list[#G.achievement_list + 1] = v
    end
    table.sort(G.achievement_list, function (a, b) return a.order < b.order end)
    for i = 1, math.ceil(#G.achievement_list/G.ACHIEVEMENT_PAGE_SIZE) do
        table.insert(achievement_pages, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.achievement_list/G.ACHIEVEMENT_PAGE_SIZE)))
    end
    G.E_MANAGER:add_event(Event({func = (function()
        G.FUNCS.change_achievement_list_page{cycle_config = {current_option = 1}}
    return true end)}))
    local _ac_comp, _ac_tot = 0, #G.achievement_list
    for k, v in ipairs(G.achievement_list) do
        if v.earned then _ac_comp = _ac_comp + 1 end
    end
    local t = create_UIBox_generic_options({back_func = 'options', back_id = 'achievement_list', contents = {
        {n=G.UIT.C, config={align = "cm", padding = 0.0}, nodes={
            {n=G.UIT.R, config={align = "cm", padding = 0.1, minh = 2.8, minw = 3.5}, nodes={
                {n=G.UIT.O, config={id = 'achievement_list', object = Moveable()}},
            }},
            {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
                create_option_cycle({id = 'achievement_page', scale = 0.9, h = 0.3, w = 3.5, options = achievement_pages, cycle_shoulders = true, opt_callback = 'change_achievement_list_page', current_option = 1, colour = G.C.RED, no_pips = true, focus_args = {snap_to = true}})
            }},
            {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
                {n=G.UIT.T, config={text = localize{type = 'variable', key = 'achievements_completed', vars = {_ac_comp, _ac_tot}}, scale = 0.4, colour = G.C.WHITE}},
            }},
        }},
        {n=G.UIT.C, config={align = "cm", minh = 5, minw = 8.2}, nodes={
            {n=G.UIT.O, config={id = 'achievement_area', object = Moveable()}},
        }},
    }})
    return t
end

G.FUNCS.change_achievement_list_page = function(args)
    if not args or not args.cycle_config then return end
    if G.OVERLAY_MENU then
        local ac_list = G.OVERLAY_MENU:get_UIE_by_ID('achievement_list')
        if ac_list then
            if ac_list.config.object then
                ac_list.config.object:remove()
            end
            ac_list.config.object = UIBox{
                definition =  G.UIDEF.achievement_list_page(args.cycle_config.current_option-1),
                config = {offset = {x=0,y=0}, align = 'cm', parent = ac_list}
            }
            G.FUNCS.change_achievement_description{config = {id = 'nil'}}
        end
    end
end

function G.UIDEF.achievement_list_page(_page)
    local snapped = false
    local achievement_list = {}
    for k, v in ipairs(G.achievement_list) do
        if v.order > G.ACHIEVEMENT_PAGE_SIZE*(_page or 0) and v.order <= G.ACHIEVEMENT_PAGE_SIZE*((_page or 0) + 1) then
            if G.CONTROLLER.focused.target and G.CONTROLLER.focused.target.config.id == 'achievement_page' then snapped = true end
            local achievement_completed =  v.earned
            achievement_list[#achievement_list+1] = {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.C, config={align = 'cl', minw = 0.8}, nodes = {
                    {n=G.UIT.T, config={text = v.order..'', lang = G.LANGUAGES['en-us'], scale = 0.4, colour = G.C.WHITE}},
                }},
                UIBox_button({id = v.name, col = true, label = {localize(v.name, 'achievement_names')}, button = 'change_achievement_description', colour = G.C.RED, minw = 4, scale = 0.4, minh = 0.6, focus_args = {snap_to = not snapped}}),
                {n=G.UIT.C, config={align = 'cm', padding = 0.05, minw = 0.6}, nodes={
                    {n=G.UIT.C, config={minh = 0.4, minw = 0.4, emboss = 0.05, r = 0.1, colour = achievement_completed and G.C.GREEN or G.C.BLACK}, nodes={
                        achievement_completed and {n=G.UIT.O, config={object = Sprite(0,0,0.4,0.4, G.ASSET_ATLAS["icons"], {x=1, y=0})}} or nil
                    }},
                }},
            }}      
            snapped = true
        end
    end
    return {n=G.UIT.ROOT, config={align = "cm", padding = 0.1, colour = G.C.CLEAR}, nodes=achievement_list}
end

G.FUNCS.change_achievement_description = function(e)
    if G.OVERLAY_MENU then
        local desc_area = G.OVERLAY_MENU:get_UIE_by_ID('achievement_area')
        if desc_area and desc_area.config.oid ~= e.config.id then
            if desc_area.config.old_chosen then desc_area.config.old_chosen.config.chosen = nil end
            e.config.chosen = 'vert'
            if desc_area.config.object then 
                desc_area.config.object:remove() 
            end
            desc_area.config.object = UIBox{
                definition =  G.UIDEF.achievement_description(e.config.id),
                config = {offset = {x=0,y=0}, align = 'cm', parent = desc_area}
            }
            desc_area.config.oid = e.config.id 
            desc_area.config.old_chosen = e
        end
    end
end

function G.UIDEF.achievement_description(name)
    if not G.ACHIEVEMENTS[name] then return {n=G.UIT.ROOT, config={align = "cm", colour = G.C.BLACK, minh = 4.6, minw = 7.9, r = 0.1}, nodes={{n=G.UIT.T, config={text = localize('ph_select_achievement'), scale = 0.4, colour = G.C.UI.TEXT_LIGHT}}}} end
    local achievement = get_achievement_information(name)
    local unlock_size = 0.6
    local unlocks = CardArea(0,0,2*unlock_size,0.6*G.CARD_H, {card_limit = 5, card_w = unlock_size*G.CARD_W, type = 'title_2', highlight_limit = 0})
    if achievement.card or achievement.seal then
        local card = Card(0,0, G.CARD_W*unlock_size, G.CARD_H*unlock_size, G.P_CARDS.empty, G.P_CENTERS[achievement.card or 'c_base'], {bypass_discovery_center = true, bypass_discovery_ui = true, bypass_lock = true})
        if achievement.seal then card:set_seal(achievement.seal, true) end
        if achievement.polychrome then card:set_edition({polychrome = true}, nil, true) end
        unlocks:emplace(card)
    elseif achievement.deck then
        local deck = Card(unlocks.T.x, unlocks.T.y, G.CARD_W*unlock_size, G.CARD_H*unlock_size, G.P_CARDS.empty, G.P_CENTERS.c_base)
        local deck_s = Sprite(0, 0, G.CARD_W*unlock_size, G.CARD_W*unlock_size, G.ASSET_ATLAS["centers"], G.P_CENTERS[achievement.deck].pos)
        deck.no_ui = true
        deck.children.center = deck_s
        deck_s:set_role({major = deck, role_type = 'Glued', draw_major = deck})
        unlocks:emplace(deck)
    elseif achievement.stake then
        local stake = Card(unlocks.T.x, unlocks.T.y, G.CARD_W*unlock_size, G.CARD_W*unlock_size, G.P_CARDS.empty, G.P_CENTERS.c_base)
        local stake_s = Sprite(0, 0, G.CARD_W*unlock_size, G.CARD_W*unlock_size, G.ASSET_ATLAS["chips"], G.P_CENTER_POOLS.Stake[achievement.stake].pos)
        stake.no_ui = true
        stake.children.center = stake_s
        stake_s:set_role({major = stake, role_type = 'Glued', draw_major = stake})
        stake.draw = function(...)
            Card.draw(...)
            stake.ARGS.send_to_shader = stake.ARGS.send_to_shader or {}
            stake.ARGS.send_to_shader[1] = math.min(stake.VT.r*3, 1) + G.TIMERS.REAL/(18) + (stake.juice and stake.juice.r*20 or 0) + 1
            stake.ARGS.send_to_shader[2] = G.TIMERS.REAL
            Sprite.draw_shader(stake.children.center, 'dissolve')
            Sprite.draw_shader(stake.children.center, 'voucher', nil, stake.ARGS.send_to_shader)
        end
        unlocks:emplace(stake)
    else
        local trophy = Card(unlocks.T.x, unlocks.T.y, G.CARD_W*unlock_size, G.CARD_W*unlock_size, G.P_CARDS.empty, G.P_CENTERS.c_base)
        local trophy_s = Sprite(0, 0, G.CARD_W*unlock_size, G.CARD_W*unlock_size, G.ASSET_ATLAS["icons"], {x=3, y=0})
        trophy.no_ui = true
        trophy.children.center = trophy_s
        trophy_s:set_role({major = trophy, role_type = 'Glued', draw_major = trophy})
        unlocks:emplace(trophy)
    end
    local ac_tab = {max = achievement.tab.max or 1, current = achievement.tab.current or 0}
    if achievement.completed then ac_tab.current = ac_tab.max end
    local progress_bars = {n=G.UIT.C, config={align = "cm", r = 0.1, maxh = 1.8, colour = G.C.L_BLACK, emboss = 0.05, progress_bar = {max = ac_tab.max, ref_table = ac_tab, ref_value = 'current', empty_col = G.C.L_BLACK, filled_col = achievement.completed and G.C.GREEN or G.C.FILTER}}, nodes={
        {n=G.UIT.C, config={align = "cm", padding = 0.05, r = 0.1, minw = 5}, nodes={
            {n=G.UIT.O, config={object = DynaText({string = {math.floor(0.01+100*ac_tab.current/ac_tab.max)..'%'}, font = G.LANGUAGES['en-us'].font, colours = {G.C.WHITE}, shadow = true, float = true, scale = 0.6})}},
            {n=G.UIT.T, config={text = " ("..ac_tab.current..'/'..ac_tab.max..")", lang = G.LANGUAGES['en-us'], scale = scale_number(ac_tab.max, 0.6), colour = G.C.JOKER_GREY}}
        }}
    }}
    local unlock_col = {n=G.UIT.C, config={align = "cm", padding = 0.05, colour = G.C.L_BLACK, r = 0.1, maxh = 1.8}, nodes={
        {n=G.UIT.T, config={text = localize('k_reward'), scale = 0.5, colour = G.C.UI.TEXT_LIGHT, vert = true, shadow = true}},
        {n=G.UIT.C, config={align = "cm", minh = 0.6*G.CARD_H, minw = 2, r = 0.1, colour = G.C.UI.TRANSPARENT_DARK}, nodes={
            unlocks and {n=G.UIT.O, config={object = unlocks}} or {n=G.UIT.T, config={text = localize('k_none'), scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}
        }}
    }}
    return {n=G.UIT.ROOT, config={align = "cm", r = 0.1, colour = G.C.BLACK}, nodes={
        {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
            unlock_col, progress_bars
        }},
        {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
            {n=G.UIT.C, config={align = "cm", padding = 0.1, colour = G.C.L_BLACK, r = 0.1, minw = 3}, nodes={
                {n=G.UIT.C, config={align = "cm", minw = 3, r = 0.1, colour = G.C.BLUE}, nodes={
                    {n=G.UIT.R, config={align = "cm", padding = 0.08, minh = 0.6}, nodes={
                        {n=G.UIT.T, config={text = localize('b_rules'), scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }},
                    {n=G.UIT.R, config={align = "cm", minh = 1.6, minw = 7.5, maxw = 7.5, padding = 0.05, r = 0.1, colour = G.C.WHITE}, nodes={
                        {n=G.UIT.T, config={text = localize(name, 'achievement_descriptions'), scale = 0.4, colour = G.C.UI.TEXT_DARK}},
                    }}
                }}
            }}
        }}
    }}
end

function get_achievement_information(name)
    local achievement = {tab = {}, card = nil, seal = nil, polychrome = nil, stake = nil, deck = nil, completed = nil}
    if name == 'ante_up' then
        achievement.tab.max = 4
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].high_scores['furthest_ante'].amt, achievement.tab.max)
        achievement.card = 'j_ring_master'
    elseif name == 'ante_upper' then
        achievement.tab.max = 8
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].high_scores['furthest_ante'].amt, achievement.tab.max)
        achievement.card = 'j_flower_pot'
    elseif name == 'heads_up' then
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].career_stats['c_wins'], 1)
        achievement.card = 'j_blueprint'
    elseif name == 'low_stakes' then
        achievement.deck = 'b_zodiac'
    elseif name == 'mid_stakes' then
        achievement.deck = 'b_anaglyph'
    elseif name == 'high_stakes' then
        achievement.stake = 8
    elseif name == 'card_player' then
        achievement.tab.max = 2500
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].career_stats['c_cards_played'], achievement.tab.max)
        achievement.card = 'v_nacho_tong'
    elseif name == 'card_discarder' then
        achievement.tab.max = 2500
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].career_stats['c_cards_discarded'], achievement.tab.max)
        achievement.card = 'v_recyclomancy'
    elseif name == 'nest_egg' then
        achievement.tab.max = 400
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].career_stats['c_dollars_earned'], achievement.tab.max)
        achievement.card = 'j_satellite'
    elseif name == 'flushed' then
        achievement.card = 'm_wild'
    elseif name == 'speedrunner' then
        achievement.card = 'j_merry_andy'
    elseif name == 'roi' then
        achievement.card = 'v_seed_money'
    elseif name == 'shattered' then
        achievement.card = 'm_glass'
    elseif name == 'royale' then
        achievement.card = 'j_baron'
    elseif name == 'retrograde' then
        achievement.card = 'c_mercury'
    elseif name == '_10k' then
        achievement.tab.max = 10000
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].high_scores['hand'].amt, achievement.tab.max)
        achievement.card = 'j_oops'
    elseif name == '_1000k' then
        achievement.tab.max = 1000000
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].high_scores['hand'].amt, achievement.tab.max)
        achievement.card = 'j_idol'
    elseif name == '_100000k' then
        achievement.tab.max = 100000000
        achievement.tab.current = math.min(G.PROFILES[G.SETTINGS.profile].high_scores['hand'].amt, achievement.tab.max)
        achievement.card = 'j_stuntman'
    elseif name == 'tiny_hands' then
        achievement.card = 'j_four_fingers'
    elseif name == 'big_hands' then
        achievement.card = 'v_grabber'
    elseif name == 'rule_bender' then
        achievement.card = 'j_acrobat'
    elseif name == 'rule_breaker' then
        achievement.tab.max = #G.CHALLENGES
        achievement.tab.current = 0
        for k, v in ipairs(G.CHALLENGES) do
            if v.id and G.PROFILES[G.SETTINGS.profile].challenge_progress.completed[v.id] then
                achievement.tab.current = achievement.tab.current + 1
            end
        end
        achievement.deck = 'b_challenge'
    elseif name == 'legendary' then
        achievement.card = 'c_soul'
    elseif name == 'astronomy' then
        achievement.tab.max = G.DISCOVER_TALLIES.planets.of
        achievement.tab.current = G.DISCOVER_TALLIES.planets.tally
        achievement.card = 'j_astronomer'
    elseif name == 'cartomancy' then
        achievement.tab.max = G.DISCOVER_TALLIES.tarots.of
        achievement.tab.current = G.DISCOVER_TALLIES.tarots.tally
        achievement.card = 'j_cartomancer'
    elseif name == 'clairvoyance' then
        achievement.tab.max = G.DISCOVER_TALLIES.spectrals.of
        achievement.tab.current = G.DISCOVER_TALLIES.spectrals.tally
        achievement.card = 'c_aura'
    elseif name == 'extreme_couponer' then
        achievement.tab.max = G.DISCOVER_TALLIES.vouchers.of
        achievement.tab.current = G.DISCOVER_TALLIES.vouchers.tally
        achievement.card = 'v_overstock_norm'
    elseif name == 'completionist' then
        achievement.tab.max = G.DISCOVER_TALLIES.total.of
        achievement.tab.current = G.DISCOVER_TALLIES.total.tally
        achievement.seal = 'Gold'
    elseif name == 'completionist_plus' then
        achievement.tab.max = G.PROGRESS.deck_stakes.of
        achievement.tab.current = G.PROGRESS.deck_stakes.tally
        achievement.card = 'j_golden'
    elseif name == 'completionist_plus_plus' then
        achievement.tab.max = G.PROGRESS.joker_stickers.of
        achievement.tab.current = G.PROGRESS.joker_stickers.tally
        achievement.card = 'c_fool'
        achievement.polychrome = true
    else
        achievement.tab.max = 1
    end
    if G.ACHIEVEMENTS[name] and G.ACHIEVEMENTS[name].earned then
        achievement.completed = true
    end
    return achievement
end

function can_parse()
    if Portable.config.score_parse then
        if G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND or G.STATE == G.STATES.PLAY_TAROT then
            return true
        end
    end
end

function has_order_changed()
    if not G.jokers or not G.hand then return end
    G.GAME.parse_order = G.GAME.parse_order or {jokers = {}, hand = {}, highlighted = 0}
    local order = G.GAME.parse_order
    local changed = false
    if (#order.jokers ~= #G.jokers.cards) or (#order.hand ~= #G.hand.cards) then changed = true end
    if order.highlighted ~= #G.hand.highlighted then order.highlighted = #G.hand.highlighted; changed = true end
    for k, v in ipairs(G.jokers.cards) do
        if order.jokers[v.sort_id] ~= k then
            changed = true
            order.jokers[v.sort_id] = k
        end
    end
    for k, v in ipairs(G.hand.cards) do
        if order.hand[v.sort_id] ~= k then
            changed = true
            order.hand[v.sort_id] = k
        end
    end
    return changed
end

function main_parse()
    local parse = {}
    global_parse(parse)
    blind_parse(parse)
    play_cards_parse(parse)
    hand_cards_parse(parse)
    poker_hands_parse(parse)
    jokers_parse(parse)
    planets_parse(parse)
    evaluate_parse(parse)
    return parse
end

function base_parse(card)
    local base = {
        sort_id = card.sort_id or 0,
        suit = card.base.suit or "Spades",
        is_face = card:is_face() or false,
        nominal = card.base.nominal or 0,
        id = card.base.id or 0,
        debuff = card.debuff or false,
        enhanced = card.ability.effect or "Base",
        seal = card.seal or nil,
        edition = card.edition and card.edition.type or "base",
        perma_bonus = card.ability.perma_bonus or 0
    }
    return base
end

function joker_parse(card)
    local joker = {
        sort_id = card.sort_id or 0,
        name = card.ability.name or "Joker",
        rarity = card.config.center.rarity or 1,
        debuff = card.debuff or false,
        edition = card.edition and card.edition.type or "base",
        card = card
    }
    return joker
end

function planet_parse(card)
    local planet = {
        sort_id = card.sort_id or 0,
        name = card.ability.name or "Pluto",
        debuff = card.debuff or false,
        hand_type = card.ability.consumeable.hand_type or "High Card"
    }
    return planet
end

function level_parse(parse, amount)
    amount = amount or 1
    G.GAME.hands[parse.poker_hands.name].level = G.GAME.hands[parse.poker_hands.name].level + amount
    G.GAME.hands[parse.poker_hands.name].chips = G.GAME.hands[parse.poker_hands.name].chips + G.GAME.hands[parse.poker_hands.name].l_chips*amount
    G.GAME.hands[parse.poker_hands.name].mult = G.GAME.hands[parse.poker_hands.name].mult + G.GAME.hands[parse.poker_hands.name].l_mult*amount
end

function is_suit_parse(base, suit)
    if base.enhanced == "Stone Card" then
        return false
    elseif base.enhanced == "Wild Card" then
        return true
    elseif next(find_joker("Smeared Joker")) and (base.suit == "Hearts" or base.suit == "Diamonds") == (suit == "Hearts" or suit == "Diamonds") then
        return true
    end
    return base.suit == suit
end

function get_id_parse(base)
    if base.enhanced == "Stone Card" and not base.vampired then
        return -math.random(100, 1000000)
    end
    return base.id
end

--main subordinate parse
function global_parse(parse)
    parse.global = {
        backup_pseudorandom = copy_parse(G.GAME.pseudorandom),
        backup_hands = copy_parse(G.GAME.hands),
        chip_total = 0,
        chips = 0,
        mult = 0,
        money = 0,
        hands_left = G.GAME.current_round.hands_left or 1,
        deck_size = #G.playing_cards or 0,
        sort_id = G.sort_id or 0,
        stone_tally = 0,
        steel_tally = 0,
        driver_tally = 0,
    }
    for _, v in ipairs(G.playing_cards) do
        if v.config.center == G.P_CENTERS.m_stone then parse.global.stone_tally = parse.global.stone_tally + 1 end
        if v.config.center == G.P_CENTERS.m_steel then parse.global.steel_tally = parse.global.steel_tally + 1 end
        if v.config.center ~= G.P_CENTERS.c_base then parse.global.driver_tally = parse.global.driver_tally + 1 end
    end
end

function blind_parse(parse)
    parse.blind = {
        name = G.GAME.blind.name or "Small Blind",
        disabled = G.GAME.blind.disabled or false,
    }
end

function play_cards_parse(parse)
    parse.play_cards = {}
    if G.hand and G.hand.highlighted and #G.hand.highlighted > 0 then
        for k, v in ipairs(G.hand.highlighted) do
            local base = base_parse(v)
            base.order = v.T.x or k
            table.insert(parse.play_cards, base)
        end
        table.sort(parse.play_cards, function(a, b) return a.order < b.order end)
        for k, v in ipairs(parse.play_cards) do v.order = k end
    end
end

function hand_cards_parse(parse)
    parse.hand_cards = {}
    if G.hand and G.hand.cards and #G.hand.cards > 0 then
        for k, v in ipairs(G.hand.cards) do
            if not v.highlighted then
                local base = base_parse(v)
                base.order = v.T.x or k
                table.insert(parse.hand_cards, base)
            end
        end
        table.sort(parse.hand_cards, function(a, b) return a.order < b.order end)
        for k, v in ipairs(parse.hand_cards) do v.order = k end
    end
end

function poker_hands_parse(parse)
    parse.poker_hands = {}
    parse.scoring_cards = {}
    if G.hand and G.hand.highlighted and #G.hand.highlighted > 0 then
        local text, _, poker_hands, scoring_hand = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
        parse.poker_hands.name = text
        parse.poker_hands.subordinate = {}
        for k, v in pairs(poker_hands) do
            if next(v) then
                parse.poker_hands.subordinate[k] = true
            end
        end
        local index = {}
        for _, v in ipairs(parse.play_cards) do
            index[v.sort_id] = v
        end
        for _, v in ipairs(scoring_hand) do
            if index[v.sort_id] then
                table.insert(parse.scoring_cards, index[v.sort_id])
            end
        end
    end
end

function jokers_parse(parse)
    parse.jokers = {}
    if G.jokers and G.jokers.cards and #G.jokers.cards > 0 then
        for k, v in ipairs(G.jokers.cards) do
            local joker = joker_parse(v)
            joker.order = v.T.x or k
            table.insert(parse.jokers, joker)
        end
        table.sort(parse.jokers, function(a, b) return a.order < b.order end)
        for k, v in ipairs(parse.jokers) do v.order = k end
    end
end

function planets_parse(parse)
    parse.planets = {}
    if G.consumeables and G.consumeables.cards and #G.consumeables.cards > 0 then
        for k, v in ipairs(G.consumeables.cards) do
            if v.ability.set == "Planet" then
                local planet = planet_parse(v)
                planet.order = v.T.x or k
                table.insert(parse.planets, planet)
            end
        end
        table.sort(parse.planets, function(a, b) return a.order < b.order end)
        for k, v in ipairs(parse.planets) do v.order = k end
    end
end

--evaluate subordinate parse
function eval_discard_parse(parse)
    local discard_cards = {}
    local to_keep = {}
    local destroyed_cards = {}
    for _, v in ipairs(parse.hand_cards) do
        if v.discard then
            v.discard = nil
            table.insert(discard_cards, v)
        else
            table.insert(to_keep, v)
        end
    end
    parse.hand_cards = to_keep
    for k, v in ipairs(parse.hand_cards) do v.order = k end
    table.sort(discard_cards, function(a, b) return a.order < b.order end)
    for _, v in ipairs(discard_cards) do
        local removed = false
        for _, j in ipairs(parse.jokers) do
            local is_destroyed = eval_joker_parse(j, parse, {discard = true, base = v, discarded = discard_cards})
            if is_destroyed then removed = true end
        end
        if removed then
            table.insert(destroyed_cards, v)
            parse.global.deck_size = parse.global.deck_size - 1
            if v.enhanced == "Stone Card" then
                parse.global.stone_tally = parse.global.stone_tally - 1
            elseif v.enhanced == "Steel Card" then
                parse.global.steel_tally = parse.global.steel_tally - 1
            end
            if v.enhanced ~= "Base" then parse.global.driver_tally = parse.global.driver_tally - 1 end
        end
    end
    if #destroyed_cards > 0 then
        for _, v in ipairs(parse.jokers) do
            eval_joker_parse(v, parse, {remove_playing_cards = true, removed = destroyed_cards})
        end
    end
end

function scoring_cards_parse(parse)
    if next(find_joker("Splash")) then
        for k, v in ipairs(parse.play_cards) do
            parse.scoring_cards[k] = v
        end
    else
        for _, v in ipairs(parse.play_cards) do
            if v.enhanced == "Stone Card" then
                local inside = false
                for _, j in ipairs(parse.scoring_cards) do
                    if j.sort_id == v.sort_id then
                        inside = true
                        break
                    end
                end
                if not inside then table.insert(parse.scoring_cards, v) end
            end
        end
    end
    table.sort(parse.scoring_cards, function(a, b) return a.order < b.order end)
end

function eval_blind_parse(blind, parse, context)
    if blind.disabled then return end
    if context.press_play then
        if blind.name == "The Hook" then
            local any_selected = nil
            local _cards = {}
            for _, v in ipairs(parse.hand_cards) do
                _cards[#_cards+1] = v
            end
            for i = 1, 2 do
                if parse.hand_cards[i] then
                    local selected_card, card_key = pseudorandom_element(_cards, pseudoseed("hook"))
                    selected_card.discard = true
                    table.remove(_cards, card_key)
                    any_selected = true
                end
            end
            if any_selected then
                eval_discard_parse(parse)
            end
        elseif blind.name == "The Tooth" then
            for _, v in ipairs(parse.play_cards) do
                parse.global.money = parse.global.money - 1
            end
        end
    elseif context.debuff_hand then
        if blind.name == "The Ox" then
            if parse.poker_hands.name == G.GAME.current_round.most_played_poker_hand then
                blind.triggered = true
                parse.global.money = parse.global.money - G.GAME.dollars
            end
        elseif blind.name == "The Mouth" then
            if G.GAME.blind.only_hand and G.GAME.blind.only_hand ~= parse.poker_hands.name then
                blind.triggered = true
                return true
            end
        elseif blind.name == "The Arm" then
            if G.GAME.hands[parse.poker_hands.name].level > 1 then
                blind.triggered = true
                level_parse(parse, -1)
            end
        elseif blind.name == "The Psychic" then
            if #parse.play_cards < G.GAME.blind.debuff.h_size_ge then
                blind.triggered = true
                return true
            end
        elseif blind.name == "The Eye" then
            if G.GAME.blind.hands[parse.poker_hands.name] then
                blind.triggered = true
                return true
            end
        end
    elseif context.modify_hand then
        if blind.name == "The Flint" then
            blind.triggered = true
            parse.global.chips = math.max(math.floor(parse.global.chips*0.5 + 0.5), 1)
            parse.global.mult = math.max(math.floor(parse.global.mult*0.5 + 0.5), 0)
        end
    end
end

function eval_seal_parse(base, parse, context)
    if base.debuff or not base.seal then return end
    if context.repetition then
        if base.seal == "Red" then
            return 1
        end
    end
end

function eval_edition_parse(card, parse)
    if card.debuff or not card.edition then return end
    if card.edition == "foil" then
        parse.global.chips = parse.global.chips + G.P_CENTERS.e_foil.config.extra
    elseif card.edition == "holo" then
        parse.global.mult = parse.global.mult + G.P_CENTERS.e_holo.config.extra
    elseif card.edition == "polychrome" then
        parse.global.mult = parse.global.mult*G.P_CENTERS.e_polychrome.config.extra
    end
end

function base_bonus_parse(base, parse)
    if base.debuff then return end
    if base.enhanced ~= "Stone Card" then
        parse.global.chips = parse.global.chips + base.nominal
    end
    if base.enhanced == "Bonus Card" then
        parse.global.chips = parse.global.chips + G.P_CENTERS.m_bonus.config.bonus
    elseif base.enhanced == "Stone Card" then
        parse.global.chips = parse.global.chips + G.P_CENTERS.m_stone.config.bonus
    end
    parse.global.chips = parse.global.chips + base.perma_bonus
end

function base_mult_parse(base, parse)
    if base.debuff then return end
    if base.enhanced == "Mult Card" then
        parse.global.mult = parse.global.mult + G.P_CENTERS.m_mult.config.mult
    elseif base.enhanced == "Lucky Card" then
        if pseudorandom("lucky_mult") < G.GAME.probabilities.normal/5 then
            base.lucky_trigger = true
            parse.global.mult = parse.global.mult + G.P_CENTERS.m_lucky.config.mult
        end
    end
end

function base_dollars_parse(base, parse)
    if base.debuff then return end
    if base.seal == "Gold" then
        parse.global.money = parse.global.money + 3
    end
    if base.enhanced == "Lucky Card" then
        if pseudorandom("lucky_money") < G.GAME.probabilities.normal/15 then
            base.lucky_trigger = true
            parse.global.money = parse.global.money + G.P_CENTERS.m_lucky.config.p_dollars
        end
    end
end

function base_x_mult_parse(base, parse)
    if base.debuff then return end
    if base.enhanced == "Glass Card" then
        parse.global.mult = parse.global.mult*G.P_CENTERS.m_glass.config.Xmult
    end
end

function base_h_x_mult_parse(base, parse)
    if base.debuff then return end
    if base.enhanced == "Steel Card" then
        parse.global.mult = parse.global.mult*G.P_CENTERS.m_steel.config.h_x_mult
    end
end

function eval_base_parse(base, parse, context)
    if base.debuff then return end
    if context.repetition then
        return eval_seal_parse(base, parse, context)
    elseif context.play then
        base_bonus_parse(base, parse)
        base_mult_parse(base, parse)
        base_dollars_parse(base, parse)
        base_x_mult_parse(base, parse)
        eval_edition_parse(base, parse)
    elseif context.hand then
        base_h_x_mult_parse(base, parse)
    end
end

function eval_joker_parse(joker, parse, context)
    if joker.debuff then return end
    if joker.name == "Blueprint" then
        context.copy_loop = (context.copy_loop or 0) + 1
        if context.copy_loop > #parse.jokers then return end
        if joker.order < #parse.jokers then
            return eval_joker_parse(parse.jokers[joker.order + 1], parse, context)
        end
    elseif joker.name == "Brainstorm" then
        context.copy_loop = (context.copy_loop or 0) + 1
        if context.copy_loop > #parse.jokers then return end
        if joker.order > 1 then
            return eval_joker_parse(parse.jokers[1], parse, context)
        end
    elseif context.discard then
        if joker.name == "Ramen" then
            if not context.copy_loop then
                if (joker.x_mult or joker.card.ability.x_mult) - joker.card.ability.extra <= 1 then
                    table.remove(parse.jokers, joker.order)
                    for k, v in ipairs(parse.jokers) do v.order = k end
                else
                    joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) - joker.card.ability.extra
                end
            end
        elseif joker.name == "Yorick" then
            if not context.copy_loop then
                if (joker.yorick_discards or joker.card.ability.yorick_discards) <= 1 then
                    joker.yorick_discards = joker.card.ability.extra.discards
                    joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) + joker.card.ability.extra.xmult
                else
                    joker.yorick_discards = (joker.yorick_discards or joker.card.ability.yorick_discards) - 1
                end
            end
        elseif joker.name == "Trading Card" then
            if G.GAME.current_round.discards_used <= 0 and #context.discarded == 1 and not context.copy_loop then
                parse.global.money = parse.global.money + joker.card.ability.extra
                return true
            end
        elseif joker.name == "Castle" then
            if not context.base.debuff and is_suit_parse(context.base, G.GAME.current_round.castle_card.suit) and not context.copy_loop then
                joker.chips = (joker.chips or joker.card.ability.extra.chips) + joker.card.ability.extra.chip_mod
            end
        elseif joker.name == "Mail-In Rebate" then
            if not context.base.debuff and get_id_parse(context.base) == G.GAME.current_round.mail_card.id then
                parse.global.money = parse.global.money + joker.card.ability.extra
            end
        elseif joker.name == "Hit the Road" then
            if not context.base.debuff and get_id_parse(context.base) == 11 and not context.copy_loop then
                joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) + joker.card.ability.extra
            end
        elseif joker.name == "Green Joker" then
            if context.base == context.discarded[#context.discarded] and not context.copy_loop then
                joker.mult = math.max(0, (joker.mult or joker.card.ability.mult) - joker.card.ability.extra.discard_sub)
            end
        end
    elseif context.remove_playing_cards then
        if joker.name == "Caino" then
            if not context.copy_loop then
                local face_cards = 0
                for _, v in ipairs(context.removed) do
                    if v.is_face then face_cards = face_cards + 1 end
                end
                if face_cards > 0 then
                    joker.caino_xmult = (joker.caino_xmult or joker.card.ability.caino_xmult) + joker.card.ability.extra*face_cards
                end
            end
        elseif joker.name == "Glass Joker" then
            if not context.copy_loop then
                local glass_cards = 0
                for _, v in ipairs(context.removed) do
                    if v.enhanced == "Glass Card" then glass_cards = glass_cards + 1 end
                end
                if glass_cards > 0 then
                    joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) + joker.card.ability.extra*glass_cards
                end
            end
        end
    elseif context.before then
        if joker.name == "Spare Trousers" then
            if (parse.poker_hands.subordinate["Two Pair"] or parse.poker_hands.subordinate["Full House"]) and not context.copy_loop then
                joker.mult = (joker.mult or joker.card.ability.mult) + joker.card.ability.extra
            end
        elseif joker.name == "Space Joker" then
            if pseudorandom("space") < G.GAME.probabilities.normal/joker.card.ability.extra then
                level_parse(parse)
            end
        elseif joker.name == "Square Joker" then
            if #parse.play_cards == 4 and not context.copy_loop then
                joker.chips = (joker.chips or joker.card.ability.extra.chips) + joker.card.ability.extra.chip_mod
            end
        elseif joker.name == "Runner" then
            if parse.poker_hands.subordinate["Straight"] and not context.copy_loop then
                joker.chips = (joker.chips or joker.card.ability.extra.chips) + joker.card.ability.extra.chip_mod
            end
        elseif joker.name == "Midas Mask" then
            if not context.copy_loop then
                for _, v in ipairs(parse.scoring_cards) do
                    if v.is_face then
                        v.enhanced = "Gold Card"
                    end
                end
            end
        elseif joker.name == "Vampire" then
            if not context.copy_loop then
                local enhanced = 0
                for k, v in ipairs(parse.scoring_cards) do
                    if v.enhanced ~= "Base" and not v.debuff and not v.vampired then
                        enhanced = enhanced + 1
                        v.vampired = true
                        v.enhanced = "Base"
                    end
                end
                if enhanced > 0 then
                    joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) + joker.card.ability.extra*enhanced
                end
            end
        elseif joker.name == "To Do List" then
            if parse.poker_hands.name == joker.card.ability.to_do_poker_hand then
                parse.global.money = parse.global.money + joker.card.ability.extra.dollars
            end
        elseif joker.name == "DNA" then
            if G.GAME.current_round.hands_played == 0 and #parse.play_cards == 1 then
                local copied = copy_parse(parse.play_cards[1])
                table.insert(parse.hand_cards, copied)
                parse.global.sort_id = parse.global.sort_id + 1
                copied.sort_id = parse.global.sort_id
                copied.order = #parse.hand_cards
                parse.global.deck_size = parse.global.deck_size + 1
                for _, v in ipairs(parse.jokers) do
                    eval_joker_parse(v, parse, {playing_card_added = true, cards = {copied}})
                end
            end
        elseif joker.name == "Ride the Bus" then
            if not context.copy_loop then
                local faces = false
                for _, v in ipairs(parse.scoring_cards) do
                    if v.is_face then
                        faces = true
                        break
                    end
                end
                if faces then
                    joker.mult = 0
                else
                    joker.mult = (joker.mult or joker.card.ability.mult) + joker.card.ability.extra
                end
            end
        elseif joker.name == "Obelisk" then
            if not context.copy_loop then
                local reset = true
                local play_more_than = (G.GAME.hands[parse.poker_hands.name].played or 0)
                for k, v in pairs(G.GAME.hands) do
                    if k ~= parse.poker_hands.name and v.played >= play_more_than and v.visible then
                        reset = false
                    end
                end
                if reset then
                    joker.x_mult = 1
                else
                    joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) + joker.card.ability.extra
                end
            end
        elseif joker.name == "Green Joker" then
            if not context.copy_loop then
                joker.mult = (joker.mult or joker.card.ability.mult) + joker.card.ability.extra.hand_add
            end
        end
    elseif context.playing_card_added then
        if joker.name == "Hologram" then
            if context.cards and context.cards[1] and not context.copy_loop then
                joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) + joker.card.ability.extra*#context.cards
            end
        end
    elseif context.repetition then
        if context.play then
            if joker.name == "Sock and Buskin" then
                if context.base.is_face then
                    return joker.card.ability.extra
                end
            elseif joker.name == "Hanging Chad" then
                if context.base == parse.scoring_cards[1] then
                    return joker.card.ability.extra
                end
            elseif joker.name == "Dusk" then
                if parse.global.hands_left == 0 then
                    return joker.card.ability.extra
                end
            elseif joker.name == "Seltzer" then
                return 1
            elseif joker.name == "Hack" then
                if get_id_parse(context.base) == 2 or get_id_parse(context.base) == 3 or get_id_parse(context.base) == 4 or get_id_parse(context.base) == 5 then
                    return joker.card.ability.extra
                end
            end
        elseif context.hand then
            if joker.name == "Mime" then
                return joker.card.ability.extra
            end
        end
    elseif context.individual then
        if context.play then
            if joker.name == "Hiker" then
                context.base.perma_bonus = context.base.perma_bonus + joker.card.ability.extra
            elseif joker.name == "Lucky Cat" then
                if context.base.lucky_trigger and not context.copy_loop then
                    joker.x_mult = (joker.x_mult or joker.card.ability.x_mult) + joker.card.ability.extra
                end
            elseif joker.name == "Wee Joker" then
                if get_id_parse(context.base) == 2 and not context.copy_loop then
                    joker.chips = (joker.chips or joker.card.ability.extra.chips) + joker.card.ability.extra.chip_mod
                end
            elseif joker.name == "Photograph" then
                local first_face = nil
                for _, v in ipairs(parse.scoring_cards) do
                    if v.is_face then first_face = v break end
                end
                if context.base == first_face then
                    parse.global.mult = parse.global.mult*joker.card.ability.extra
                end
            elseif joker.name == "The Idol" then
                if get_id_parse(context.base) == G.GAME.current_round.idol_card.id and is_suit_parse(context.base, G.GAME.current_round.idol_card.suit) then
                    parse.global.mult = parse.global.mult*joker.card.ability.extra
                end
            elseif joker.name == "Scary Face" then
                if context.base.is_face then
                    parse.global.chips = parse.global.chips + joker.card.ability.extra
                end
            elseif joker.name == "Smiley Face" then
                if context.base.is_face then
                    parse.global.mult = parse.global.mult + joker.card.ability.extra
                end
            elseif joker.name == "Golden Ticket" then
                if context.base.enhanced == "Gold Card" then
                    parse.global.money = parse.global.money + joker.card.ability.extra
                end
            elseif joker.name == "Scholar" then
                if get_id_parse(context.base) == 14 then
                    parse.global.chips = parse.global.chips + joker.card.ability.extra.chips
                    parse.global.mult = parse.global.mult + joker.card.ability.extra.mult
                end
            elseif joker.name == "Walkie Talkie" then
                if get_id_parse(context.base) == 10 or get_id_parse(context.base) == 4 then
                    parse.global.chips = parse.global.chips + joker.card.ability.extra.chips
                    parse.global.mult = parse.global.mult + joker.card.ability.extra.mult
                end
            elseif joker.name == "Business Card" then
                if context.base.is_face and pseudorandom("business") < G.GAME.probabilities.normal/joker.card.ability.extra then
                    parse.global.money = parse.global.money + 2
                end
            elseif joker.name == "Fibonacci" then
                if get_id_parse(context.base) == 2 or get_id_parse(context.base) == 3 or get_id_parse(context.base) == 5 or get_id_parse(context.base) == 8 or get_id_parse(context.base) == 14 then
                    parse.global.mult = parse.global.mult + joker.card.ability.extra
                end
            elseif joker.name == "Even Steven" then
                if get_id_parse(context.base) <= 10 and get_id_parse(context.base) >= 0 and get_id_parse(context.base)%2 == 0 then
                    parse.global.mult = parse.global.mult + joker.card.ability.extra
                end
            elseif joker.name == "Odd Todd" then
                if (get_id_parse(context.base) <= 10 and get_id_parse(context.base) >= 0 and get_id_parse(context.base)%2 == 1) or get_id_parse(context.base) == 14 then
                    parse.global.chips = parse.global.chips + joker.card.ability.extra
                end
            elseif joker.card.ability.effect == "Suit Mult" then
                if is_suit_parse(context.base, joker.card.ability.extra.suit) then
                    parse.global.mult = parse.global.mult + joker.card.ability.extra.s_mult
                end
            elseif joker.name == "Rough Gem" then
                if is_suit_parse(context.base, "Diamonds") then
                    parse.global.money = parse.global.money + joker.card.ability.extra
                end
            elseif joker.name == "Onyx Agate" then
                if is_suit_parse(context.base, "Clubs") then
                    parse.global.mult = parse.global.mult + joker.card.ability.extra
                end
            elseif joker.name == "Arrowhead" then
                if is_suit_parse(context.base, "Spades") then
                    parse.global.chips = parse.global.chips + joker.card.ability.extra
                end
            elseif joker.name == "Bloodstone" then
                if is_suit_parse(context.base, "Hearts") and pseudorandom("bloodstone") < G.GAME.probabilities.normal/joker.card.ability.extra.odds then
                    parse.global.mult = parse.global.mult*joker.card.ability.extra.Xmult
                end
            elseif joker.name == "Ancient Joker" then
                if is_suit_parse(context.base, G.GAME.current_round.ancient_card.suit) then
                    parse.global.mult = parse.global.mult*joker.card.ability.extra
                end
            elseif joker.name == "Triboulet" then
                if get_id_parse(context.base) == 12 or get_id_parse(context.base) == 13 then
                    parse.global.mult = parse.global.mult*joker.card.ability.extra
                end
            end
        elseif context.hand then
            if joker.name == "Shoot the Moon" then
                if get_id_parse(context.base) == 12 then
                    parse.global.mult = parse.global.mult + 13
                end
            elseif joker.name == "Baron" then
                if get_id_parse(context.base) == 13 then
                    parse.global.mult = parse.global.mult*joker.card.ability.extra
                end
            elseif joker.name == "Reserved Parking" then
                if context.base.is_face and pseudorandom("parking") < G.GAME.probabilities.normal/joker.card.ability.extra.odds then
                    parse.global.money = parse.global.money + joker.card.ability.extra.dollars
                end
            elseif joker.name == "Raised Fist" then
                local temp_Mult, temp_ID, raised_card = 15, 15, nil
                for _, v in ipairs(parse.hand_cards) do
                    if temp_ID >= v.id and v.enhanced ~= "Stone Card" then
                        temp_Mult = v.nominal
                        temp_ID = v.id
                        raised_card = v
                    end
                end
                if raised_card == context.base then
                    parse.global.mult = parse.global.mult + temp_Mult*2
                end
            end
        end
    elseif context.joker_main then
        if joker.name == "Loyalty Card" then
            local loyalty_remaining = (joker.card.ability.extra.every - 1 - (G.GAME.hands_played - joker.card.ability.hands_played_at_create))%(joker.card.ability.extra.every + 1)
            if loyalty_remaining == joker.card.ability.extra.every then
                parse.global.mult = parse.global.mult*joker.card.ability.extra.Xmult
            end
        elseif (joker.x_mult or joker.card.ability.x_mult) > 1 then
            if joker.card.ability.type == "" or parse.poker_hands.subordinate[joker.card.ability.type] then
                parse.global.mult = parse.global.mult*(joker.x_mult or joker.card.ability.x_mult)
            end
        elseif joker.card.ability.t_mult > 0 then
            if parse.poker_hands.subordinate[joker.card.ability.type] then
                parse.global.mult = parse.global.mult + joker.card.ability.t_mult
            end
        elseif joker.card.ability.t_chips > 0 then
            if parse.poker_hands.subordinate[joker.card.ability.type] then
                parse.global.chips = parse.global.chips + joker.card.ability.t_chips
            end
        elseif joker.name == "Half Joker" then
            if #parse.play_cards <= joker.card.ability.extra.size then
                parse.global.mult = parse.global.mult + joker.card.ability.extra.mult
            end
        elseif joker.name == "Abstract Joker" then
            parse.global.mult = parse.global.mult + joker.card.ability.extra*#parse.jokers
        elseif joker.name == "Acrobat" then
            if parse.global.hands_left == 0 then
                parse.global.mult = parse.global.mult*joker.card.ability.extra
            end
        elseif joker.name == "Mystic Summit" then
            if G.GAME.current_round.discards_left == joker.card.ability.extra.d_remaining then
                parse.global.mult = parse.global.mult + joker.card.ability.extra.mult
            end
        elseif joker.name == "Misprint" then
            local temp_Mult = pseudorandom("misprint", joker.card.ability.extra.min, joker.card.ability.extra.max)
            parse.global.mult = parse.global.mult + temp_Mult
        elseif joker.name == "Banner" then
            if G.GAME.current_round.discards_left > 0 then
                parse.global.chips = parse.global.chips + joker.card.ability.extra*G.GAME.current_round.discards_left
            end
        elseif joker.name == "Stuntman" then
            parse.global.chips = parse.global.chips + joker.card.ability.extra.chip_mod
        elseif joker.name == "Matador" then
            if parse.blind.triggered then
                parse.global.money = parse.global.money + joker.card.ability.extra
            end
        elseif joker.name == "Supernova" then
            parse.global.mult = parse.global.mult + G.GAME.hands[parse.poker_hands.name].played
        elseif joker.name == "Ceremonial Dagger" then
            if joker.card.ability.mult > 0 then
                parse.global.mult = parse.global.mult + joker.card.ability.mult
            end
        elseif joker.name == "Flower Pot" then
            local suits = {["Hearts"] = 0, ["Diamonds"] = 0, ["Spades"] = 0, ["Clubs"] = 0}
            for _, v in ipairs(parse.scoring_cards) do
                if v.enhanced ~= "Wild Card" then
                    if is_suit_parse(v, "Hearts") and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
                    elseif is_suit_parse(v, "Diamonds") and suits["Diamonds"] == 0 then suits["Diamonds"] = suits["Diamonds"] + 1
                    elseif is_suit_parse(v, "Spades") and suits["Spades"] == 0 then suits["Spades"] = suits["Spades"] + 1
                    elseif is_suit_parse(v, "Clubs") and suits["Clubs"] == 0 then suits["Clubs"] = suits["Clubs"] + 1 end
                end
            end
            for _, v in ipairs(parse.scoring_cards) do
                if v.enhanced == "Wild Card" and not v.debuff then
                    if is_suit_parse(v, "Hearts") and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
                    elseif is_suit_parse(v, "Diamonds") and suits["Diamonds"] == 0 then suits["Diamonds"] = suits["Diamonds"] + 1
                    elseif is_suit_parse(v, "Spades") and suits["Spades"] == 0 then suits["Spades"] = suits["Spades"] + 1
                    elseif is_suit_parse(v, "Clubs") and suits["Clubs"] == 0 then suits["Clubs"] = suits["Clubs"] + 1 end
                end
            end
            if suits["Hearts"] > 0 and suits["Diamonds"] > 0 and suits["Spades"] > 0 and suits["Clubs"] > 0 then
                parse.global.mult = parse.global.mult*joker.card.ability.extra
            end
        elseif joker.name == "Seeing Double" then
            local suits = {["Hearts"] = 0, ["Diamonds"] = 0, ["Spades"] = 0, ["Clubs"] = 0}
            for _, v in ipairs(parse.scoring_cards) do
                if v.enhanced ~= "Wild Card" and not v.debuff then
                    if is_suit_parse(v, "Hearts") and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
                    elseif is_suit_parse(v, "Diamonds") and suits["Diamonds"] == 0 then suits["Diamonds"] = suits["Diamonds"] + 1
                    elseif is_suit_parse(v, "Spades") and suits["Spades"] == 0 then suits["Spades"] = suits["Spades"] + 1
                    elseif is_suit_parse(v, "Clubs") and suits["Clubs"] == 0 then suits["Clubs"] = suits["Clubs"] + 1 end
                end
            end
            for _, v in ipairs(parse.scoring_cards) do
                if v.enhanced == "Wild Card" and not v.debuff then
                    if is_suit_parse(v, "Hearts") and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
                    elseif is_suit_parse(v, "Diamonds") and suits["Diamonds"] == 0 then suits["Diamonds"] = suits["Diamonds"] + 1
                    elseif is_suit_parse(v, "Spades") and suits["Spades"] == 0 then suits["Spades"] = suits["Spades"] + 1
                    elseif is_suit_parse(v, "Clubs") and suits["Clubs"] == 0 then suits["Clubs"] = suits["Clubs"] + 1 end
                end
            end
            if (suits["Hearts"] > 0 or suits["Diamonds"] > 0 or suits["Spades"] > 0) and suits["Clubs"] > 0 then
                parse.global.mult = parse.global.mult*joker.card.ability.extra
            end
        elseif joker.name == "Wee Joker" then
            if (joker.chips or joker.card.ability.extra.chips) > 0 then
                parse.global.chips = parse.global.chips + (joker.chips or joker.card.ability.extra.chips)
            end
        elseif joker.name == "Castle" then
            if (joker.chips or joker.card.ability.extra.chips) > 0 then
                parse.global.chips = parse.global.chips + (joker.chips or joker.card.ability.extra.chips)
            end
        elseif joker.name == "Blue Joker" then
            if #G.deck.cards > 0 then
                parse.global.chips = parse.global.chips + joker.card.ability.extra*#G.deck.cards
            end
        elseif joker.name == "Erosion" then
            if G.GAME.starting_deck_size - parse.global.deck_size > 0 then
                parse.global.mult = parse.global.mult + joker.card.ability.extra*(G.GAME.starting_deck_size - parse.global.deck_size)
            end
        elseif joker.name == "Square Joker" then
            if (joker.chips or joker.card.ability.extra.chips) > 0 then
                parse.global.chips = parse.global.chips + (joker.chips or joker.card.ability.extra.chips)
            end
        elseif joker.name == "Runner" then
            if (joker.chips or joker.card.ability.extra.chips) > 0 then
                parse.global.chips = parse.global.chips + (joker.chips or joker.card.ability.extra.chips)
            end
        elseif joker.name == "Ice Cream" then
            parse.global.chips = parse.global.chips + joker.card.ability.extra.chips
        elseif joker.name == "Stone Joker" then
            if parse.global.stone_tally > 0 then
                parse.global.chips = parse.global.chips + joker.card.ability.extra*parse.global.stone_tally
            end
        elseif joker.name == "Steel Joker" then
            if parse.global.steel_tally > 0 then
                parse.global.mult = parse.global.mult*(1 + joker.card.ability.extra*parse.global.steel_tally)
            end
        elseif joker.name == "Bull" then
            if G.GAME.dollars + parse.global.money > 0 then
                parse.global.chips = parse.global.chips + joker.card.ability.extra*(G.GAME.dollars + parse.global.money)
            end
        elseif joker.name == "Driver's License" then
            if parse.global.driver_tally >= 16 then
                parse.global.mult = parse.global.mult*joker.card.ability.extra
            end
        elseif joker.name == "Blackboard" then
            local black_suits = 0
            for _, v in ipairs(parse.hand_cards) do
                if is_suit_parse(v, "Clubs") or is_suit_parse(v, "Spades") then
                    black_suits = black_suits + 1
                end
            end
            if black_suits == #parse.hand_cards then
                parse.global.mult = parse.global.mult*joker.card.ability.extra
            end
        elseif joker.name == "Swashbuckler" then
            if joker.card.ability.mult > 0 then
                parse.global.mult = parse.global.mult + joker.card.ability.mult
            end
        elseif joker.name == "Joker" then
            parse.global.mult = parse.global.mult + joker.card.ability.mult
        elseif joker.name == "Spare Trousers" then
            if (joker.mult or joker.card.ability.mult) > 0 then
                parse.global.mult = parse.global.mult + (joker.mult or joker.card.ability.mult)
            end
        elseif joker.name == "Ride the Bus" then
            if (joker.mult or joker.card.ability.mult) > 0 then
                parse.global.mult = parse.global.mult + (joker.mult or joker.card.ability.mult)
            end
        elseif joker.name == "Flash Card" then
            if joker.card.ability.mult > 0 then
                parse.global.mult = parse.global.mult + joker.card.ability.mult
            end
        elseif joker.name == "Popcorn" then
            if joker.card.ability.mult > 0 then
                parse.global.mult = parse.global.mult + joker.card.ability.mult
            end
        elseif joker.name == "Green Joker" then
            if (joker.mult or joker.card.ability.mult) > 0 then
                parse.global.mult = parse.global.mult + (joker.mult or joker.card.ability.mult)
            end
        elseif joker.name == "Fortune Teller" then
            if G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.tarot > 0 then
                parse.global.mult = parse.global.mult + G.GAME.consumeable_usage_total.tarot
            end
        elseif joker.name == "Gros Michel" then
            parse.global.mult = parse.global.mult + joker.card.ability.extra.mult
        elseif joker.name == "Cavendish" then
            parse.global.mult = parse.global.mult*joker.card.ability.extra.Xmult
        elseif joker.name == "Red Card" then
            if joker.card.ability.mult > 0 then
                parse.global.mult = parse.global.mult + joker.card.ability.mult
            end
        elseif joker.name == "Card Sharp" then
            if G.GAME.hands[parse.poker_hands.name].played_this_round > 1 then
                parse.global.mult = parse.global.mult*joker.card.ability.extra.Xmult
            end
        elseif joker.name == "Bootstraps" then
            if math.floor((G.GAME.dollars + parse.global.money)/joker.card.ability.extra.dollars) >= 1 then
                parse.global.mult = parse.global.mult + joker.card.ability.extra.mult*math.floor((G.GAME.dollars + parse.global.money)/joker.card.ability.extra.dollars)
            end
        elseif joker.name == "Caino" then
            if (joker.caino_xmult or joker.card.ability.caino_xmult) > 1 then
                parse.global.mult = parse.global.mult*(joker.caino_xmult or joker.card.ability.caino_xmult)
            end
        end
    elseif context.other_joker then
        if joker.name == "Baseball Card" then
            if context.other_joker.rarity == 2 then
                parse.global.mult = parse.global.mult*joker.card.ability.extra
            end
        end
    elseif context.debuffed_hand then
        if joker.name == "Matador" then
            parse.global.money = parse.global.money + joker.card.ability.extra
        end
    end
end

function eval_planet_parse(planet, parse, context)
    if planet.debuff then return end
    if context.planet_main then
        if planet.hand_type then
            if G.GAME.used_vouchers.v_observatory and planet.hand_type == parse.poker_hands.name then
                parse.global.mult = parse.global.mult*G.P_CENTERS.v_observatory.config.extra
            end
        end
    end
end

function evaluate_parse(parse)
    if not G.hand or not G.hand.highlighted or not (#G.hand.highlighted > 0) then return end
    parse.global.hands_left = parse.global.hands_left - 1
    eval_blind_parse(parse.blind, parse, {press_play = true})
    G.GAME.hands[parse.poker_hands.name].played = G.GAME.hands[parse.poker_hands.name].played + 1
    G.GAME.hands[parse.poker_hands.name].played_this_round = G.GAME.hands[parse.poker_hands.name].played_this_round + 1
    G.GAME.hands[parse.poker_hands.name].visible = true
    scoring_cards_parse(parse)
    local not_allow = eval_blind_parse(parse.blind, parse, {debuff_hand = true})
    if not not_allow then
        for _, v in ipairs(parse.jokers) do
            eval_joker_parse(v, parse, {before = true})
        end
        parse.global.chips = G.GAME.hands[parse.poker_hands.name].chips
        parse.global.mult = G.GAME.hands[parse.poker_hands.name].mult
        eval_blind_parse(parse.blind, parse, {modify_hand = true})
        for _, v in ipairs(parse.scoring_cards) do
            if v.debuff then
                parse.blind.triggered = true
            else
                local reps = 1
                local base_reps = eval_base_parse(v, parse, {repetition = true})
                if base_reps then reps = reps + base_reps end
                for _, j in ipairs(parse.jokers) do
                    local joker_reps = eval_joker_parse(j, parse, {repetition = true, play = true, base = v})
                    if joker_reps then reps = reps + joker_reps end
                end
                for i = 1, reps do
                    eval_base_parse(v, parse, {play = true})
                    for _, j in ipairs(parse.jokers) do
                        eval_joker_parse(j, parse, {individual = true, play = true, base = v})
                    end
                    v.lucky_trigger = nil
                end
            end
        end
        for _, v in ipairs(parse.hand_cards) do
            if not v.debuff then
                local reps = 1
                local base_reps = eval_base_parse(v, parse, {repetition = true})
                if base_reps then reps = reps + base_reps end
                for _, j in ipairs(parse.jokers) do
                    local joker_reps = eval_joker_parse(j, parse, {repetition = true, hand = true, base = v})
                    if joker_reps then reps = reps + joker_reps end
                end
                for i = 1, reps do
                    eval_base_parse(v, parse, {hand = true})
                    for _, j in ipairs(parse.jokers) do
                        eval_joker_parse(j, parse, {individual = true, hand = true, base = v})
                    end
                end
            end
        end
        local dollar_cap = parse.global.money
        for _, v in ipairs(parse.jokers) do
            if v.edition == "foil" or v.edition == "holo" then
                eval_edition_parse(v, parse)
            end
            eval_joker_parse(v, parse, {joker_main = true})
            for _, j in ipairs(parse.jokers) do
                eval_joker_parse(j, parse, {other_joker = v})
            end
            if v.edition == "polychrome" then
                eval_edition_parse(v, parse)
            end
        end
        for _, v in ipairs(parse.planets) do
            eval_planet_parse(v, parse, {planet_main = true})
        end
        if G.GAME.modifiers.chips_dollar_cap then
            pparse.global.chips = math.min(parse.global.chips, math.max(G.GAME.dollars + dollar_cap, 0))
        elseif G.GAME.selected_back.name == "Plasma Deck" then
            local tot = parse.global.chips + parse.global.mult
            parse.global.chips = math.floor(tot/2)
            parse.global.mult = math.floor(tot/2)
        end
    else
        for _, v in ipairs(parse.jokers) do
            eval_joker_parse(v, parse, {debuffed_hand = true})
        end
    end
    parse.global.chip_total = math.floor(parse.global.chips*parse.global.mult)
    restore_parse(G.GAME.pseudorandom, parse.global.backup_pseudorandom)
    restore_parse(G.GAME.hands, parse.global.backup_hands)
end

----------------------------------------------
------------MOD CODE END----------------------
