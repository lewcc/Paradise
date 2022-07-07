/obj/item/clothing/accessory/holster
	name = "shoulder holster"
	desc = "A handgun holster."
	icon_state = "holster"
	item_color = "holster"
	slot = ACCESSORY_SLOT_UTILITY
	var/list/holster_allow = list(/obj/item/gun)
	var/obj/item/gun/holstered = null
	actions_types = list(/datum/action/item_action/accessory/holster)
	w_class = WEIGHT_CLASS_NORMAL // so it doesn't fit in pockets

/obj/item/clothing/accessory/holster/Destroy()
	if(holstered?.loc == src) // Gun still in the holster
		holstered.forceMove(loc)
	holstered = null
	return ..()

//subtypes can override this to specify what can be holstered
/obj/item/clothing/accessory/holster/proc/can_holster(obj/item/gun/W)
	if(!W.can_holster)
		return FALSE
	else if(!is_type_in_list(W, holster_allow))
		return FALSE
	else
		return TRUE

/obj/item/clothing/accessory/holster/attack_self()
	var/holsteritem = usr.get_active_hand()
	if(!holstered)
		holster(holsteritem, usr)
	else
		unholster(usr)

/obj/item/clothing/accessory/holster/proc/holster(obj/item/I, mob/user as mob)
	if(holstered)
		to_chat(user, span_warning("There is already a [holstered] holstered here!"))
		return

	if(!istype(I, /obj/item/gun))
		to_chat(user, span_warning("Only guns can be holstered!"))
		return

	var/obj/item/gun/W = I
	if(!can_holster(W))
		to_chat(user, span_warning("This [W.name] won't fit in [src]!"))
		return

	if(!user.canUnEquip(W, 0))
		to_chat(user, span_warning("You can't let go of [W]!"))
		return

	holstered = W
	user.unEquip(holstered)
	holstered.loc = src
	holstered.add_fingerprint(user)
	user.visible_message(span_notice("[user] holsters [holstered]."), span_notice("You holster [holstered]."))

/obj/item/clothing/accessory/holster/proc/unholster(mob/user as mob)
	if(!holstered)
		return

	if(istype(user.get_active_hand(),/obj) && istype(user.get_inactive_hand(),/obj))
		to_chat(user, span_warning("You need an empty hand to draw [holstered]!"))
	else
		if(user.a_intent == INTENT_HARM)
			usr.visible_message(span_warning("[user] draws [holstered], ready to shoot!</span>"), \
			span_warning("You draw [holstered], ready to shoot!"))
		else
			user.visible_message(span_notice("[user] draws [holstered], pointing it at the ground."), \
			span_notice("You draw [holstered], pointing it at the ground."))
		user.put_in_hands(holstered)
		holstered.add_fingerprint(user)
		holstered = null

/obj/item/clothing/accessory/holster/attack_hand(mob/user as mob)
	if(has_suit)	//if we are part of a suit
		if(holstered)
			unholster(user)
		return

	..(user)

/obj/item/clothing/accessory/holster/attackby(obj/item/W as obj, mob/user as mob, params)
	holster(W, user)

/obj/item/clothing/accessory/holster/emp_act(severity)
	if(holstered)
		holstered.emp_act(severity)
	..()

/obj/item/clothing/accessory/holster/examine(mob/user)
	. = ..()
	if(holstered)
		. += "A [holstered] is holstered here."
	else
		. += "It is empty."

/obj/item/clothing/accessory/holster/on_attached(obj/item/clothing/under/S, mob/user as mob)
	..()
	has_suit.verbs += /obj/item/clothing/accessory/holster/verb/holster_verb

/obj/item/clothing/accessory/holster/on_removed(mob/user as mob)
	has_suit.verbs -= /obj/item/clothing/accessory/holster/verb/holster_verb
	..()

//For the holster hotkey
/obj/item/clothing/accessory/holster/verb/holster_verb()
	set name = "Holster"
	set category = "Object"
	set src in usr
	if(!istype(usr, /mob/living)) return
	if(usr.stat) return

	var/obj/item/clothing/accessory/holster/H = null
	if(istype(src, /obj/item/clothing/accessory/holster))
		H = src
	else if(istype(src, /obj/item/clothing/under))
		var/obj/item/clothing/under/S = src
		if(S.accessories.len)
			H = locate() in S.accessories

	if(!H)
		to_chat(usr, span_warning("Something is very wrong."))

	if(!H.holstered)
		if(!istype(usr.get_active_hand(), /obj/item/gun))
			to_chat(usr, span_warning("You need your gun equiped to holster it."))
			return
		var/obj/item/gun/W = usr.get_active_hand()
		H.holster(W, usr)
	else
		H.unholster(usr)

/obj/item/clothing/accessory/holster/armpit
	name = "shoulder holster"
	desc = "A worn-out handgun holster. Perfect for concealed carry"
	icon_state = "holster"
	item_color = "holster"
	holster_allow = list(/obj/item/gun/projectile, /obj/item/gun/energy/detective)

/obj/item/clothing/accessory/holster/waist
	name = "shoulder holster"
	desc = "A handgun holster. Made of expensive leather."
	icon_state = "holster"
	item_color = "holster_low"
