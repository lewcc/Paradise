/obj/vehicle
	name = "vehicle"
	density = TRUE
	anchored = FALSE
	can_buckle = TRUE
	buckle_lying = FALSE

	/// If true, components will be dropped on destroy.
	// TODO implement this properly. Maybe only drop some, and make sure they're heavily damaged.
	var/drop_components_on_destroy = FALSE

	/// Active for the vehicle. The in-hand item.
	var/obj/item/twohanded/vehicle_controls/controls

	/// How fast we're currently moving.
	var/current_speed = 0

	/// If we're turning, how many steps are we into said turn?
	var/steps_into_turn = 0

	/// If true, parts can only be removed if broken.
	/// This allows for some "special" parts to not be extractable to use in other vehicles.
	var/unbroken_parts_removable = FALSE

	// The main parts that make up any vehicle.
	var/obj/vehicle_part/chassis/active_chassis
	var/obj/vehicle_part/propulsion/active_propulsion
	var/obj/vehicle_part/engine/active_engine

	/// Any extra components which are on the vehicle but not part of the standard three.
	var/list/additional_components

/obj/vehicle/Initialize(mapload)
	. = ..()
	additional_components = list()

/obj/vehicle/Destroy()
	. = ..()
	QDEL_NULL(controls)
	if(!drop_components_on_destroy)
		QDEL_NULL(active_chassis)
		QDEL_NULL(active_propulsion)
		QDEL_NULL(active_engine)
	additional_components.Cut()

// These getters will get their values from the underlying components
/obj/vehicle/proc/acceleration_rate()

/obj/vehicle/proc/turning_radius()

/obj/vehicle/proc/max_speed()

/**
 * Pre-built vehicle. Spawns with a pre-assigned set of components.
 */
/obj/vehicle/prebuilt
