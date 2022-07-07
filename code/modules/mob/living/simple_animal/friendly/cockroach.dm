/mob/living/simple_animal/cockroach
	name = "cockroach"
	desc = "This station is just crawling with bugs."
	icon_state = "cockroach"
	icon_dead = "cockroach"
	health = 1
	maxHealth = 1
	turns_per_move = 5
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 270
	maxbodytemp = INFINITY
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_biotypes = MOB_ORGANIC | MOB_BUG
	mob_size = MOB_SIZE_TINY
	response_help  = "pokes"
	response_disarm = "shoos"
	response_harm   = "splats"
	density = FALSE
	ventcrawler = VENTCRAWLER_ALWAYS
	gold_core_spawnable = FRIENDLY_SPAWN
	var/squish_chance = 50
	loot = list(/obj/effect/decal/cleanable/insectguts)
	del_on_death = 1

/mob/living/simple_animal/cockroach/can_die()
	return ..() && !SSticker.cinematic //If the nuke is going off, then cockroaches are invincible. Keeps the nuke from killing them, cause cockroaches are immune to nukes.

/mob/living/simple_animal/cockroach/Crossed(atom/movable/AM, oldloc)
	if(isliving(AM))
		var/mob/living/A = AM
		if(A.mob_size > MOB_SIZE_SMALL)
			if(prob(squish_chance))
				A.visible_message(span_notice("\The [A] squashed \the [name]."), span_notice("You squashed \the [name]."))
				death()
			else
				visible_message(span_notice("\The [name] avoids getting crushed."))
	else if(istype(AM, /obj/structure))
		visible_message(span_notice("As \the [AM] moved over \the [name], it was crushed."))
		death()

/mob/living/simple_animal/cockroach/ex_act() //Explosions are a terrible way to handle a cockroach.
	return

