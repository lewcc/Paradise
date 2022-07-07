/obj/structure/closet/secure_closet
	name = "secure locker"
	desc = "It's an immobile card-locked storage unit."
	icon = 'icons/obj/closet.dmi'
	icon_state = "secure"
	open_door_sprite = "secure_door"
	opened = FALSE
	locked = TRUE
	can_be_emaged = TRUE
	max_integrity = 250
	armor = list(MELEE = 30, BULLET = 50, LASER = 50, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 80)
	damage_deflection = 20

/obj/structure/closet/secure_closet/can_open()
	if(!..())
		return FALSE
	if(locked)
		return FALSE
	return ..()

/obj/structure/closet/secure_closet/close()
	if(..())
		if(broken)
			update_icon()
		return TRUE
	else
		return FALSE

/obj/structure/closet/secure_closet/emp_act(severity)
	for(var/obj/O in src)
		O.emp_act(severity)
	if(!broken)
		if(prob(50/severity))
			locked = !locked
			update_icon()
		if(prob(20/severity) && !opened)
			if(!locked)
				open()
			else
				req_access = list()
				req_access += pick(get_all_accesses())
	..()

/obj/structure/closet/secure_closet/proc/togglelock(mob/user)
	if(opened)
		to_chat(user, span_notice("Close the locker first."))
		return
	if(broken)
		to_chat(user, span_warning("The locker appears to be broken."))
		return
	if(user.loc == src)
		to_chat(user, span_notice("You can't reach the lock from inside."))
		return
	if(allowed(user))
		locked = !locked
		visible_message(span_notice("The locker has been [locked ? null : "un"]locked by [user]."))
		update_icon()
	else
		to_chat(user, span_notice("Access Denied"))

/obj/structure/closet/secure_closet/closed_item_click(mob/user)
	togglelock(user)

/obj/structure/closet/secure_closet/AltClick(mob/user)
	if(opened)
		return ..()
	if(Adjacent(user))
		togglelock(user)

/obj/structure/closet/secure_closet/emag_act(mob/user)
	if(!broken)
		broken = TRUE
		locked = FALSE
		add_overlay("sparking")
		to_chat(user, span_notice("You break the lock on [src]."))
		addtimer(CALLBACK(src, .proc/update_icon), 1 SECONDS)

/obj/structure/closet/secure_closet/attack_hand(mob/user)
	add_fingerprint(user)
	if(locked)
		togglelock(user)
	else
		toggle(user)

/obj/structure/closet/secure_closet/verb/verb_togglelock()
	set src in oview(1) // One square distance
	set category = "Object"
	set name = "Toggle Lock"

	if(usr.incapacitated()) // Don't use it if you're not able to! Checks for stuns, ghost and restrain
		return

	if(ishuman(usr)||isrobot(usr))
		add_fingerprint(usr)
		togglelock(usr)
		return
	to_chat(usr, span_warning("This mob type can't use this verb."))

/obj/structure/closet/secure_closet/update_overlays() //Putting the welded stuff in update_overlays() so it's easy to overwrite for special cases (Fridges, cabinets, and whatnot)
	cut_overlays()
	if(opened)
		add_overlay(open_door_sprite)
		return
	if(welded)
		add_overlay("welded")
	if(broken)
		return
	if(locked)
		add_overlay("locked")
	else
		add_overlay("unlocked")

/obj/structure/closet/secure_closet/container_resist(mob/living/L)
	var/breakout_time = 2 //2 minutes by default
	if(opened)
		if(L.loc == src)
			L.forceMove(get_turf(src)) // Let's just be safe here
		return //Door's open... wait, why are you in it's contents then?
	if(!locked && !welded)
		return //It's a secure closet, but isn't locked. Easily escapable from, no need to 'resist'

	//okay, so the closet is either welded or locked... resist!!!
	to_chat(L, span_warning("You lean on the back of \the [src] and start pushing the door open. (this will take about [breakout_time] minutes)"))
	for(var/mob/O in viewers(src))
		O.show_message(span_danger("[src] begins to shake violently!"), 1)


	spawn(0)
		if(do_after(usr,(breakout_time*60*10), target = src)) //minutes * 60seconds * 10deciseconds
			if(!src || !L || L.stat != CONSCIOUS || L.loc != src || opened) //closet/user destroyed OR user dead/unconcious OR user no longer in closet OR closet opened
				return

			//Perform the same set of checks as above for weld and lock status to determine if there is even still a point in 'resisting'...
			if(!locked && !welded)
				return

			//Well then break it!
			desc = "It appears to be broken."
			broken = TRUE
			locked = FALSE
			welded = FALSE
			update_icon()
			to_chat(usr, span_warning("You successfully break out!"))
			for(var/mob/O in viewers(L.loc))
				O.show_message(span_danger("\the [usr] successfully broke out of \the [src]!"), 1)
			if(istype(loc, /obj/structure/bigDelivery)) //Do this to prevent contents from being opened into nullspace (read: bluespace)
				var/obj/structure/bigDelivery/BD = loc
				BD.attack_hand(usr)
			open()
