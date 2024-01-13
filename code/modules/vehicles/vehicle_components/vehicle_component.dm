/**
 * Makes up a key part of the vehicle
 */
/obj/item/vehicle_part
	name = "vehicle part"
	desc = "you shouldn't be seeing this."
	/// How resistant this part is to taking damage, on a scale from 0 to 1.
	/// Applied as a flat ratio onto damage dealt to this component.
	/// TODO maybe rework this to incorporate object armor?
	var/part_armor = 1
	/// New actions provided to the driver of such a vehicle
	var/list/driver_actions
	/// Actions provided to any riders
	var/list/rider_actions
	/// If the part is not removable once it's in
	var/unremovable = FALSE
	/// Traits to apply to the vehicle when applied (and to remove when removed).
	var/list/traits_provided = list()


/obj/item/vehicle_part/Initialize(mapload)
	. = ..()

// TODO custom vehicle part/damages
/obj/item/vehicle_part/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration_flat, armour_penetration_percentage)
	. = ..()

/obj/item/vehicle_part/proc/grant_actions(mob/living/rider, driver = FALSE)
	var/list/actions_to_grant = driver ? driver_actions : rider_actions
	for(var/datum/action/A in actions_to_grant)
		A.Grant(rider)

/obj/item/vehicle_part/proc/revoke_actions(mob/living/rider, driver = FALSE)
	var/list/actions_to_grant = driver ? driver_actions : rider_actions
	for(var/datum/action/A in actions_to_grant)
		A.Remove(rider)

/obj/item/vehicle_part/proc/on_new_rider(obj/vehicle/V, mob/living/new_rider, is_driver)
	SIGNAL_HANDLER  // COMSIG_VEHICLE_ADD_RIDER
	grant_actions(new_rider, is_driver)

/obj/item/vehicle_part/proc/on_rider_removal(obj/vehicle/V, mob/living/old_rider, is_driver)
	SIGNAL_HANDLER  // COMSIG_VEHICLE_REMOVE_RIDER
	revoke_actions(old_rider, is_driver)

// Return true in these procs to indicate that the item was added successfully,
// or false to indicate that it can't be added for some reason.

/obj/item/vehicle_part/proc/on_insert(obj/vehicle/target)
	SHOULD_CALL_PARENT(TRUE)
	if(!istype(target))
		CRASH("Vehicle part inserted into something that isn't a vehicle!")
	var/our_uid = UID()
	for(var/trait in traits_provided)
		ADD_TRAIT(target, trait, "vehicle_part_[our_uid]")
	for(var/mob/living/buckled in buckled_mobs)
		grant_actions(buckled, target.driver == buckled)
	RegisterSignal(target, COMSIG_VEHICLE_ADD_RIDER, PROC_REF(on_new_rider))
	RegisterSignal(target, COMSIG_VEHICLE_REMOVE_RIDER, PROC_REF(on_rider_removal))

	// TODO ADD SOME SIGNALS ON INSERT

	return TRUE

/obj/item/vehicle_part/proc/on_removal(obj/vehicle/target, force = FALSE)
	SHOULD_CALL_PARENT(TRUE)
	if(unremovable && !force)
		return FALSE
	var/our_uid = UID()
	for(var/trait in traits_provided)
		REMOVE_TRAIT(target, trait, "vehicle_part_[our_uid]")
	for(var/mob/living/buckled in buckled_mobs)
		revoke_actions(buckled, target.driver == buckled)
	UnregisterSignal(target, list(COMSIG_VEHICLE_ADD_RIDER, COMSIG_VEHICLE_REMOVE_RIDER))
	return TRUE

/obj/item/vehicle_part/proc/on_break()
	return

/// Callback to fire when something happens that should update stats.
/obj/item/vehicle_part/proc/update_stats()
	return
