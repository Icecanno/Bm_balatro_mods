--- STEAMODDED HEADER
--- MOD_NAME: Bmdragparts
--- MOD_ID: Bmdragparts
--- MOD_AUTHOR: [BaiMao]
--- MOD_DESCRIPTION: Provide drag card function, incompatible with Bmwallet
--- BADGE_COLOUR: 2F2F4F
--- VERSION: 1.0.1d
----------------------------------------------
------------MOD CODE -------------------------

Dragparts = SMODS.current_mod

Dragparts.config_tab = function()
    return {n=G.UIT.ROOT, config = {align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={
        create_option_cycle({w = 3, scale = 0.8, label = localize("b_operation_mode"), options = localize('ml_ope_mod'), opt_callback = 'change_operation_mode', current_option = G.SETTINGS.GRAPHICS.operation_mode or 1}),
    }}
end

function create_drag_target_from_card(_card)
    if _card and G.STAGE == G.STAGES.RUN then
        G.DRAG_TARGETS = G.DRAG_TARGETS or {
            S_buy =         Moveable{T={x = G.jokers.T.x, y = G.jokers.T.y - 0.1, w = G.consumeables.T.x + G.consumeables.T.w - G.jokers.T.x, h = G.jokers.T.h+0.6}},
            S_buy_and_use=  Moveable{T={x = G.deck.T.x + 0.2, y = G.deck.T.y - 5.1, w = G.deck.T.w-0.1, h = 4.5}},
            C_sell =        Moveable{T={x = G.jokers.T.x, y = G.jokers.T.y - 0.2, w = G.jokers.T.w, h = G.jokers.T.h+0.6}},
            J_sell =        Moveable{T={x = G.consumeables.T.x+0.3, y = G.consumeables.T.y - 0.2, w = G.consumeables.T.w-0.3, h = G.consumeables.T.h+0.6}},
            C_use =         Moveable{T={x = G.deck.T.x + 0.2, y = G.deck.T.y - 5.1, w = G.deck.T.w-0.1, h =4.5}},
            P_select =      Moveable{T={x = G.play.T.x, y = G.play.T.y - 2, w = G.play.T.w + 2, h = G.play.T.h + 1}},
        }
        if _card.area and (_card.area == G.shop_jokers or _card.area == G.shop_vouchers or _card.area == G.shop_booster) then
            local buy_loc = copy_table(localize((_card.area == G.shop_vouchers and 'ml_redeem_target') or (_card.area == G.shop_booster and 'ml_open_target') or 'ml_buy_target'))
            buy_loc[#buy_loc + 1] = '$'.._card.cost
            drag_target({ cover = G.DRAG_TARGETS.S_buy, colour = adjust_alpha(G.C.GREEN, 0.9), text = buy_loc, card = _card,
                active_check = (function(other)
                    return G.FUNCS.can_buy_touch(other)
                end),
                release_func = (function(other)
                    if other.area == G.shop_jokers and G.FUNCS.can_buy_touch(other) then
                        if G.OVERLAY_TUTORIAL and G.OVERLAY_TUTORIAL.button_listen == 'buy_from_shop' then
                            G.FUNCS.tut_next()
                        end
                        G.FUNCS.buy_from_shop({config = {ref_table = other, id = 'buy'}})
                        return
                    elseif other.area == G.shop_vouchers and G.FUNCS.can_buy_touch(other) then
                        G.FUNCS.use_card({config={ref_table = other}})
                    elseif other.area == G.shop_booster and G.FUNCS.can_buy_touch(other) then
                        G.FUNCS.use_card({config={ref_table = other}})
                    end
                end)
            })
            if G.FUNCS.can_buy_and_use_touch(_card) then
                local buy_use_loc = copy_table(localize('ml_buy_and_use_target'))
                buy_use_loc[#buy_use_loc + 1] = '$'.._card.cost
                drag_target({ cover = G.DRAG_TARGETS.S_buy_and_use, colour = adjust_alpha(G.C.ORANGE, 0.9), text = buy_use_loc, card = _card,
                    active_check = (function(other)
                        return G.FUNCS.can_buy_and_use_touch(other)
                    end),
                    release_func = (function(other)
                        if G.FUNCS.can_buy_and_use_touch(other) then
                            G.FUNCS.buy_from_shop({config = {ref_table = other, id = 'buy_and_use'}})
                            return
                        end
                    end)
                })
            end
        end
        if _card.area and (_card.area == G.pack_cards) then
            if _card.ability.consumeable and not (_card.ability.set == 'Planet') then
                drag_target({ cover = G.DRAG_TARGETS.C_use, colour = adjust_alpha(G.C.RED, 0.9), text = {localize('b_use')}, card = _card,
                    active_check = (function(other)
                        return other:can_use_consumeable()
                    end),
                    release_func = (function(other)
                        if other:can_use_consumeable() then
                            G.FUNCS.use_card({config={ref_table = other}})
                        end
                    end)
                })
            else
                drag_target({ cover = G.DRAG_TARGETS.P_select, colour = adjust_alpha(G.C.GREEN, 0.9), text = {localize('b_select')}, card = _card,
                    active_check = (function(other)
                        return G.FUNCS.can_select_card_touch(other)
                    end),
                    release_func = (function(other)
                        if G.FUNCS.can_select_card_touch(other) then
                            G.FUNCS.use_card({config={ref_table = other}})
                        end
                    end)
                })
            end
        end
        if _card.area and (_card.area == G.jokers or _card.area == G.consumeables) then
            local sell_loc = copy_table(localize('ml_sell_target'))
            sell_loc[#sell_loc + 1] = '$'..(_card.facing == 'back' and '?' or _card.sell_cost)
            drag_target({ cover = _card.area == G.consumeables and G.DRAG_TARGETS.C_sell or G.DRAG_TARGETS.J_sell, colour = adjust_alpha(G.C.GOLD, 0.9), text = sell_loc, card = _card,
                active_check = (function(other)
                    return other:can_sell_card()
                end),   
                release_func = (function(other)
                    G.FUNCS.sell_card{config={ref_table=other}}
                end)
            })
            if _card.area == G.consumeables and _card.ability.consumeable then
                drag_target({ cover = G.DRAG_TARGETS.C_use, colour = adjust_alpha(G.C.RED, 0.9),text = {localize('b_use')}, card = _card,
                    active_check = (function(other)
                        return other:can_use_consumeable()
                    end),
                    release_func = (function(other)
                        if other:can_use_consumeable() then
                            G.FUNCS.use_card({config={ref_table = other}})
                            if G.OVERLAY_TUTORIAL and G.OVERLAY_TUTORIAL.button_listen == 'use_card' then
                                G.FUNCS.tut_next()
                            end
                        end
                    end)
                })
            end
        end
    end
end

function drag_target(args)
    args = args or {}
    args.text = args.text or {'BUY'}
    args.colour = copy_table(args.colour or G.C.UI.TRANSPARENT_DARK)
    args.cover = args.cover or nil
    args.emboss = args.emboss or nil
    args.active_check = args.active_check or (function(other) return true end)
    args.release_func = args.release_func or (function(other) G.DEBUG_VALUE = 'WORKIN' end)
    args.text_colour = copy_table(G.C.WHITE)
    args.uibox_config = {
        align = args.align or 'tli',
        offset = args.offset or {x=0,y=0}, 
        major = args.cover or args.major or nil,
    }
    local drag_area_width =(args.T and args.T.w or args.cover and args.cover.T.w or 0.001) + (args.cover_padding or 0)
    local text_rows = {}
    for k, v in ipairs(args.text) do
        local font = k == #args.text and #args.text > 1 and G.LANGUAGES['en-us'].font
        text_rows[#text_rows+1] = {n=G.UIT.R, config={align = "cm", padding = 0.05, maxw = drag_area_width-0.1}, nodes={{n=G.UIT.O, config={object = DynaText({scale = args.scale, string = v, maxw = args.maxw or (drag_area_width-0.1), font = font, colours = {args.text_colour},float = true, shadow = true, silent = not args.noisy, 0.7, pop_in = 0, pop_in_rate = 6, rotate = args.rotate or nil})}}}}
    end
    args.DT = UIBox{
        T = {0,0,0,0},
        definition = {n=G.UIT.ROOT, config = {align = 'cm', args = args, can_collide = true, hover = true, release_func = args.release_func, func = 'check_drag_target_active', minw = drag_area_width, minh = (args.cover and args.cover.T.h or 0.001) + (args.cover_padding or 0), padding = 0.03, r = 0.1, emboss = args.emboss, colour = G.C.CLEAR}, nodes=text_rows}, 
        config = args.uibox_config
    }
    args.DT.attention_text = true
    if G.OVERLAY_TUTORIAL and G.OVERLAY_TUTORIAL.highlights then 
        G.OVERLAY_TUTORIAL.highlights[#G.OVERLAY_TUTORIAL.highlights+1] = args.DT
    end
    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0, blockable = false, blocking = false, func = function()
        if not G.CONTROLLER.dragging.target and args.DT then 
            if G.OVERLAY_TUTORIAL and G.OVERLAY_TUTORIAL.highlights then
                for k, v in ipairs(G.OVERLAY_TUTORIAL.highlights) do
                    if args.DT == v then 
                        table.remove(G.OVERLAY_TUTORIAL.highlights, k)
                        break
                    end
                end
            end
            args.DT:remove()
        return true end 
    end}))
end

G.FUNCS.check_drag_target_active = function(e)
    if e.config.args.active_check(e.config.args.card) then
        if (not e.config.pulse_border) or not e.config.args.init then
            e.config.pulse_border = true
            e.config.colour = e.config.args.colour
            e.config.args.text_colour[4] = 1
            e.config.release_func = e.config.args.release_func
        end
    else
        if (e.config.pulse_border) or not e.config.args.init then 
            e.config.pulse_border = nil
            e.config.colour = adjust_alpha(G.C.L_BLACK, 0.9)
            e.config.args.text_colour[4] = 0.5
            e.config.release_func = nil
        end
    end
    e.config.args.init = true
end

G.FUNCS.can_buy_touch = function(_card)
    if _card.cost > (G.GAME.dollars - G.GAME.bankrupt_at) and (_card.cost > 0) then
        return false
    end
    return true
end

G.FUNCS.can_buy_and_use_touch = function(_card)
    if (((_card.cost > G.GAME.dollars - G.GAME.bankrupt_at) and (_card.cost > 0)) or not _card.ability.consumeable or (not _card:can_use_consumeable())) then
        return false
    end
    return true
end

G.FUNCS.can_select_card_touch = function(_card)
    if _card.ability.set ~= 'Joker' or (_card.edition and _card.edition.negative) or #G.jokers.cards < G.jokers.config.card_limit then 
        return true
    end
    return false
end

local CardArea_set_ranks_ref = CardArea.set_ranks
function CardArea:set_ranks()
    CardArea_set_ranks_ref(self)
    for k, card in ipairs(self.cards) do
        if self.config.type == 'shop' or self.config.type == 'consumeable' then
            card.states.drag.can = true
        end
    end
end

local CardArea_can_highlight_ref = CardArea.can_highlight
function CardArea:can_highlight(card)
    local t = CardArea_can_highlight_ref(self, card)
    if (G.SETTINGS.GRAPHICS.operation_mode or 1) > 2 then
        if self.config.type == 'hand' then
            return true
        end
    else
        return t
    end
end

local G_UIDEF_use_and_sell_buttons_ref = G.UIDEF.use_and_sell_buttons
function G.UIDEF.use_and_sell_buttons(card)
    local ret = G_UIDEF_use_and_sell_buttons_ref(card)
    local mid = ret.nodes[1].config
    if mid.mid then
        mid.mid = nil
    end
    return ret
end

G.FUNCS.change_operation_mode = function(args)
    G.SETTINGS.GRAPHICS.operation_mode = args.to_key
    G:save_settings()
end

function Controller:is_valid_touch_hover_lock_target(target)
    return target and target ~= G.ROOM and not target.REMOVED and target.states and target.states.hover and target:is(Card)
end

function Controller:should_lock_touch_hover()
    local target = self.hovering.target
    if not self.HID.touch or not self:is_valid_touch_hover_lock_target(target) then return false end
    return Vector_Dist(self.cursor_down.T, self.cursor_up.T) >= G.MIN_CLICK_DIST
end

----------------------------------------------
------------MOD CODE END----------------------
