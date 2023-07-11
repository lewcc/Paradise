/**
 * Makes up a key part of the vehicle
 */
/obj/vehicle_part
	name = "vehicle part"
	desc = "you shouldn't be seeing this."
	damage_deflection = 3
	/// New actions provided to the rider of such a vehicle
	var/list/actions
	/// If the part is not removable once it's in
	var/unremovable = FALSE

/obj/vehicle_part/Initialize(mapload)
	. = ..()
