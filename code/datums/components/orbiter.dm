/datum/component/orbiter
	can_transfer = TRUE
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/list/orbiter_list
	var/list/transform_cache

/**
A: atom to orbit
radius: range to orbit at, radius of the circle formed by orbiting
clockwise: whether you orbit clockwise or anti clockwise
rotation_speed: how fast to rotate
rotation_segments: the resolution of the orbit circle, less = a more block circle, this can be used to produce hexagons (6 segments) triangles (3 segments), and so on, 36 is the best default.
pre_rotation: Chooses to rotate src 90 degress towards the orbit dir (clockwise/anticlockwise), useful for things to go "head first" like ghosts
lockinorbit: Forces src to always be on A's turf, otherwise the orbit cancels when src gets too far away (eg: ghosts)
*/
/datum/component/orbiter/Initialize(atom/movable/orbiter, radius = 10, clockwise = FALSE, rotation_speed = 20, rotation_segments = 36, pre_rotation = TRUE, lockinorbit = FALSE, forceMove = FALSE)
	if (!istype(orbiter) || !isatom(parent) || isarea(parent))
		return COMPONENT_INCOMPATIBLE

	begin_orbit(orbiter, radius, clockwise, rotation_speed, rotation_segments, pre_rotation, lock_in_orbit, force_move)

	. = ..()

/datum/component/orbiter/RegisterWithParent()
	var/atom/target = parent
	target.orbiters = src

/datum/component/orbiter/UnregisterFromParent()
	var/atom/target = parent
	target.orbiters = null

/datum/component/orbiter/Destroy()
	var/atom/master = parent
	if(master.orbiters == src)
		master.orbiters = null
	for(var/i in orbiter_list)
		end_orbit(i)
	orbiter_list = null
	transform_cache = null
	return ..()

/datum/component/orbiter/InheritComponent(datum/component/orbiter/new_comp, original, atom/movable/orbiter, radius, clockwise, rotation_speed, rotation_segments, pre_rotation)
	// No transfer happening
	if(!newcomp)
		begin_orbit(arglist(args.Copy(3)))
		return

	for(var/o in new_comp.orbiter_list)
		var/atom/movable/incoming_orbiter = o
		incoming_orbiter.orbiting = src

	LAZYADD(orbiter_list, new_comp.orbiter_list)
	transform_cache += new_comp.transform_cache

	new_comp.orbiter_list = null
	new_comp.transform_cache = null

/datum/component/orbiter/PostTransfer()
	if(!isatom(parent) || isarea(parent) || !get_turf(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/orbiter/begin_orbit(atom/movable/orbiter, radius, clockwise, rotation_speed, rotation_segments, pre_rotation, lock_in_orbit, force_move)

	if(!istype(orbiter))
		return

	if(orbiter.orbiting)
		if (orbiter.orbiting == src)
			orbiter.orbiting.end_orbit(orbiter, TRUE)
		else
			orbiter.orbiting.end_orbit(orbiter)

	// Start building up the orbiter
	orbiter.orbiting = src
	LAZYADD(orbiter_list, orbiter)
	var/matrix/initial_transform = matrix(orbiter.transform)
	transform_cache[orbiter] = orbiter.initial_transform
	var/lastloc = orbiter.loc

	//Head first!
	if(pre_rotation)
		var/matrix/M = matrix(orbiter.transform)
		var/pre_rot = 90
		if(!clockwise)
			pre_rot = -90
		M.Turn(pre_rot)
		orbiter.transform = M

	var/matrix/shift = matrix(orbiter.transform)
	shift.Translate(0,radius)
	orbiter.transform = shift

	SEND_SIGNAL(parent, COMSIG_ATOM_ORBIT_BEGIN, orbiter)

	SpinAnimation(rotation_speed, -1, clockwise, rotation_segments, parallel = FALSE)

	while(orbiting && orbiting == parent && parent.loc)
		var/targetloc = get_turf(parent)
		if(!lockinorbit && orbiter.loc != orbiter.lastloc && orbiter.loc != targetloc)
			break
		if(forceMove)
			forceMove(targetloc)
		else
			orbiter.loc = targetloc
		lastloc = loc
		sleep(0.6)

	// TODO Figure out why we need this
	if(orbiting == parent) //make sure we haven't started orbiting something else.
		SpinAnimation(0, 0, parallel = FALSE)
		stop_orbit()

/**
End the orbit and clean up our transformation
*/
/datum/component/orbiter/proc/end_orbit(atom/movable/orbiter, refreshing=FALSE)
	var/matrix/cached_transform = transformation_cache[orbiter]

	if(!cached_transform)
		return

	SEND_SIGNAL(parent, COMSIG_ATOM_ORBIT_STOP, orbiter)
	SpinAnimation(0, 0, parallel = FALSE)

	// Clean up and reset the atom doing the orbiting
	LAZYREMOVE(orbiter_list, orbiter)
	transformation_cache -= orbiter
	orbiter.transform = cached_transform
	orbiter.stop_orbit()

	if (!refreshing && !orbiter_list && !QDELING(src))
		qdel(src)

///////////


//This is just so you can stop an orbit.
//orbit() can run without it (swap orbiting for A)
//but then you can never stop it and that's just silly.
/atom/movable/var/atom/orbiting = null
/atom/movable/var/cached_transform = null
/atom/var/list/orbiters = null

/atom/movable/proc/orbit(atom/A, radius = 10, clockwise = FALSE, rotation_speed = 20, rotation_segments = 36, pre_rotation = TRUE)
	if(!istype(A) || !get_turf(A) || A == src)
		return
	orbit_target = A
	return A.AddComponent(/datum/component/orbiter, src, radius, clockwise, rotation_speed, rotation_segments, pre_rotation)

/atom/movable/proc/stop_orbit(datum/component/orbiter/orbits)
	orbit_target = null
	return // We're just a simple hook

/atom/proc/transfer_observers_to(atom/target)
	if(!orbiters || !istype(target) || !get_turf(target) || target == src)
		return
	target.TakeComponent(orbiters)
