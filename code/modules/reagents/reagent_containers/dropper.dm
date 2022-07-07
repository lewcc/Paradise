////////////////////////////////////////////////////////////////////////////////
/// 								Droppers.								 ///
////////////////////////////////////////////////////////////////////////////////

/obj/item/reagent_containers/dropper
	name = "dropper"
	desc = "A dropper. Transfers 5 units."
	icon_state = "dropper"
	item_state = "dropper"
	belt_icon = "dropper"
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = list(1, 2, 3, 4, 5)
	volume = 5

/obj/item/reagent_containers/dropper/on_reagent_change()
	if(!reagents.total_volume)
		icon_state = "[initial(icon_state)]"
	else
		icon_state = "[initial(icon_state)]1"

/obj/item/reagent_containers/dropper/attack(mob/living/M, mob/living/user, def_zone)
	return

/obj/item/reagent_containers/dropper/afterattack(atom/target, mob/user, proximity)
	if(!proximity)
		return
	var/to_transfer = 0
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(!reagents.total_volume)
			return
		if(user != C)
			visible_message(span_danger("[user] begins to drip something into [C]'s eyes!"))
			if(!do_mob(user, C, 30))
				return
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			var/obj/item/safe_thing = null

			if(H.glasses)
				safe_thing = H.glasses
			if(H.wear_mask )
				if(H.wear_mask.flags_cover & MASKCOVERSEYES)
					safe_thing = H.wear_mask
			if(H.head)
				if(H.head.flags_cover & MASKCOVERSEYES)
					safe_thing = H.head

			if(safe_thing)
				visible_message(span_danger("[user] tries to drip something into [H]'s eyes, but fails!"))

				reagents.reaction(safe_thing, REAGENT_TOUCH)
				to_transfer = reagents.remove_any(amount_per_transfer_from_this)

				to_chat(user, span_notice("You transfer [to_transfer] units of the solution."))
				return

		visible_message(span_danger("[user] drips something into [C]'s eyes!"))
		reagents.reaction(C, REAGENT_TOUCH)

		var/list/injected = list()
		for(var/datum/reagent/R in reagents.reagent_list)
			injected += R.name
		var/contained = english_list(injected)
		add_attack_logs(user, C, "Dripped with [src] containing ([contained]), transfering [to_transfer]")

		to_transfer = reagents.trans_to(C, amount_per_transfer_from_this)
		to_chat(user, span_notice("You transfer [to_transfer] units of the solution."))

	if(isobj(target))
		if(!target.reagents)
			return

		if(reagents.total_volume)
			if(!target.is_open_container() && !(istype(target, /obj/item/reagent_containers/food) && !istype(target, /obj/item/reagent_containers/food/pill)) && !istype(target, /obj/item/clothing/mask/cigarette))
				to_chat(user, span_warning("You cannot directly fill this object."))
				return

			if(target.reagents.total_volume >= target.reagents.maximum_volume)
				to_chat(user, span_warning("[target] is full."))
				return

			to_transfer = reagents.trans_to(target, amount_per_transfer_from_this)
			to_chat(user, span_notice("You transfer [to_transfer] units of the solution."))

		else
			if(!target.is_open_container() && !istype(target, /obj/structure/reagent_dispensers))
				to_chat(user, span_warning("You cannot directly remove reagents from [target]."))
				return

			if(!target.reagents.total_volume)
				to_chat(user, span_warning("[target] is empty."))
				return

			to_transfer = target.reagents.trans_to(src, amount_per_transfer_from_this)

			to_chat(user, span_notice("You fill [src] with [to_transfer] units of the solution."))

/obj/item/reagent_containers/dropper/cyborg
	name = "Industrial Dropper"
	desc = "A larger dropper. Transfers 10 units."
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	volume = 10

/obj/item/reagent_containers/dropper/precision
	name = "pipette"
	desc = "A high precision pippette. Holds 1 unit."
	icon_state = "pipette"
	amount_per_transfer_from_this = 1
	possible_transfer_amounts = list(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1)
	volume = 1

//Syndicate item. Virus transmitting mini hypospray
/obj/item/reagent_containers/dropper/precision/viral_injector

/obj/item/reagent_containers/dropper/precision/viral_injector/attack(mob/living/M, mob/living/user, def_zone)
	if(M.can_inject(user, TRUE))
		to_chat(user, span_warning("You stealthily stab [M] with [src]."))
		if(reagents.total_volume && M.reagents)
			var/list/injected = list()
			for(var/datum/reagent/R in reagents.reagent_list)
				injected += R.name
				var/datum/reagent/blood/B = R

				if(istype(B) && B.data["viruses"])
					var/virList = list()
					for(var/dis in B.data["viruses"])
						var/datum/disease/D = dis
						var/virusData = D.name
						var/english_symptoms = list()
						var/datum/disease/advance/A = D
						if(A)
							for(var/datum/symptom/S in A.symptoms)
								english_symptoms += S.name
							virusData += " ([english_list(english_symptoms)])"
						virList += virusData
					var/str = english_list(virList)
					add_attack_logs(user, M, "Infected with [str].")

				reagents.reaction(M, REAGENT_INGEST, reagents.total_volume)
				reagents.trans_to(M, 1)

			var/contained = english_list(injected)
			add_attack_logs(user, M, "Injected with [src] containing ([contained])")
