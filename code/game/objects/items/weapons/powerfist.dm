/obj/item/melee/powerfist
	name = "power-fist"
	desc = "A metal gauntlet with a piston-powered ram ontop for that extra 'ompfh' in your punch."
	icon_state = "powerfist"
	item_state = "powerfist"
	flags = CONDUCT
	attack_verb = list("whacked", "fisted", "power-punched")
	force = 12
	throwforce = 10
	throw_range = 7
	w_class = WEIGHT_CLASS_NORMAL
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 40)
	resistance_flags = FIRE_PROOF
	origin_tech = "combat=5;powerstorage=3;syndicate=3"
	var/click_delay = 1.5
	var/fisto_setting = 1
	var/gasperfist = 3
	var/obj/item/tank/internals/tank = null //Tank used for the gauntlet's piston-ram.


/obj/item/melee/powerfist/Destroy()
	QDEL_NULL(tank)
	return ..()

/obj/item/melee/powerfist/examine(mob/user)
	. = ..()
	if(!in_range(user, src))
		. += span_notice("You'll need to get closer to see any more.")
	else if(tank)
		. += span_notice("[bicon(tank)] It has [tank] mounted onto it.")

/obj/item/melee/powerfist/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/tank/internals))
		if(!tank)
			var/obj/item/tank/internals/IT = W
			if(IT.volume <= 3)
				to_chat(user, span_warning("[IT] is too small for [src]."))
				return
			updateTank(W, 0, user)
			return
	return ..()

/obj/item/melee/powerfist/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	switch(fisto_setting)
		if(1)
			fisto_setting = 2
		if(2)
			fisto_setting = 3
		if(3)
			fisto_setting = 1
	to_chat(user, span_notice("You tweak [src]'s piston valve to [fisto_setting]."))

/obj/item/melee/powerfist/screwdriver_act(mob/user, obj/item/I)
	if(!tank)
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	updateTank(tank, 1, user)

/obj/item/melee/powerfist/proc/updateTank(obj/item/tank/thetank, removing = 0, mob/living/carbon/human/user)
	if(removing)
		if(!tank)
			to_chat(user, span_notice("[src] currently has no tank attached to it."))
			return
		to_chat(user, span_notice("You detach [thetank] from [src]."))
		tank.forceMove(get_turf(user))
		user.put_in_hands(tank)
		tank = null
	if(!removing)
		if(tank)
			to_chat(user, span_warning("[src] already has a tank."))
			return
		if(!user.unEquip(thetank))
			return
		to_chat(user, span_notice("You hook [thetank] up to [src]."))
		tank = thetank
		thetank.forceMove(src)


/obj/item/melee/powerfist/attack(mob/living/target, mob/living/user)
	if(!tank)
		to_chat(user, span_warning("[src] can't operate without a source of gas!"))
		return
	if(tank && !tank.air_contents.remove(gasperfist * fisto_setting))
		to_chat(user, span_warning("[src]'s piston-ram lets out a weak hiss, it needs more gas!"))
		playsound(loc, 'sound/effects/refill.ogg', 50, 1)
		return

	user.do_attack_animation(target)

	target.apply_damage(force * fisto_setting, BRUTE)
	target.visible_message(span_danger("[user]'s powerfist lets out a loud hiss as [user.p_they()] punch[user.p_es()] [target.name]!"), \
		span_userdanger("You cry out in pain as [user]'s punch flings you backwards!"))
	new /obj/effect/temp_visual/kinetic_blast(target.loc)
	playsound(loc, 'sound/weapons/resonator_blast.ogg', 50, 1)
	playsound(loc, 'sound/weapons/genhit2.ogg', 50, 1)

	var/atom/throw_target = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))

	target.throw_at(throw_target, 5 * fisto_setting, 0.2)

	add_attack_logs(user, target, "POWER FISTED with [src]")

	user.changeNext_move(CLICK_CD_MELEE * click_delay)
