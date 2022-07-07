//Procedures in this file: Robotic limbs attachment, meat limbs attachment
//////////////////////////////////////////////////////////////////
//						LIMB SURGERY							//
//////////////////////////////////////////////////////////////////

/datum/surgery/amputation
	name = "Amputation"
	steps = list(/datum/surgery_step/generic/amputate)
	possible_locs = list("head","l_arm", "l_hand","r_arm","r_hand","r_leg","r_foot","l_leg","l_foot","groin")


/datum/surgery/amputation/can_start(mob/user, mob/living/carbon/target)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/organ/external/affected = H.get_organ(user.zone_selected)
		if(!affected)
			return FALSE
		if(affected.is_robotic())
			return FALSE
		if(affected.limb_flags & CANNOT_DISMEMBER)
			return FALSE

		return TRUE


/datum/surgery/reattach
	name = "Limb Reattachment"
	steps = list(/datum/surgery_step/limb/attach,/datum/surgery_step/limb/connect)
	possible_locs = list("head","l_arm", "l_hand","r_arm","r_hand","r_leg","r_foot","l_leg","l_foot","groin")

/datum/surgery/reattach/can_start(mob/user, mob/living/carbon/target)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/organ/external/affected = H.get_organ(user.zone_selected)
		if(ismachineperson(target))
			// RIP bi-centennial man
			return FALSE
		if(!affected)
			return TRUE
	return FALSE

/datum/surgery/reattach_synth
	name = "Synthetic Limb Reattachment"
	steps = list(/datum/surgery_step/limb/attach/robo)
	possible_locs = list("head","l_arm", "l_hand","r_arm","r_hand","r_leg","r_foot","l_leg","l_foot","groin")

/datum/surgery/reattach_synth/can_start(mob/user, mob/living/carbon/target)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/organ/external/affected = H.get_organ(user.zone_selected)
		if(!affected)
			return TRUE

		return FALSE


/datum/surgery/robo_attach
	name = "Apply Robotic Prosthetic"
	steps = list(/datum/surgery_step/limb/mechanize)
	possible_locs = list("head","l_arm", "l_hand","r_arm","r_hand","r_leg","r_foot","l_leg","l_foot","groin")

/datum/surgery/robo_attach/can_start(mob/user, mob/living/carbon/target)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/organ/external/affected = H.get_organ(user.zone_selected)
		if(!affected)
			return TRUE

		return FALSE

/datum/surgery_step/limb/
	can_infect = FALSE
/datum/surgery_step/limb/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!hasorgans(target))
		return FALSE
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if(affected)
		return FALSE
	var/list/organ_data = target.dna.species.has_limbs["[target_zone]"]
	return !isnull(organ_data)

/datum/surgery_step/limb/attach
	name = "attach limb"
	allowed_tools = list(/obj/item/organ/external = 100)

	time = 32

/datum/surgery_step/limb/attach/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!..())
		return FALSE
	if(!istype(tool, /obj/item/organ/external))
		return FALSE
	var/obj/item/organ/external/E = tool
	if(target.get_organ(E.limb_name))
		// This catches attaching an arm to a missing hand while the arm is still there
		to_chat(user, span_warning("[target] already has an [E.name]!"))
		return FALSE
	if(E.limb_name != target_zone)
		// This ensures you must be aiming at the appropriate location to attach
		// this limb. (Can't aim at a missing foot to re-attach a missing arm)
		to_chat(user, span_warning("The [E.name] does not go there."))
		return FALSE
	// if(E.parent_organ && !target.get_organ(E.parent_organ))
	// 	// No rayman allowed
	// 	return FALSE
	if(!is_correct_limb(E))
		to_chat(user, span_warning("This is not the correct limb type for this surgery!"))
		return FALSE

	return TRUE


/datum/surgery_step/limb/attach/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/E = tool
	user.visible_message("[user] starts attaching [E.name] to [target]'s [E.amputation_point].", \
	"You start attaching [E.name] to [target]'s [E.amputation_point].")

/datum/surgery_step/limb/attach/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/E = tool
	user.visible_message(span_notice("[user] has attached [target]'s [E.name] to the [E.amputation_point]."),	\
	span_notice("You have attached [target]'s [E.name] to the [E.amputation_point]."))
	attach_limb(user, target, E)
	return TRUE

/datum/surgery_step/limb/attach/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/E = tool
	user.visible_message("<span class='alert'>[user]'s hand slips, damaging [target]'s [E.amputation_point]!</span>", \
	"<span class='alert'>Your hand slips, damaging [target]'s [E.amputation_point]!</span>")
	target.apply_damage(10, BRUTE, null, sharp = TRUE)
	return FALSE


/datum/surgery_step/limb/attach/proc/is_correct_limb(obj/item/organ/external/E)
	if(E.is_robotic())
		return FALSE
	return TRUE

/datum/surgery_step/limb/attach/proc/attach_limb(mob/living/user, mob/living/carbon/human/target, obj/item/organ/external/E)
	user.unEquip(E)
	E.replaced(target)
	target.update_body()
	target.updatehealth()
	target.UpdateDamageIcon()


// This is a step that handles robotic limb attachment while skipping the "connect" step
// THIS IS DISTINCT FROM USING A CYBORG LIMB TO CREATE A NEW LIMB ORGAN
/datum/surgery_step/limb/attach/robo
	name = "attach robotic limb"

/datum/surgery_step/limb/attach/robo/is_correct_limb(obj/item/organ/external/E)
	if(!E.is_robotic())
		return FALSE
	return TRUE

/datum/surgery_step/limb/attach/robo/attach_limb(mob/living/user, mob/living/carbon/human/target, obj/item/organ/external/E)
	// Fixes fabricator IPC heads
	if(!(E.dna) && E.is_robotic() && target.dna)
		E.set_dna(target.dna)
	..()
	if(E.limb_name == "head")
		var/obj/item/organ/external/head/H = target.get_organ("head")
		var/datum/robolimb/robohead = GLOB.all_robolimbs[H.model]
		if(robohead.is_monitor) //Ensures that if an IPC gets a head that's got a human hair wig attached to their body, the hair won't wipe.
			H.h_style = "Bald"
			H.f_style = "Shaved"
			target.m_styles["head"] = "None"


/datum/surgery_step/limb/connect
	name = "connect limb"
	allowed_tools = list(
	/obj/item/hemostat = 100,	\
	/obj/item/stack/cable_coil = 90, 	\
	/obj/item/assembly/mousetrap = 25
	)
	can_infect = TRUE

	time = 32


/datum/surgery_step/limb/connect/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(!hasorgans(target))
		return FALSE
	return TRUE

/datum/surgery_step/limb/connect/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/E = target.get_organ(target_zone)
	user.visible_message("[user] starts connecting tendons and muscles in [target]'s [E.amputation_point] with [tool].", \
	"You start connecting tendons and muscle in [target]'s [E.amputation_point].")

/datum/surgery_step/limb/connect/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/E = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] has connected tendons and muscles in [target]'s [E.amputation_point] with [tool]."),	\
	span_notice("You have connected tendons and muscles in [target]'s [E.amputation_point] with [tool]."))
	target.update_body()
	target.updatehealth()
	target.UpdateDamageIcon()
	return TRUE

/datum/surgery_step/limb/connect/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/E = target.get_organ(target_zone)
	user.visible_message("<span class='alert'>[user]'s hand slips, damaging [target]'s [E.amputation_point]!</span>", \
	"<span class='alert'>Your hand slips, damaging [target]'s [E.amputation_point]!</span>")
	target.apply_damage(10, BRUTE, null, sharp = TRUE)
	return FALSE

/datum/surgery_step/limb/mechanize
	name = "apply robotic prosthetic"
	allowed_tools = list(/obj/item/robot_parts = 100)

	time = 32

/datum/surgery_step/limb/mechanize/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if(..())
		var/obj/item/robot_parts/p = tool
		if(p.part)
			if(!(target_zone in p.part))
				to_chat(user, span_warning("\The [tool] does not go there!"))
				return FALSE
		return isnull(target.get_organ(target_zone))

/datum/surgery_step/limb/mechanize/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		user.visible_message("[user] starts attaching \the [tool] to [target].", \
		"You start attaching \the [tool] to [target].")

/datum/surgery_step/limb/mechanize/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/robot_parts/L = tool
	user.visible_message(span_notice("[user] has attached \the [tool] to [target]."),	\
	span_notice("You have attached \the [tool] to [target]."))

	if(L.part)
		for(var/part_name in L.part)
			if(!isnull(target.get_organ(part_name)))
				continue
			var/list/organ_data = target.dna.species.has_limbs["[part_name]"]
			if(!organ_data)
				continue
			// This will break if there's more than one stump ever
			var/obj/item/organ/external/stump = target.bodyparts_by_name["limb stump"]
			if(stump)
				stump.remove(target)
			var/new_limb_type = organ_data["path"]
			var/obj/item/organ/external/new_limb = new new_limb_type(target)
			new_limb.robotize(L.model_info)
			if(L.sabotaged)
				new_limb.sabotaged = TRUE
	target.update_body()
	target.updatehealth()
	target.UpdateDamageIcon()

	qdel(tool)

	return TRUE

/datum/surgery_step/limb/mechanize/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message("<span class='alert'>[user]'s hand slips, damaging [target]'s flesh!</span>", \
	"<span class='alert'>Your hand slips, damaging [target]'s flesh!</span>")
	target.apply_damage(10, BRUTE, null, sharp = TRUE)
	return FALSE
