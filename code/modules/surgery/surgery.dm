///Datum Surgery Helpers//
/datum/surgery
	/// Name of the surgery
	var/name
	/// Description of the surgery
	var/desc
	/// How far along we are in a surgery being performed.
	var/status = 1
	/// Surgical steps that go into performing this procedure
	var/list/steps = list()
	/// Whether this surgery can be stopped after the first step with a cautery
	var/can_cancel = TRUE
	/// If we're currently performing a step
	var/step_in_progress = FALSE
	/// Location of the surgery
	var/location = BODY_ZONE_CHEST
	/// Whether we can perform the surgery on a robotic limb
	var/requires_organic_bodypart = TRUE							//Prevents you from performing an operation on robotic limbs
	/// Whether you need to remove clothes to perform the surgery
	var/ignore_clothes = TRUE
	/// Body locations this surgery can be performed on
	var/list/possible_locs = list()
	/// Surgery is only available if the target bodypart is present (or if it's missing)
	var/requires_bodypart = TRUE
	/// Surgery step speed modifier
	var/speed_modifier = 0
	/// Some surgeries might work on limbs that don't really exist
	var/requires_real_bodypart = FALSE
	/// Does the victim (patient) need to be lying down?
	var/lying_required = TRUE
	/// Can the surgery be performed on yourself?
	var/self_operable = FALSE
	/// Don't show this surgery if this type exists. Set to /datum/surgery if you want to hide a "base" surgery.
	var/replaced_by
	/// Mobs on which this can be performed
	var/list/allowed_mob = list(/mob/living/carbon/human)
	/// Target of the surgery
	var/mob/living/carbon/target
	/// Body part the surgery is currently being performed on.
	var/obj/item/organ/organ_ref

/datum/surgery/New(atom/surgery_target, surgery_location, surgery_bodypart)
	..()
	if(!surgery_target)
		return
	target = surgery_target
	target.surgeries += src
	if(surgery_location)
		location = surgery_location
	if(!surgery_bodypart)
		return
	organ_ref = surgery_bodypart

/datum/surgery/Destroy()
	if(target)
		target.surgeries -= src
	target = null
	organ_ref = null
	return ..()

/**
 * Whether or not we can start this surgery.
 * If this returns FALSE, this surgery won't show up in the list.
 */
/datum/surgery/proc/can_start(mob/user, mob/living/carbon/target)
	if(replaced_by == /datum/surgery)
		return FALSE

	return TRUE

/**
 * Try to perform the next step in the current operation.
 * This gets called in the attack chain, and as such returning FALSE in here means that the target
 * will be hit with whatever's in your hand.
 *
 * TODO Document what the return type here means
 */
/datum/surgery/proc/next_step(mob/user, mob/living/carbon/target)
	if(location != user.zone_selected)
		return FALSE

	if(step_in_progress)
		return FALSE

	var/datum/surgery_step/step = get_surgery_step()
	if(step)
		var/obj/item/tool = user.get_active_hand()
		if(step.try_op(user, target, user.zone_selected, tool, src))
			return TRUE
		if(tool && tool.flags & SURGICALTOOL)
			to_chat(user, "<span class='warning'>This step requires a different tool!</span>")
			return TRUE
	return FALSE

/**
 * Get the current surgery step we're on
 */
/datum/surgery/proc/get_surgery_step()
	var/step_type = steps[status]
	return new step_type

/**
 * Get the next step in the current surgery, or null if we're on the last one.
 */
/datum/surgery/proc/get_surgery_next_step()
	if(status < steps.len)
		var/step_type = steps[status + 1]
		return new step_type
	else
		return null

/datum/surgery/proc/complete(mob/living/carbon/human/target)
	target.surgeries -= src
	qdel(src)



/* SURGERY STEPS */
/datum/surgery_step
	var/name
	/// Type path of tools that can be used to complete this step. Format is `path = probability of success`.
	/// If the tool has a specific surgery tooltype, you can use that as a key as well.
	var/list/allowed_tools = null
	/// The current type of implement used. This has to be stored, as the typepath of the tool might not match the list type.
	var/implement_type = null
	/// does the surgery step require an open hand? If true, ignores implements. Compatible with accept_any_item.
	var/accept_hand = FALSE
	/// Does the surgery step accept any item? If true, ignores implements. Compatible with accept_hand.
	var/accept_any_item = FALSE
	/// duration of the step
	var/time = 1 SECONDS
	/// Is this step repeatable? Make sure it isn't the last step, or it's used in a cancellable surgery.
	// TODO There's probably a better way to handle this
	var/repeatable = FALSE
	/// List of chems needed in the mob to complete the step. Even on success, this step will have no effect if the required chems aren't in the mob.
	var/list/chems_needed = list()
	/// Do we require any of the needed chems, or all of them?
	var/require_all_chems = TRUE
	/// Whether silicons ignore any probabilities (and are therefore "perfect" surgeons)
	var/silicons_obey_prob = FALSE

	// evil infection stuff that will make everyone hate me

	/// Whether this surgery step can cause an infection.
	var/can_infect = FALSE
	/// How much blood this step can get on surgeon. 1 - hands, 2 - full body.
	var/blood_level = 0

/**
 * Try to perform an operation on a user.
 * Arguments:
 * * user - The user performing the surgery.
 * * target - The user on whom the surgery is being performed.
 * * target_zone - the zone the user is targeting for the surgery.
 * * tool - The object that the user is using to perform the surgery (optional)
 * * surgery - The surgery being performed.
 * Returns TRUE if the step was a success, or FALSE if the step can't be performed for some reason.
 */
/datum/surgery_step/proc/try_op(mob/living/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/success = FALSE
	if(accept_hand)
		if(!tool)
			success = TRUE
		if(isrobot(user))
			success = TRUE

	if(accept_any_item)
		if(tool && tool_quality(tool))
			success = TRUE
	else if(tool)
		for(var/key in allowed_tools)
			var/match = FALSE
			if(ispath(key) && istype(tool, key))
				match = TRUE
			else if(tool.tool_behaviour == key)
				match = TRUE

			if(match)
				implement_type = key
				if(tool_quality(tool))
					success = TRUE
					break

	if(success)
		if(target_zone == surgery.location)
			if(get_location_accessible(target, target_zone) || surgery.ignore_clothes)
				initiate(user, target, target_zone, tool, surgery)
			else
				to_chat(user, "<span class='warning>You need to expose [target]'s [parse_zone(target_zone)] before you can perform surgery on it!")
			return TRUE //returns TRUE so we don't stab the guy in the dick or wherever.

	if(repeatable)
		var/datum/surgery_step/next_step = surgery.get_surgery_next_step()
		if(next_step)
			surgery.status++
			if(next_step.try_op(user, target, user.zone_selected, user.get_active_hand(), surgery))
				return TRUE
			else
				surgery.status--

	return FALSE

/**
 * Initiate and really perform the surgery itself.
 * This includes the main do-after and the checking of probabilities for successful surgeries.
 * If try_to_fail is TRUE, then this surgery will be deliberately failed out of.
 *
 * Returns TRUE if the surgery should proceed to the next step, or FALSE otherwise.
 */
/datum/surgery_step/proc/initiate(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)

	// TODO See if we can't do away with this proc a bit, or at least see how /tg/ implements it.
	if(!can_use(user, target, target_zone, tool, surgery))
		return

	surgery.step_in_progress = TRUE

	var/speed_mod = 1
	var/advance = FALSE
	var/prob_success = 100

	// TODO Clean up the begin_step calls so they all return TRUE or some define
	if(begin_step(user, target, target_zone, tool, surgery) == -1)
		surgery.step_in_progress = FALSE
		return

	if(tool)
		speed_mod = tool.toolspeed

	// Using an unoptimal tool slows down your surgery
	var/implement_speed_mod = 1
	if(implement_type)
		implement_speed_mod = allowed_tools[implement_type] / 100.0

	// TODO Changing the speed here is a balance change, make sure that's followed up with
	// TODO /tg/ code also has a mob_surgery_speed_mod, could be nice to add
	// They also have some interesting ways that surgery success/fail prob get evaluated, maybe worth looking at
	speed_mod /= (get_location_modifier(target) * 1 + surgery.speed_modifier) * implement_speed_mod
	var/modded_time = time * speed_mod

	if(slowdown_immune(user))
		// TODO Also a balance change here, borgos wouldn't be any faster either...
		modded_time = time

	if(implement_type)	//this means it isn't a require nd or any item step.
		prob_success = allowed_tools[implement_type]
	prob_success *= get_location_modifier(target)

	if(do_after(user, modded_time, target = target))

		var/chem_check_result = chem_check(target)
		var/pain_mod = deal_pain(user, target, target_zone, tool, surgery)
		prob_success *= pain_mod

		if((prob(prob_success) || isrobot(user) && !silicons_obey_prob) && chem_check_result && !try_to_fail)

			if(end_step(user, target, target_zone, tool, surgery))
				advance = TRUE
		else
			if(fail_step(user, target, target_zone, tool, surgery))
				advance = TRUE
			if(chem_check_result)
				return .(user, target, target_zone, tool, surgery, try_to_fail) //automatically re-attempt if failed for reason other than lack of required chemical

		// Bump the surgery status
		// if it's repeatable, don't let it truly "complete" though
		if(advance && !repeatable)
			surgery.status++
			if(surgery.status > surgery.steps.len)
				surgery.complete(target)

	surgery.step_in_progress = FALSE
	return advance

/**
 * Try to inflict pain during a surgery, a surgeon's dream come true.
 * This will wake up the user if they're voluntarily sleeping.
 *
 * Returns the pain_mod inflicted to the user.
 */
/datum/surgery_step/proc/deal_pain(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)
	. = 1
	if(ispath(surgery.steps[surgery.status], /datum/surgery_step/robotics) || surgery.organ_ref)//Repairing robotic limbs doesn't hurt, and neither does cutting someone out of a rig
		return
	if(!ishuman(target))
		return

	var/mob/living/carbon/human/H = target
	var/pain_mod = get_pain_modifier(H)

	// don't let people sit on the optable and sleep verb
	var/datum/status_effect/incapacitating/sleeping/S = H.IsSleeping()
	if(S?.voluntary)
		H.SetSleeping(0) // wake up people who are napping through the surgery
		if(pain_mod < 0.95)
			to_chat(H, "<span class='danger'>The surgery on your [parse_zone(target_zone)] is agonizingly painful, and rips you out of your shallow slumber!</span>")
		else
			// Still wake people up, but they shouldn't be as alarmed.
			to_chat(H, "<span class='warning'>The surgery being performed on your [parse_zone(target_zone)] wakes you up.</span>")
	return pain_mod //operating on conscious people is hard.

//returns how well tool is suited for this step
/datum/surgery_step/proc/tool_quality(obj/item/tool)
	for(var/T in allowed_tools)
		if(istype(tool,T))
			return allowed_tools[T]
	return 0

// Checks if this step applies to the user mob at all
/datum/surgery_step/proc/is_valid_target(mob/living/carbon/human/target)
	if(!hasorgans(target))
		return FALSE
	return TRUE

/**
 * Check for mobs that would be immune to surgery slowdowns/speedups.
 */
/datum/surgery_step/proc/slowdown_immune(mob/living/user)
	if(isrobot(user))
		return TRUE
	return FALSE

/// Checks whether this step can be applied with the given user and target
/datum/surgery_step/proc/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool, datum/surgery/surgery)
	return TRUE

// does stuff to begin the step, usually just printing messages. Moved germs transfering and bloodying here too
/datum/surgery_step/proc/begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(ishuman(target))
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		if(can_infect && affected)
			spread_germs_to_organ(affected, user, tool)
	if(ishuman(user) && !(istype(target,/mob/living/carbon/alien)) && prob(60))
		var/mob/living/carbon/human/H = user
		if(blood_level)
			H.bloody_hands(target,0)
		if(blood_level > 1)
			H.bloody_body(target,0)
	return

/**
 * Finish a surgery step, performing anything that runs on the tail-end of a successful surgery.
 * This runs if the surgery step passes the probability check, and therefore is a success.
 *
 * Should return TRUE to advance the surgery, though may return FALSE to keep the surgery step from advancing.
 */
/datum/surgery_step/proc/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool, datum/surgery/surgery)
	return TRUE

/**
 * Play out the failure state of a surgery step.
 * This runs if the surgery step fails the probability check, the right chems weren't present, or if the user deliberately failed the surgery.
 *
 * Should return FALSE to prevent the surgery step from advancing, though may return TRUE to advance to the next step regardless.
 */
/datum/surgery_step/proc/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool, datum/surgery/surgery)
	return FALSE

/**
 * Spread some nasty germs to an organ.
 *
 * * target_organ - The organ to try spreading germs to.
 * * user - The user who's manipulating the organ.
 * * tool - The tool the user is using to mess with the organ.
 */
/proc/spread_germs_to_organ(obj/item/organ/target_organ, mob/living/carbon/human/user, obj/item/tool)
	if(!istype(user) || !istype(target_organ) || target_organ.is_robotic() || target_organ.sterile)
		return

	var/germ_level = user.germ_level

	// germ spread from surgeon touching the patient
	if(user.gloves)
		germ_level = user.gloves.germ_level
	target_organ.germ_level = max(germ_level, target_organ.germ_level)
	spread_germs_by_incision(target_organ, tool) //germ spread from environement to patient

/**
 * Spread germs directly from a tool.
 *
 * * E - An external organ being operated on.
 * * tool - The tool performing the operation.
 */
/proc/spread_germs_by_incision(obj/item/organ/external/E, obj/item/tool)
	if(!istype(E, /obj/item/organ/external))
		return

	var/germs = 0

	for(var/mob/living/carbon/human/H in view(2, E.loc))//germs from people
		if(AStar(E.loc, H.loc, /turf/proc/Distance, 2, simulated_only = 0))
			if(!HAS_TRAIT(H, TRAIT_NOBREATH) && !H.wear_mask) //wearing a mask helps preventing people from breathing cooties into open incisions
				germs += H.germ_level * 0.25

	for(var/obj/effect/decal/cleanable/M in view(2, E.loc))//germs from messes
		if(AStar(E.loc, M.loc, /turf/proc/Distance, 2, simulated_only = 0))
			germs++

	if(tool && tool.blood_DNA && tool.blood_DNA.len) //germs from blood-stained tools
		germs += 30

	if(E.internal_organs.len)
		germs = germs / (E.internal_organs.len + 1) // +1 for the external limb this eventually applies to; let's not multiply germs now.
		for(var/obj/item/organ/internal/O in E.internal_organs)
			if(!O.is_robotic())
				O.germ_level += germs

	E.germ_level += germs

/**
 * Check that the target contains the chems we expect them to.
 */
/datum/surgery_step/proc/chem_check(mob/living/target)
	if(!LAZYLEN(chems_needed))
		return TRUE

	if(require_all_chems)
		. = TRUE
		for(var/reagent in chems_needed)
			if(!target.reagents.has_reagent(reagent))
				return FALSE
	else
		. = FALSE
		for(var/reagent in chems_needed)
			if(target.reagents.has_reagent(reagent))
				return TRUE
