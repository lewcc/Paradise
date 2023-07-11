/**
 * Controls for a vehicle.
 * Icon changes based on the speed of the vehicle itself, and the "grip" determines the degree of control the user has.
 */
/obj/item/twohanded/vehicle_controls
	// TODO make a better icon that reflects the acceleration level
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "keyjanitor"
	var/speed_level = 0
	flags = ABSTRACT | DROPDEL | NODROP
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// The vehicle these controls control
	var/obj/vehicle/connected_vehicle

/obj/item/twohanded/vehicle_controls/Initialize(mapload, obj/vehicle/controlling)
	. = ..()
	connected_vehicle = controlling
	name = "[connected_vehicle]'s [connected_vehicle.controls_fluff_name]"
	RegisterSignal(connected_vehicle, COMSIG_PARENT_QDELETING, PROC_REF(Destroy))
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))

/obj/item/twohanded/vehicle_controls/Destroy()
	. = ..()
	if(connected_vehicle)
		SEND_SIGNAL(connected_vehicle, COMSIG_VEHICLE_GRIP_CHANGE, VEHICLE_CONTROL_GRIP_NONE)
	connected_vehicle = null

/obj/item/twohanded/vehicle_controls/wield(mob/living/carbon/user)
	. = ..()
	if(.)
		SEND_SIGNAL(connected_vehicle, COMSIG_VEHICLE_GRIP_CHANGE, VEHICLE_CONTROL_GRIP_TWOHAND)

/obj/item/twohanded/vehicle_controls/unwield(mob/living/carbon/user)
	. = ..()
	if(.)
		SEND_SIGNAL(connected_vehicle, COMSIG_VEHICLE_GRIP_CHANGE, VEHICLE_CONTROL_GRIP_ONEHAND)


