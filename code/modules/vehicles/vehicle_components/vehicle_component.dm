/**
 * Makes up a key part of the vehicle
 */
/obj/item/vehicle_part
	name = "vehicle part"
	desc = "you shouldn't be seeing this."
	/// How resistant this part is to taking damage. For now just an arbitrary number.
	var/damage_resist = 3
	/// New actions provided to the rider of such a vehicle
	var/list/rider_actions
	/// If the part is not removable once it's in
	var/unremovable = FALSE
	/// Traits to apply to the vehicle when applied (and to remove when removed).
	var/list/traits_provided = list()


/obj/item/vehicle_part/Initialize(mapload)
	. = ..()

// Return true in these procs to indicate that the item was added successfully,
// or false to indicate that it can't be added for some reason.

/obj/item/vehicle_part/proc/on_insert(obj/vehicle/target)
	SHOULD_CALL_PARENT(TRUE)
	if(!istype(target))
		CRASH("Vehicle part inserted into something that isn't a vehicle!")
	var/our_uid = UID()
	for(var/trait in traits_provided)
		ADD_TRAIT(target, trait, "vehicle_part_[our_uid]")

	if(target.rider)

	// TODO ADD SOME SIGNALS ON INSERT

	return TRUE

/obj/item/vehicle_part/proc/on_removal(obj/vehicle/target, force = FALSE)
	SHOULD_CALL_PARENT(TRUE)
	if(unremovable && !force)
		return FALSE
	var/our_uid = UID()
	for(var/trait in traits_provided)
		REMOVE_TRAIT(target, trait, "vehicle_part_[our_uid]")
	return TRUE

/obj/item/vehicle_part/proc/on_break()
	return

/// Callback to fire when something happens that should update stats.
/obj/item/vehicle_part/proc/update_stats()
	return
