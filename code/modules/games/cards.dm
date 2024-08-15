/datum/playingcard
	var/name = "playing card"
	/// The front of the card, with all the fun stuff.
	var/card_icon = "card_back"
	/// The back of the card, shown when face-down.
	var/back_icon = "card_back"

/datum/playingcard/New(newname, newcard_icon, newback_icon)
	..()
	if(newname)
		name = newname
	if(newcard_icon)
		card_icon = newcard_icon
	if(newback_icon)
		back_icon = newback_icon

// lewtodo make unum decks stack on top of the actual deck itself
/obj/item/deck
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/playing_cards.dmi'
	actions_types = list(/datum/action/item_action/draw_card, /datum/action/item_action/deal_card, /datum/action/item_action/deal_card_multi, /datum/action/item_action/shuffle)

	throw_speed = 3
	throw_range = 10
	throwforce = 0
	force = 0

	var/list/cards = list()
	/// To prevent spam shuffle
	var/cooldown = 0
	/// Decks default to a single pack, setting it higher will multiply them by that number
	var/deck_size = 1
	/// The total number of cards. Set on init after the deck is fully built
	var/deck_total = 0
	/// Styling for the cards, if they have multiple sets of sprites
	var/card_style = null
	/// Styling for the deck, it they has multiple sets of sprites
	var/deck_style = null
	/// For decks without a full set of sprites
	var/simple_deck = FALSE
	/// Inherited card hit sound
	var/card_hitsound
	/// Inherited card force
	var/card_force = 0
	/// Inherited card throw force
	var/card_throwforce = 0
	/// Inherited card throw speed
	var/card_throw_speed = 4
	/// Inherited card throw range
	var/card_throw_range = 20
	/// Inherited card verbs
	var/card_attack_verb
	/// Inherited card resistance
	var/card_resistance_flags = FLAMMABLE
	/// Deck ID, used for splitting and re-joining decks.
	var/main_deck_id = -1

/obj/item/deck/Initialize(mapload, parent_deck_id = -1)
	. = ..()
	build_decks()
	update_icon(UPDATE_ICON_STATE|UPDATE_OVERLAYS)
	if(parent_deck_id == -1)
		// we're our own deck
		main_deck_id = rand(1, 99999)
	else
		main_deck_id = parent_deck_id


/obj/item/deck/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It contains <b>[length(cards) ? length(cards) : "no"]</b> card\s.</span>"
	. += "<span class='notice'>Drag [src] to yourself to pick it up.</span>"
	. += "<span class='notice'>If you draw or return cards with <span class='danger'>harm</span> intent, your plays will be public!</span>"
	. += "<span class='notice'>Examine this again to see some shortcuts for interacting with it.</span>"

/obj/item/deck/examine_more(mob/user)
	. = ..()
	. += "<span class='notice'><b>Click</b> to draw a card.</span>"
	. += "<span class='notice'><b>Alt-Click</b> to place a card.</span>"
	. += "<span class='notice'>With cards in your active hand...</span>"
	. += "\t<span class='notice'><b>Click</b> to draw a card into your hand.</span>"
	. += "\t<span class='notice'><b>Alt-click</b> with cards to place them on the bottom of the deck.</span>"
	. += "\t<span class='notice'><b>Ctrl-click</b> with cards to shuffle them into the deck.</span>"
	. += ""
	. += "<span class='notice'>With an empty hand...</span>"
	. += "\t<span class='notice'><b>Click</b> to draw from the top of the deck.</span>"
	. += "\t<span class='notice'><b>Alt-Click</b> to draw from the bottom of the deck.</span>"
	. += "\t<span class='notice'><b>Alt-Shift-Click</b> to shuffle the deck.</span>"


/obj/item/deck/proc/build_decks()
	if(length(cards))
		// prevent building decks more than once
		return
	for(var/deck in 1 to deck_size)
		build_deck()
	deck_total = length(cards)

/obj/item/deck/proc/build_deck()
	return

/obj/item/deck/attackby(obj/O, mob/user)
	// clicking is for drawing
	if(istype(O, /obj/item/deck))
		var/obj/item/deck/other_deck = O
		if(other_deck.main_deck_id != main_deck_id)
			to_chat(user, "<span class='warning'>These aren't the same deck!</span>")
			return

		merge_deck(user, O)
		return

	if(istype(O, /obj/item/pen))
		rename_interactive(user, O)
		return

	if(!istype(O, /obj/item/cardhand))
		return ..()
	var/obj/item/cardhand/H = O
	// lewtodo: parent deck ID needs to work in a way that allows for merging cards
	if(H.parentdeck != src)
		to_chat(user, "<span class='warning'>You can't mix cards from different decks!</span>")
		return

	draw_card(user, user.a_intent == INTENT_HARM)

// lewtodo: add the ability for decks to be split

/obj/item/deck/CtrlShiftClick(mob/user)
	. = ..()
	// todo: allow for splitting the deck so we can have a discard pile
	if(length(cards) <= 1)
		to_chat(user, "<span class='notice'>You can't split this deck, it's too small!</span>")
		return

	// split it off, with our deck ID.
	var/obj/item/deck/new_deck = new src.type(get_turf(src), main_deck_id)
	QDEL_LIST_CONTENTS(new_deck.cards)
	new_deck.cards = cards.Copy(length(cards) / 2, length(cards))
	cards.Cut(length(cards) / 2, length(cards))
	user.put_in_any_hand_if_possible(new_deck)
	user.visible_message("<span class='notice'>[user] splits [src] in two.</span>", "<span class='notice'>You split [src] in two.</span>")

/obj/item/deck/proc/merge_deck(mob/user, obj/item/deck/other_deck)
	for(var/card in other_deck.cards)
		cards += card
		other_deck -= card
	qdel(other_deck)
	user.visible_message("<span class='notice'>[user] mixes the two decks together.</span>", "<span class='notice'>You merge the two decks together.</span>")

/obj/item/deck/attack_hand(mob/user)
	draw_card(user)

/obj/item/deck/AltClick(mob/living/carbon/human/user)
	// alt-clicking is for putting back
	return_hand_click(user, TRUE)

/obj/item/deck/proc/return_hand_click(mob/user, on_top = TRUE)
	// alt-shift-click is for putting on the bottom
	if(!istype(user))
		return
	var/obj/item/cardhand/hand = get_user_card_hand(user)
	if(!istype(hand))
		return

	if(length(hand.cards) == 1)
		// we need to put this into a new list, otherwise things get funky if they reference both the hand list and this other list
		return_cards(user, hand, on_top, hand.cards.Copy())
		return
	var/selected_card = hand.select_card_radial(user)
	if(isnull(selected_card))
		return
	return_cards(user, hand, on_top, list(selected_card))

/obj/item/deck/MouseDrop_T(obj/item/I, mob/user)
	if(!istype(I, /obj/item/cardhand))
		return
	if(!Adjacent(user) || !user.Adjacent(I))
		return
	var/choice = tgui_alert(user, "Where would you like to return your hand to the deck?", "Return Hand", list("Top", "Bottom", "Cancel"))
	if(!Adjacent(user) || !user.Adjacent(I) || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) || isnull(choice) || choice == "Cancel")
		return

	return_cards(user, I, choice == "Top")

// is this getting too complicated?

/proc/get_user_card_hand(mob/living/carbon/human/user)
	var/obj/item/cardhand/hand = user.get_active_hand()
	if(!istype(hand))
		hand = user.get_inactive_hand()
	if(istype(hand))
		return hand

/obj/item/deck/proc/return_cards(mob/living/carbon/human/user, obj/item/cardhand/hand, place_on_top = TRUE, chosen_cards = list())

	if(!istype(hand))
		return

	if(hand.parentdeck != src)
		to_chat(user, "<span class='warning'>You can't mix cards from different decks!</span>")
		return

	var/side = place_on_top ? "top" : "bottom"

	// if we have chosen cards, we can skip confirmation since that should have probably happened before us
	if(!length(chosen_cards))
		if(length(hand.cards) > 1)
			var/confirm = tgui_alert(user, "Are you sure you want to put your [length(hand.cards)] card\s into the [side] of the deck?", "Return Hand to Bottom", list("Yes", "No"))
			if(confirm != "Yes" || !Adjacent(user) || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
				return
		chosen_cards = hand.cards

	if(place_on_top)
		cards = chosen_cards + cards
	else
		// equiv to += but here for clarity
		cards = cards + chosen_cards
	hand.cards -= chosen_cards
	if(!length(hand.cards))
		qdel(hand)
	else
		hand.update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
	if(length(chosen_cards) == 1 && !hand.concealed)
		var/datum/playingcard/P = chosen_cards[1]
		if(user.a_intent == INTENT_HARM)
			var/obj/effect/temp_visual/card_preview/draft = new /obj/effect/temp_visual/card_preview(user, P.card_icon)
			user.vis_contents += draft
			QDEL_IN(draft, 1 SECONDS)
			sleep(1 SECONDS)  // todo maybe do away with this sleep
		user.visible_message("<span class='notice'>[user] places [P] on the [side] of [src].</span>", "<span class='notice'>You place [P] on the [side] of [src].</span>")
	else
		user.visible_message("<span class='notice'>[user] returns [length(chosen_cards)] card\s to the [side] of [src].</span>", "<span class='notice'>You return [length(chosen_cards)] card\s to the [side] of [src].</span>")

	update_icon(UPDATE_ICON_STATE|UPDATE_OVERLAYS)

/obj/item/deck/CtrlClick(mob/living/carbon/human/user)
	if(!istype(user))
		return

	var/obj/item/cardhand/hand = user.get_active_hand()
	if(!istype(hand))
		return ..()

	if(hand.parentdeck != src)
		to_chat(user, "<span class='warning'>You can't mix cards from different decks!</span>")
		return

	if(length(hand.cards) > 1)
		var/confirm = tgui_alert(user, "Are you sure you want to put your [length(hand.cards)] card\s into the bottom of the deck?", "Return Hand to Bottom", list("Yes", "No"))
		if(confirm != "Yes" || !Adjacent(user) || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
			return


// Datum actions
/datum/action/item_action/draw_card
	name = "Draw - Draw one card"
	button_overlay_icon_state = "draw"
	use_itemicon = FALSE

/datum/action/item_action/draw_card/Trigger(left_click)
	if(istype(target, /obj/item/deck))
		var/obj/item/deck/D = target
		return D.draw_card(owner)
	return ..()

/datum/action/item_action/deal_card
	name = "Deal - deal one card to a person next to you"
	button_overlay_icon_state = "deal_card"
	use_itemicon = FALSE

/datum/action/item_action/deal_card/Trigger(left_click)
	if(istype(target, /obj/item/deck))
		var/obj/item/deck/D = target
		return D.deal_card()
	return ..()

/datum/action/item_action/deal_card_multi
	name = "Deal multiple card - Deal multiple card to a person next to you"
	button_overlay_icon_state = "deal_card_multi"
	use_itemicon = FALSE

/datum/action/item_action/deal_card_multi/Trigger(left_click)
	if(istype(target, /obj/item/deck))
		var/obj/item/deck/D = target
		return D.deal_card_multi()
	return ..()

/datum/action/item_action/shuffle
	name = "Shuffle - shuffle the deck"
	button_overlay_icon_state = "shuffle"
	use_itemicon = FALSE

/datum/action/item_action/shuffle/Trigger(left_click)
	if(istype(target, /obj/item/deck))
		var/obj/item/deck/D = target
		return D.deckshuffle()
	return ..()

// Datum actions


/**
 * Draw a card from this deck.
 * Arguments:
 * * user - The mob drawing the card.
 * * public - If true, the drawn card will be displayed to people around the table.
 * * draw_from_top - If true, the card will be drawn from the top of the deck.
 */
/obj/item/deck/proc/draw_card(mob/user, public = FALSE, draw_from_top = TRUE)
	var/mob/living/carbon/human/M = user

	if(user.incapacitated() || !Adjacent(user) || !istype(user))
		return

	if(!length(cards))
		to_chat(user,"<span class='notice'>There are no cards in the deck.</span>")
		return

	var/obj/item/cardhand/H = M.is_in_hands(/obj/item/cardhand)
	if(H && (H.parentdeck != src))
		to_chat(user,"<span class='warning'>You can't mix cards from different decks!</span>")
		return

	if(!H)
		H = new(get_turf(src))
		user.put_in_hands(H)

	var/datum/playingcard/P = draw_from_top ? cards[1] : cards[length(cards)]
	H.cards += P
	cards -= P
	update_icon(UPDATE_ICON_STATE|UPDATE_OVERLAYS)
	H.parentdeck = src
	H.update_values()
	H.update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)

	if(public)
		user.visible_message("<span class='danger'>[user] draws [P]!</span>", "<span class='danger'>You draw [P]!</span>")
		var/obj/effect/temp_visual/card_preview/draft = new /obj/effect/temp_visual/card_preview(user, P.card_icon)
		user.vis_contents += draft
		QDEL_IN(draft, 1 SECONDS)
		sleep(1 SECONDS)
	else
		user.visible_message("<span class='notice'>[user] draws a card.</span>", "<span class='notice'>You draw a card.</span>")
		to_chat(user, "<span class='notice'>It's [P].</span>")

/obj/item/deck/proc/deal_card()
	if(usr.incapacitated() || !Adjacent(usr))
		return

	if(!length(cards))
		to_chat(usr,"<span class='notice'>There are no cards in the deck.</span>")
		return

	var/list/players = list()
	for(var/mob/living/player in viewers(3))
		if(!player.incapacitated())
			players += player
	//players -= usr

	var/mob/living/M = tgui_input_list(usr, "Who do you wish to deal a card to?", "Deal Card", players)
	if(!usr || !src || !M) return

	deal_at(usr, M, 1)

/obj/item/deck/proc/deal_card_multi()
	if(usr.incapacitated() || !Adjacent(usr))
		return

	if(!length(cards))
		to_chat(usr,"<span class='notice'>There are no cards in the deck.</span>")
		return

	var/list/players = list()
	for(var/mob/living/player in viewers(3))
		if(!player.incapacitated())
			players += player
	var/dcard = tgui_input_number(usr, "How many card(s) do you wish to deal? You may deal up to [length(cards)] cards.", "Deal Cards", 1, length(cards), 1)
	if(isnull(dcard))
		return
	var/mob/living/M = tgui_input_list(usr, "Who do you wish to deal [dcard] card(s)?", "Deal Card", players)
	if(!usr || !src || !M || !Adjacent(usr))
		return

	deal_at(usr, M, dcard)

/obj/item/deck/proc/deal_at(mob/user, mob/target, dcard) // Take in the no. of card to be dealt
	var/obj/item/cardhand/H = new(get_step(user, user.dir))
	for(var/i in 1 to dcard)
		H.cards += cards[1]
		cards -= cards[1]
		update_icon(UPDATE_ICON_STATE|UPDATE_OVERLAYS)
		H.parentdeck = src
		H.update_values()
		H.concealed = TRUE
		H.update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
	if(user == target)
		user.visible_message("<span class='notice'>[user] deals [dcard] card(s) to [user.p_themselves()].</span>")
	else
		user.visible_message("<span class='notice'>[user] deals [dcard] card(s) to [target].</span>")
	H.throw_at(get_step(target, target.dir), 3, 1, null)


/obj/item/deck/attack_self()
	deckshuffle()


/obj/item/deck/proc/deckshuffle()
	var/mob/living/user = usr
	if(cooldown < world.time - 1 SECONDS)
		cards = shuffle(cards)

		if(user)
			user.visible_message("<span class='notice'>[user] shuffles [src].</span>")
			playsound(user, 'sound/items/cardshuffle.ogg', 50, TRUE)
		cooldown = world.time

	update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)

/obj/item/deck/MouseDrop(atom/over, src_location, over_location, src_control, over_control, params)
	var/mob/M = usr
	if(M.incapacitated() || !Adjacent(M))
		return
	if(!ishuman(M))
		return

	if(is_screen_atom(over))
		if(!remove_item_from_storage(get_turf(M)))
			M.unEquip(src)
		switch(over.name)
			if("r_hand")
				if(M.put_in_r_hand(src))
					add_fingerprint(M)
					usr.visible_message("<span class='notice'>[usr] picks up the deck.</span>")
			if("l_hand")
				if(M.put_in_l_hand(src))
					add_fingerprint(M)
					usr.visible_message("<span class='notice'>[usr] picks up the deck.</span>")
		return

	if(over == M && loc != M)
		if(M.put_in_hands(src))
			add_fingerprint(M)
			usr.visible_message("<span class='notice'>[usr] picks up the deck.</span>")

/obj/item/pack
	name = "card pack"
	desc = "For those with disposable income."

	icon_state = "card_pack"
	icon = 'icons/obj/playing_cards.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/list/cards = list()
	var/parentdeck = null // For future card pack that need to be compatible with eachother i.e. cardemon


/obj/item/pack/attack_self(mob/user as mob)
	user.visible_message("<span class='notice'>[name] rips open [src]!</span>", "<span class='notice'>You rip open [src]!</span>")
	var/obj/item/cardhand/H = new(get_turf(user))

	H.cards += cards
	cards.Cut()
	user.unEquip(src, force = 1)
	qdel(src)

	H.update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
	user.put_in_hands(H)

/obj/item/cardhand
	name = "hand of cards"
	desc = "Some playing cards."
	icon = 'icons/obj/playing_cards.dmi'
	icon_state = "empty"
	w_class = WEIGHT_CLASS_TINY
	actions_types = list(/datum/action/item_action/remove_card, /datum/action/item_action/discard)

	var/concealed = FALSE
	var/list/cards = list()
	/// Tracked direction, which is used when updating the hand's appearance instead of messing with the local dir
	var/direction = NORTH
	var/parent_deck_id = null

/obj/item/cardhand/examine(mob/user)
	. = ..()
	if(!concealed && length(cards))
		. += "<span class='notice'>It contains:</span>"
		for(var/datum/playingcard/P in cards)
			. += "<span class='notice'>the [P.name].</span>"

	if(Adjacent(user))
		. += "<span class='notice'><b>Click</b> this in-hand to select a card to draw.</span>"
		. += "<span class='notice'><b>Ctrl-Click</b> this in-hand to flip it.</span>"
		. += "<span class='notice'><b>Alt-Click</b> this in-hand to see the legacy interaction menu.</span>"
		. += "<span class='notice'><b>Drag</b> this to its associated deck to return all cards at once to it.</span>"

/obj/item/cardhand/proc/single()
	return length(cards) == 1

/obj/item/cardhand/proc/update_values()
	if(!parentdeck)
		return
	var/obj/item/deck/D = parentdeck
	hitsound = D.card_hitsound
	force = D.card_force
	throwforce = D.card_throwforce
	throw_speed = D.card_throw_speed
	throw_range = D.card_throw_range
	attack_verb = D.card_attack_verb
	resistance_flags = D.card_resistance_flags

/obj/item/cardhand/attackby(obj/O, mob/user)
	if(length(cards) == 1 && is_pen(O))
		var/datum/playingcard/P = cards[1]
		if(P.name != "Blank Card")
			to_chat(user,"<span class='notice'>You cannot write on that card.</span>")
			return
		var/t = rename_interactive(user, P, use_prefix = FALSE, actually_rename = FALSE)
		if(t && P.name == "Blank Card")
			P.name = t
		// SNOWFLAKE FOR CAG, REMOVE IF OTHER CARDS ARE ADDED THAT USE THIS.
		P.card_icon = "cag_white_card"
		update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
	else if(istype(O,/obj/item/cardhand))
		var/obj/item/cardhand/H = O
		if(H.parentdeck == parentdeck)
			H.concealed = concealed
			cards.Add(H.cards)
			qdel(H)
			update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
			return
		else
			to_chat(user, "<span class='notice'>You cannot mix cards from other decks!</span>")
			return
	..()

/obj/item/cardhand/attack_self(mob/user)
	if(length(cards) == 1)
		turn_hand(user)
		return
	if(user.get_item_by_slot(SLOT_HUD_LEFT_HAND) == src || user.get_item_by_slot(SLOT_HUD_RIGHT_HAND) == src)
		var/card = select_card_radial(user)
		remove_card(card)

/obj/item/cardhand/AltClick(mob/user)
	. = ..()
	user.set_machine(src)
	interact(user)

/obj/item/cardhand/proc/select_card_radial(mob/user)
	var/list/options = list()
	for(var/datum/playingcard/P in cards)
		// lewtodo: figure out how to add the number underneath, like how some items in inventory get them
		// check botany
		if(isnull(options[P]))
			options[P] = image(icon = 'icons/obj/playing_cards.dmi', icon_state = P.card_icon)

	var/choice = show_radial_menu(user, src, options)
	if(HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) || user.stat != CONSCIOUS || isnull(choice))
		return

	return choice


/obj/item/cardhand/proc/turn_hand(mob/user)
	concealed = !concealed
	update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
	user.visible_message("<span class='notice'>[user] [concealed ? "conceals" : "reveals"] their hand.</span>")

/obj/item/cardhand/interact(mob/user)
	var/dat = "You have:<br>"
	for(var/t in cards)
		dat += "<a href='byond://?src=[UID()];pick=[t]'>The [t]</a><br>"
	dat += "Which card will you remove next?<br>"
	dat += "<a href='byond://?src=[UID()];pick=Turn'>Turn the hand over</a>"
	var/datum/browser/popup = new(user, "cardhand", "Hand of Cards", 400, 240)
	popup.set_content(dat)
	popup.open()

/obj/item/cardhand/point_at(atom/pointed_atom)

	if(!isturf(loc))
		return

	if(length(cards) != 1)
		return ..()

	var/datum/playingcard/card = cards[1]

	if(!(pointed_atom in src) && !(pointed_atom.loc in src))
		return

	var/obj/effect/temp_visual/card_preview/draft = new /obj/effect/temp_visual/card_preview(usr, card.card_icon)
	usr.vis_contents += draft

	QDEL_IN(draft, 0.6 SECONDS)

/obj/item/cardhand/Topic(href, href_list)
	if(..())
		return
	if(usr.stat || !ishuman(usr))
		return
	var/mob/living/carbon/human/cardUser = usr
	if(href_list["pick"])
		if(href_list["pick"] == "Turn")
			turn_hand(usr)
		else
			if(cardUser.get_item_by_slot(SLOT_HUD_LEFT_HAND) == src || cardUser.get_item_by_slot(SLOT_HUD_RIGHT_HAND) == src)
				var/picked_card = href_list["pick"]
				remove_card(picked_card)
		cardUser << browse(null, "window=cardhand")


// Datum action here

/datum/action/item_action/remove_card
	name = "Remove a card - Remove a single card from the hand."
	button_overlay_icon_state = "remove_card"
	use_itemicon = FALSE

/datum/action/item_action/remove_card/IsAvailable()
	var/obj/item/cardhand/C = target
	if(length(C.cards) <= 1)
		return FALSE
	return ..()

/datum/action/item_action/remove_card/Trigger(left_click)
	if(!IsAvailable())
		return
	if(istype(target, /obj/item/cardhand))
		var/obj/item/cardhand/C = target
		return C.remove_card()
	return ..()

/datum/action/item_action/discard
	name = "Discard - Place (a) card(s) from your hand in front of you."
	button_overlay_icon_state = "discard"
	use_itemicon = FALSE

/datum/action/item_action/discard/Trigger(left_click)
	if(istype(target, /obj/item/cardhand))
		var/obj/item/cardhand/C = target
		return C.discard()
	return ..()

// No more datum action here

/// Create a new card-hand from a list of cards in the other hand.
/obj/item/cardhand/proc/split(list/cards_in_new_hand)
	if(length(cards) == 0 || length(cards_in_new_hand) == 0)
		return

	var/obj/item/cardhand/new_hand = new()
	for(var/datum/playingcard/card in cards_in_new_hand)
		new_hand.cards += card
		cards -= card

	new_hand.parentdeck = parentdeck
	new_hand.update_values()
	new_hand.concealed = concealed
	new_hand.update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)

	return new_hand

/// Draw a card from a card hand.
/obj/item/cardhand/proc/remove_card(datum/playingcard/picked_card)
	var/mob/living/carbon/user = usr

	if(user.incapacitated() || !Adjacent(user))
		return

	if(!picked_card)
		var/pickablecards = list()
		for(var/datum/playingcard/P in cards)
			pickablecards[P.name] = P
		var/selected_card = tgui_input_list(usr, "Which card do you want to remove from the hand?", "Remove Card", pickablecards)
		picked_card = pickablecards[selected_card]
		if(!picked_card)
			return

	if(QDELETED(src))
		return


	if(loc != user) // Don't want people teleporting cards
		return
	user.visible_message("<span class='notice'>[user] draws a card from [user.p_their()] hand.</span>", "<span class='notice'>You take the [picked_card] from your hand.</span>")

	var/obj/item/cardhand/H = new(get_turf(src))
	user.put_in_hands(H)
	H.cards += picked_card
	cards -= picked_card
	H.parentdeck = parentdeck
	H.update_values()
	H.concealed = concealed
	H.update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
	if(!length(cards))
		qdel(src)
		return
	update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)

/obj/item/cardhand/proc/discard()
	var/mob/living/carbon/user = usr

	var/maxcards = min(length(cards), 5)
	var/discards = tgui_input_number(usr, "How many cards do you want to discard? You may discard up to [maxcards] card(s)", "Discard Cards", max_value = maxcards)
	if(discards > maxcards)
		return
	for(var/i in 1 to discards)
		var/list/to_discard = list()
		for(var/datum/playingcard/P in cards)
			to_discard[P.name] = P
		var/discarding = tgui_input_list(usr, "Which card do you wish to put down?", "Discard", to_discard)

		if(!discarding)
			continue

		if(loc != user) // Don't want people teleporting cards
			return

		if(QDELETED(src))
			return

		var/datum/playingcard/card = to_discard[discarding]
		to_discard.Cut()

		var/obj/item/cardhand/H = new type(get_turf(src))
		H.cards += card
		cards -= card
		H.concealed = FALSE
		H.parentdeck = parentdeck
		H.update_values()
		H.direction = user.dir
		H.update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
		if(length(cards))
			update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
		if(length(H.cards))
			user.visible_message("<span class='notice'>[user] plays the [discarding].</span>", "<span class='notice'>You play the [discarding].</span>")
		H.loc = get_step(user, user.dir)

	if(!length(cards))
		qdel(src)

/obj/item/cardhand/update_appearance(updates=ALL)
	if(!length(cards))
		return
	if(length(cards) <= 2)
		for(var/X in actions)
			var/datum/action/A = X
			A.UpdateButtons()
	..()

/obj/item/cardhand/update_name()
	. = ..()
	if(length(cards) > 1)
		name = "hand of [length(cards)] cards"
	else
		name = "playing card"

/obj/item/cardhand/update_desc()
	. = ..()
	if(length(cards) > 1)
		desc = "Some playing cards."
	else
		if(concealed)
			desc = "A playing card. You can only see the back."
		else
			var/datum/playingcard/card = cards[1]
			desc = "\A [card.name]."

/obj/item/cardhand/update_icon_state()
	return

/obj/item/cardhand/update_overlays()
	. = ..()
	var/matrix/M = matrix()
	switch(direction)
		if(NORTH)
			M.Translate( 0,  0)
		if(SOUTH)
			M.Turn(180)
			M.Translate( 0,  4)
		if(WEST)
			M.Turn(-90)
			M.Translate( 3,  0)
		if(EAST)
			M.Turn(90)
			M.Translate(-2,  0)

	if(length(cards) == 1)
		var/datum/playingcard/P = cards[1]
		var/image/I = new(icon, (concealed ? "[P.back_icon]" : "[P.card_icon]") )
		I.transform = M
		I.pixel_x += (-5+rand(10))
		I.pixel_y += (-5+rand(10))
		. += I
		return

	var/offset = FLOOR(20/length(cards) + 1, 1)
	// var/i = 0
	for(var/i in 1 to length(cards))
		var/datum/playingcard/P = cards[i]
		if(i >= 20)
			// skip the rest and just draw the last one on top
			. += render_card(cards[length(cards)], M, i, offset)
			break
		. += render_card(P, M, i, offset)
		i++

/obj/item/cardhand/proc/render_card(datum/playingcard/card, matrix/mat, index, offset)
	var/image/I = new(icon, (concealed ? "[card.back_icon]" : "[card.card_icon]") )
	switch(direction)
		if(SOUTH)
			I.pixel_x = 8 - (offset * index)
		if(WEST)
			I.pixel_y = -6 + (offset * index)
		if(EAST)
			I.pixel_y = 8 - (offset * index)
		else
			I.pixel_x = -7 + (offset * index)
	I.transform = mat
	return I

/obj/item/cardhand/dropped(mob/user)
	..()
	if(user)
		direction = user.dir
	else
		direction = NORTH
	update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)

/obj/item/cardhand/pickup(mob/user as mob)
	. = ..()
	direction = NORTH
	update_appearance(UPDATE_NAME|UPDATE_DESC|UPDATE_OVERLAYS)
