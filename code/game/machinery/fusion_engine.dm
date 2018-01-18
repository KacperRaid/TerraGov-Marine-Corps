//Experimental engine for the Almayer.  Should be fancier.  I expect I'll eventually make it totally seperate from the Geothermal as I don't like the procs... - Apop


/obj/machinery/power/geothermal/fusion
	name = "\improper S-52 fusion reactor"
	icon = 'icons/Marine/fusion_eng.dmi'
	icon_state = "off-0"
	desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat.  Currently in standby mode."
	almayer = 1 //Yup, it's on the Almayer.
	directwired = 0     //Requires a cable directly underneath
	unacidable = 1      //NOPE.jpg
	power_gen_percent = 0 //50,000W at full capacity
	power_generation_max = 50000 //Full capacity
	powernet_connection_failed = 0 //Logic checking for powernets
	buildstate = 0 //What state of building it are we on, 0-3, 1 is "broken", the default
	is_on = 0  //Is this damn thing on or what?
	fail_rate = 5 //% chance of failure each fail_tick check
	fail_check_ticks = 100 //Check for failure every this many ticks
	cur_tick = 0 //Tick updater

	//almayer Generator Unique Vars

	var/obj/item/fuelCell/fusion_cell = new/obj/item/fuelCell //Starts with a fuel cell loaded in.  Maybe replace with the plasma tanks in the future and have it consume plasma?  Possibly remove this later if it's irrelevent...

	var/produce_heat = 1 //Fusion is a VERY warm process.  The reactor room should probably be cooled... Probably...
	var/fuel_rate = 0.00 //Rate at which fuel is used.  Based mostly on how long the generator has been running.
	var/icon_track = 100 //This is to track the amount of fuel so it selects the proper icon.

	New()
		buildstate = rand(0,3) //This is needed to set the state for repair interactions
		switch(buildstate)
			if(1) icon_state = "weld"
			if(2) icon_state = "wire"
			if(3) icon_state = "wrench"

		fusion_cell.fuel_amount = rand(15,100)
		..()

	process()
		if(!is_on || buildstate || !anchored) //Default logic checking
			return 0
		if (fusion_cell.fuel_amount <= 0)
			visible_message("\icon[src] <b>[src]</b> flashes that the fuel cell is empty as the engine seizes.")
			desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat.  <red>The reactor ran out of fuel and seized up"
			fuel_rate = 0
			buildstate = 1  //No fuel really fucks it.
			is_on = 0
			icon_track = 0
			fail_rate+=2 //Each time the engine is allowed to seize up it's fail rate for the future increases because reasons.
			icon_state = "weld"
			r_FAL
		if(!powernet && !powernet_connection_failed) //Powernet checking, make sure there's valid cables & powernets
			if(!connect_to_network())
				powernet_connection_failed = 1
				is_on = 0
				spawn(150) // Error! Check again in 15 seconds. Someone could have blown/acided or snipped a cable
					powernet_connection_failed = 0
		else if(powernet) //All good! Let's fire it up!
			if(!check_failure()) //THIS STILL NEEDS A SMIDGE OF WORK, AND PROBABLY IT'S OWN PROC SINCE I'M GHETTOING UP THE REGULAR ONE...
//			update_icon()

				if(power_gen_percent < 100) power_gen_percent++

				switch(power_gen_percent) //Flavor text!
					if(10)
						visible_message("\icon[src] <span class='notice'><b>[src]</b> begins to whirr as it powers up.</span>")
						fuel_rate = 0.025
					if(50)
						visible_message("\icon[src] <span class='notice'><b>[src]</b> begins to hum loudly as it reaches half capacity.</span>")
						fuel_rate = 0.05
					if(99)
						visible_message("\icon[src] <span class='notice'><b>[src]</b> rumbles loudly as the combustion and thermal chambers reach full strength.</span>")
						fuel_rate = 0.1

				add_avail(power_generation_max * (power_gen_percent / 100) ) //Nope, all good, just add the power
				fusion_cell.fuel_amount-=fuel_rate //Consumes fuel

		if(is_on && powernet) //This can probably be changed in the future.  For now, when a fuel cell is ejected, it'll be "useless" no matter how much fuel remains.
			switch(fusion_cell.fuel_amount)
				if(0 to 10)
	//				visible_message("\icon[src] <b>[src]</b> displasy that the fuel cell is critically low and needs to be replaced")
					desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat.  <red>The Fuel cell is critically low.</red>"
					icon_track = 10
				if(11 to 25)
	//				visible_message("\icon[src] <b>[src]</b> displays that it's fuel cell is below half")
					desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat.  <red>The fuel cell is running low.</red>"
					icon_track = 25
				if(26 to 50)
//				visible_message("\icon[src] <b>[src]</b> displays that it's fuel cell at half")
					desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat.  The fuel cell is a little under halfway."
					icon_track = 50
				if(51 to 75)
		//			visible_message("\icon[src] <b>[src]</b> displays that it's fuel cell is 75% full")
					desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat.  The fuel cell is a little above halfway."
					icon_track = 75
				if(76 to INFINITY)
//				visible_message("\icon[src] <b>[src]</b> displays that it's fuel cell is mostly full")
					desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat.  The fuel cell is nearly full."
					icon_track = 100
			icon_state = "on-[icon_track]" //Makes sure it gets the proper icon
//			update_icon() //Gonna either make a new one of these with blackjack and hooker or just ignore it 5ever.


	attack_hand(mob/user as mob)
		if(!anchored) //Shouldn't actually be possible
			usr << "MAKE AN AHELP RIGHT AWAY, BECAUSE SHIT IS SOMEHOW FUCKED - ERROR: ALM001."
			r_FAL
		if(!ishuman(user) || user.stat)
			user << "<span class='warning'>You have no idea how to use that.</span>" //No ayylamos
			r_FAL
		add_fingerprint(user)
		switch(buildstate)
			if(1)
				usr << "<span class='info'>Use a blowtorch, then wirecutters, then wrench to repair it.</span>"
				r_FAL
			if(2)
				usr << "<span class='notice'>Use a wirecutters, then wrench to repair it.</span>"
				r_FAL
			if(3)
				usr << "<span class='notice'>Use a wrench to repair it.</span>"
				r_FAL
		if(is_on)
			visible_message("\icon[src] <span class='warning'><b>[src]</b> beeps softly and the humming stops as [usr] shuts off the generator.</span>")
			icon_state = "off-[icon_track]"
			is_on = 0
			power_gen_percent = 0
			cur_tick = 0
	//		update_icon()
			r_TRU
		if(fusion_cell == null)
			usr << "<span class='notice'>The reactor requires a fuel cell before you can turn it on.</span>"
			r_FAL
		if(fusion_cell.fuel_amount <= 10)
			usr << "\icon[src] <span class='warning'><b>[src]</b>: Fuel levels critically low.</span>"
		visible_message("\icon[src] <span class='warning'><b>[src]</b> beeps loudly as [usr] turns the generator on and begins the process of fusion...</span>")
		icon_state = "on-[icon_track]"
		fuel_rate = 0.01
		is_on = 1
		cur_tick = 0
//	update_icon()
		r_TRU


	attackby(obj/item/O, mob/user)
		if(istype(O, /obj/item/fuelCell))
			if(is_on)
				user << "<span class='warning'>The [src] needs to be turned off first...</span>"
				r_TRU
			if(fusion_cell == null)
				if(user.drop_inv_item_to_loc(O, src.))
					fusion_cell = O
					user << "<span class='notice'>You load the [src] with the [O].</span>"
				r_TRU
			else
				user << "<span class='warning'>You need to remove the fuel cell from the [src] first.</span>"
				r_TRU
			icon_track = 100
			desc = "A Westingland S-52 Fusion Reactor.  Takes fuels cells and converts them to power for the ship.  Also produces a large amount of heat. "
			desc += (fusion_cell == null) ? "There is no fuel cell in the receptacle." : "You can see a fuel cell in the receptacle."
			r_TRU
		else if(istype(O, /obj/item/tool/weldingtool))
			if(buildstate == 1 && !is_on)
				var/obj/item/tool/weldingtool/WT = O
				if(WT.remove_fuel(0, user))
					if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_ENGI)
						user << "<span class='warning'>You start fumbling around, examining what's broken...</span>"
						var/fumbling_time = 100 - 20*user.mind.cm_skills.engineer
						if(!do_after(user, fumbling_time, TRUE, 5, BUSY_ICON_CLOCK)) return
					playsound(loc, 'sound/items/Welder2.ogg', 25, 1)
					user.visible_message("<span class='notice'>[user] starts to weld the damage to [src].</span>","<span class='notice'>You start to weld the damage to [name]. Stand still!</span>")
					if (do_after(user,200, TRUE, 5, BUSY_ICON_CLOCK))
						if(buildstate != 1 || is_on || !WT.isOn()) r_FAL
						buildstate = 2
						user << "You finish welding."
						icon_state = "wire"
//						update_icon()
						r_TRU
				else
					user << "\red You need more welding fuel to complete this task."
					r_FAL
		else if(istype(O,/obj/item/tool/wirecutters))
			if(buildstate == 2 && !is_on)
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_ENGI)
					user << "<span class='warning'>You start fumbling around, trying to figure out the wiring...</span>"
					var/fumbling_time = 100 - 20*user.mind.cm_skills.engineer
					if(!do_after(user, fumbling_time, TRUE, 5, BUSY_ICON_CLOCK)) return
				playsound(loc, 'sound/items/Wirecutter.ogg', 25, 1)
				user.visible_message("<span class='notice'>[user] starts to secure the wiring on [src].</span>","<span class='notice'>You start to secure the wiring. Stand still!</span>")
				if(do_after(user,120, TRUE, 12, BUSY_ICON_CLOCK))
					if(buildstate != 2 || is_on) r_FAL
					buildstate = 3
					user << "You finish securing the wires."
					icon_state = "wrench"
	//				update_icon()
					r_TRU
		else if(istype(O,/obj/item/tool/wrench))
			if(buildstate == 3 && !is_on)
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_ENGI)
					user << "<span class='warning'>You start fumbling around, examining the damage on the tubes and plating...</span>"
					var/fumbling_time = 100 - 20*user.mind.cm_skills.engineer
					if(!do_after(user, fumbling_time, TRUE, 5, BUSY_ICON_CLOCK)) return
				playsound(loc, 'sound/items/Ratchet.ogg', 25, 1)
				user.visible_message("<span class='notice'>[user] starts to repair the tubes and plating on [src].</span>","<span class='notice'>You start to repair the plating. Stand still!</span>")
				if(do_after(user,150, TRUE, 15, BUSY_ICON_CLOCK))
					if(buildstate != 3 || is_on) r_FAL
					buildstate = 0
					is_on = 0
					user << "You finish repairing the plating. The generator looks good to go! Press it to turn it on."
					icon_state = "off"
//					update_icon
					r_TRU
		else if(istype(O,/obj/item/tool/crowbar))
			if(buildstate != 0)
				user << "<span class='notice'>You must repair the generator before working with its fuel cell.</span>"
				return
			if(is_on)
				user << "<span class='notice'>You must turn off the generator before working with its fuel cell.</span>"
				return
			if(!fusion_cell)
				user << "<span class='notice'>There is no cell to remove.</span>"
			else
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_ENGI)
					user << "<span class='warning'>You start to jam the head of the crowbar under the fuel cell's safety cover...</span>"
					var/fumbling_time = 100 - 20*user.mind.cm_skills.engineer
					if(!do_after(user, fumbling_time, TRUE, 5, BUSY_ICON_CLOCK)) return
				playsound(loc, 'sound/items/Crowbar.ogg', 25, 1)
				user.visible_message("<span class='notice'>[user] starts to pry open the fuel receptacle on [src].</span>","<span class='notice'>You start to pry open the cover. Stand still!</span>")
				if(do_after(user, 100, TRUE, 15, BUSY_ICON_CLOCK))
					if(buildstate != 0 || is_on || !fusion_cell) r_FAL
					user << "You pop open the cover and pull out the fuel cell."
					fusion_cell.update_icon()
					user.put_in_hands(fusion_cell)
					fusion_cell = null
					r_TRU
		else
			return ..()



//FUEL CELL
/obj/item/fuelCell
	name = "\improper WL-6 universal fuel cell"
	icon = 'icons/Marine/shuttle-parts.dmi'
	icon_state = "cell-full"
	desc = "A rechargable fuel cell designed to work as a power source for the Cheyenne-Class transport or for Westingland S-52 Reactors."
	var/fuel_amount = 100.0
	var/max_fuel_amount = 100.0

	update_icon()
		if(fuel_amount == 0)
			icon_state = "cell-empty"
		else if(percent() > 0 && percent() < 25)
			icon_state = "cell-low"
		else if(percent() >= 25 && percent() < 75)
			icon_state = "cell-medium"
		else if(percent() >= 75 && percent() < 100)
			icon_state = "cell-high"
		else if(fuel_amount == max_fuel_amount)
			icon_state = "cell-full"

/obj/item/fuelCell/proc/percent()
	return 100.0*fuel_amount/max_fuel_amount

/obj/item/fuelCell/proc/is_regenerated()
	return (fuel_amount == max_fuel_amount)

/obj/item/fuelCell/proc/give(amount as num)
	fuel_amount += amount
	if(fuel_amount > max_fuel_amount)
		fuel_amount = max_fuel_amount
