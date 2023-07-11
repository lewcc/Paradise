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

	/// The type for the vehicle's controls
	var/control_type = /obj/item/twohanded/vehicle_controls

	/// How fast we're currently moving.
	var/current_speed = 0

	/// If we're turning, how many steps are we into said turn?
	var/steps_into_turn = 0

	var/controls_fluff_name = "controls"

	var/active_grip = VEHICLE_CONTROL_GRIP_NONE

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

/obj/vehicle/proc/get_low_speed()

/obj/vehicle/proc/get_medium_speed()

/obj/vehicle/proc/get_high_speed()

/obj/vehicle/proc/max_speed()

/obj/vehicle/proc/create_new_controls()
	if(controls)
		stack_trace("[src] tried to create controls while it already had some!")
		return
	controls = new control_type(src)
	RegisterSignal(controls, COMSIG_VEHICLE_GRIP_CHANGE, PROC_REF(on_grip_change))

/obj/vehicle/proc/get_controls()
	if(!controls)
		controls = create_new_controls()
	return controls

/obj/vehicle/proc/on_grip_change(obj/item/grip, grip_level)
	SIGNAL_HANDLER  // COMSIG_VEHICLE_GRIP_CHANGE
	active_grip = grip_level

/**
 * Pre-built vehicle. Spawns with a pre-assigned set of components.
 */
/obj/vehicle/prebuilt


/datum/action/innate/toggle_vehicle_controls
	name = "Toggle Vehicle Controls"
	desc = "Click to toggle vehicle controls (such as a steering wheel)."
	var/obj/vehicle/source_vehicle

/datum/action/innate/toggle_vehicle_controls/New(Target, source_vehicle)
	. = ..()
	src.source_vehicle = source_vehicle


/datum/action/innate/toggle_vehicle_controls/Activate()
	if(!target || !iscarbon(owner))
		return

	var/mob/living/carbon/C = owner
	if(!C.has_left_hand() && !C.has_right_hand())
		to_chat(owner, "<span class='warning'>You don't have any hands with which to hold [source_vehicle]'s controls!</span>")
		return

	if(ismob(source_vehicle.controls.loc))
		if(owner.l_hand == source_vehicle.controls || owner.r_hand == source_vehicle.controls)
			qdel(source_vehicle.controls)
			to_chat(owner, "<span class='notice'>You release [source_vehicle]'s controls.</span>")
			return
		stack_trace("Somehow, controls exist outside of the rider's hands.")

	if(!C.put_in_hands(source_vehicle.get_controls()))
		to_chat(owner, "<span class='warning'>You aren't able to get a grip on [source_vehicle]'s controls!</span>")
	else
		owner.visible_message("<span class='notice'>[owner] takes [source_vehicle]'s controls!</span>")
