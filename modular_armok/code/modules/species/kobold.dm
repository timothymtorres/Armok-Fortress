// =========================
// = K O B O L D   R A C E =
// =========================
//
// Kobolds as per Dwarf Fortress lore:
// - Small, cave-dwelling thieves
// - Completely illiterate
// - Nocturnal (penalized in bright light)
// - Speak only Kobold (unintelligible to others)
// - Easily grabbed (pushovers)
// - Cowardly but cunning

// ===========================
// =   S P E C I E S         =
// ===========================

/datum/species/lizard/kobold
	name = "\improper Kobold"
	plural_form = "Kobolds"
	id = SPECIES_KOBOLD
	examine_limb_id = SPECIES_LIZARD  // Reuse lizard limb sprites as base

	inherent_traits = list(
		TRAIT_MUTANT_COLORS,
		TRAIT_ILLITERATE,        // Kobolds cannot read or write
		TRAIT_GRABWEAKNESS,      // Kobolds are pushovers, easily grabbed
		TRAIT_DWARF,             // Short stature, same height as dwarves
		TRAIT_SILENT_FOOTSTEPS,  // Sneaky little critters
	)

	inherent_biotypes = MOB_ORGANIC|MOB_HUMANOID|MOB_REPTILE

	species_language_holder = /datum/language_holder/kobold

	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT

	// Kobolds are lizard-adjacent but have their own organ setup
	mutanttongue   = /obj/item/organ/tongue/kobold
	mutanteyes     = /obj/item/organ/eyes/kobold
	mutantbrain    = /obj/item/organ/brain/lizard  // Primitive brain, reuse lizard
	mutant_organs  = list(
		/obj/item/organ/tail/lizard = "Smooth",  // They have tails
		/obj/item/organ/snout       = "Round",   // Small snouts
	)

	// Coldblooded like lizards, but living underground
	// means they tolerate cold slightly better than surface lizards
	coldmod = 1.25
	heatmod = 0.75
	bodytemp_heat_damage_limit = BODYTEMP_HEAT_LAVALAND_SAFE
	bodytemp_cold_damage_limit = (BODYTEMP_COLD_DAMAGE_LIMIT - 20)

	// Kobolds are cold-blooded like lizards
	// (overridden proc below)

	exotic_bloodtype = BLOOD_TYPE_LIZARD  // Same reptilian blood as lizards

	// Kobolds are small and their hide is thin
	inert_mutation = /datum/mutation/dwarfism

	// Kobolds use lizard bodyparts for visuals
	bodypart_overrides = list(
		BODY_ZONE_HEAD    = /obj/item/bodypart/head/lizard,
		BODY_ZONE_CHEST   = /obj/item/bodypart/chest/lizard,
		BODY_ZONE_L_ARM   = /obj/item/bodypart/arm/left/lizard,
		BODY_ZONE_R_ARM   = /obj/item/bodypart/arm/right/lizard,
		BODY_ZONE_L_LEG   = /obj/item/bodypart/leg/left/lizard,
		BODY_ZONE_R_LEG   = /obj/item/bodypart/leg/right/lizard,
	)

	payday_modifier = 0.9  // Kobolds are paid less (treated as pests/nuisances)

	meat        = /obj/item/food/meat/slab/human/mutant/lizard
	skinned_type = /obj/item/stack/sheet/animalhide/carbon/lizard

	death_sound = 'sound/mobs/humanoids/lizard/deathsound.ogg'

	family_heirlooms = list(
		//obj/item/melee/knife,       // A stolen blade
		/obj/item/storage/backpack,  // For carrying stolen goods
	)

// Kobolds are cold-blooded, no internal temperature regulation
/datum/species/lizard/kobold/body_temperature_core(mob/living/carbon/human/humi, seconds_per_tick)
	return

// ================================
// =   O N   G A I N  /  L O S S =
// ================================

/datum/species/lizard/kobold/on_species_gain(mob/living/carbon/human/new_kobold, datum/species/old_species, pref_load, regenerate_icons)
	. = ..()
	if(!ishuman(new_kobold))
		return

	// Register for the bright-light penalty handler
	RegisterSignal(new_kobold, COMSIG_LIVING_LIFE, PROC_REF(handle_light_sensitivity))

/datum/species/lizard/kobold/on_species_loss(mob/living/carbon/human/former_kobold, datum/species/new_species, pref_load)
	UnregisterSignal(former_kobold, COMSIG_LIVING_LIFE)
	former_kobold.clear_mood_event("kobold_bright_light")
	former_kobold.clear_mood_event("kobold_safe_dark")
	return ..()

// ===============================
// =   L I G H T   P E N A L T Y =
// ===============================

/// Kobolds are nocturnal cave-dwellers.
/// They suffer eye pain and a vision penalty in brightly lit areas,
/// and feel at home in the dark.
/datum/species/lizard/kobold/proc/handle_light_sensitivity(mob/living/carbon/human/kobold, seconds_per_tick)
	SIGNAL_HANDLER

	if(HAS_TRAIT(kobold, TRAIT_NOFLASH))  // Eye protection negates the penalty
		kobold.clear_mood_event("kobold_bright_light")
		kobold.remove_movespeed_modifier(/datum/movespeed_modifier/kobold_bright_light)
		return

	// Check the luminosity of the turf the kobold is standing on
	var/turf/standing_turf = get_turf(kobold)
	if(!standing_turf)
		return

	var/light_level = standing_turf.get_lumcount()

	// Threshold: anything above 0.6 luminosity counts as "bright" to a kobold
	// Station lighting is typically 0.7–1.0
	if(light_level >= KOBOLD_BRIGHT_LIGHT_THRESHOLD)
		kobold.clear_mood_event("kobold_safe_dark")
		kobold.add_mood_event("kobold_bright_light", /datum/mood_event/kobold_bright_light)
		kobold.add_or_update_variable_movespeed_modifier(
			/datum/movespeed_modifier/kobold_bright_light,
			multiplicative_slowdown = KOBOLD_LIGHT_SLOWDOWN,
		)
		// Occasionally squint/complain about the light
		//if(SPT_PROB(2, seconds_per_tick))
			//kobold.emote("squint")

	else if(light_level < KOBOLD_COMFORTABLE_DARK_THRESHOLD)
		// Kobold is in comfortably dim/dark area
		kobold.clear_mood_event("kobold_bright_light")
		kobold.remove_movespeed_modifier(/datum/movespeed_modifier/kobold_bright_light)
		kobold.add_mood_event("kobold_safe_dark", /datum/mood_event/kobold_safe_dark)

	else
		// In-between: not bright, not dark. Neutral.
		kobold.clear_mood_event("kobold_bright_light")
		kobold.clear_mood_event("kobold_safe_dark")
		kobold.remove_movespeed_modifier(/datum/movespeed_modifier/kobold_bright_light)

// ===================================
// =   M O O D   E V E N T S         =
// ===================================

/datum/mood_event/kobold_bright_light
	description = "The light burns my eyes! Too bright, too bright!"
	mood_change = -4
	timeout = 5 SECONDS  // Refreshed each life tick if still in light

/datum/mood_event/kobold_safe_dark
	description = "The shadows wrap around me like home. Safe here."
	mood_change = 3
	timeout = 10 SECONDS

// =========================================
// =   M O V E S P E E D   M O D I F I E R =
// =========================================

/datum/movespeed_modifier/kobold_bright_light
	// Base slowdown is set dynamically via add_or_update_variable_movespeed_modifier
	multiplicative_slowdown = KOBOLD_LIGHT_SLOWDOWN

// ========================
// =   P R E F E R E N C E =
// ========================

/datum/species/lizard/kobold/prepare_human_for_preview(mob/living/carbon/human/human)
	// Kobolds tend toward earthy, muted colors
	human.dna.features[FEATURE_MUTANT_COLOR] = pick(
		"#6b5a3e",  // Muddy brown
		"#4a6b3e",  // Cave moss green
		"#3e4a6b",  // Slate blue-grey
		"#6b3e3e",  // Rust red
		"#5a5a5a",  // Ashen grey
	)
	human.update_body(is_creating = TRUE)

// ===================================
// =   S P E C I E S   I N F O       =
// ===================================

/datum/species/lizard/kobold/get_physical_attributes()
	return "Kobolds are small, cave-dwelling reptilians with sharp eyes suited for \
		the dark. They suffer in bright light, cannot read or write, are easily \
		grabbed due to their small stature, and speak a language wholly their own."

/datum/species/lizard/kobold/get_species_description()
	return "Sneaky, nimble-fingered reptilian scavengers who dwell in the deep \
		places of the world. Kobolds are notorious thieves who communicate in \
		a guttural tongue that no other race has ever bothered to learn."

/datum/species/lizard/kobold/get_species_lore()
	return list(
		"Kobolds are among the oldest nuisances known to dwarven civilization. \
		Where dwarves dig fortresses, kobolds inevitably appear at the edges, \
		slipping through shadows to steal whatever isn't nailed down — and \
		sometimes things that are.",

		"No one has ever successfully taught a kobold to read. Whether this is \
		because they are incapable or simply uninterested is a matter of some \
		academic debate, though most dwarves consider the question not worth \
		the ale it takes to discuss.",

		"Kobolds communicate exclusively in their own rasping, clicking language. \
		No other race has ever bothered to learn it, and kobolds have shown \
		little inclination to learn anything else. This suits them fine.",

		"They are cave-dwellers by nature, their slit-pupil eyes large and \
		sensitive in the dark. Bright light pains them, and kobolds caught \
		out in well-lit areas tend to move erratically and with obvious \
		discomfort.",

		"Despite being widely regarded as cowards and pests, kobolds are \
		extraordinarily difficult to fully eradicate. Their colonies vanish \
		and reappear elsewhere with infuriating regularity, and their knack \
		for acquiring other people's belongings is, begrudgingly, impressive.",
	)

// ===================================
// =   P E R K S                     =
// ===================================

/datum/species/lizard/kobold/create_pref_unique_perks()
	var/list/to_add = list()

	to_add += list(
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_SUN,
			SPECIES_PERK_NAME = "Light Sensitivity",
			SPECIES_PERK_DESC = "Kobolds are nocturnal cave-dwellers. Bright light \
				causes them discomfort and slows their movement. \
				Wearing eye protection negates this penalty.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_BOOK,
			SPECIES_PERK_NAME = "Illiterate",
			SPECIES_PERK_DESC = "Kobolds cannot read or write. Signs, books, \
				and written notices are meaningless to them.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_HAND_PAPER,
			SPECIES_PERK_NAME = "Pushover",
			SPECIES_PERK_DESC = "Kobolds are easily grabbed and restrained due to \
				their small, slight frames.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_SHOE_PRINTS,
			SPECIES_PERK_NAME = "Light-Footed",
			SPECIES_PERK_DESC = "Kobolds move without making a sound, making them \
				naturally stealthy.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_EYE,
			SPECIES_PERK_NAME = "Cave Eyes",
			SPECIES_PERK_DESC = "Kobolds see clearly in the dark, their large \
				eyes adapted for cave life.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
			SPECIES_PERK_ICON = FA_ICON_COMMENT,
			SPECIES_PERK_NAME = "Kobold-Tongue Only",
			SPECIES_PERK_DESC = "Kobolds speak only their own rasping language. \
				No other race understands it, and kobolds understand no one else.",
		),
	)

	return to_add

// Override temperature perks to match our cold-blooded cave dweller
/datum/species/lizard/kobold/create_pref_temperature_perks()
	var/list/to_add = list()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = "thermometer-empty",
		SPECIES_PERK_NAME = "Cold-blooded",
		SPECIES_PERK_DESC = "Kobolds are cold-blooded reptilians and cannot regulate \
			their own body temperature. They tolerate heat better than most, \
			but are vulnerable to cold.",
	))

	return to_add

// =======================
// =   L A N G U A G E   =
// =======================

/datum/language/kobold
	name = "Kobold"
	desc = "A rasping, clicking tongue of grunts and hisses. No sane person has ever tried to learn it."
	key = "k"
	icon = 'modular_armok/icons/ui/chat/df_language.dmi'
	icon_state = "kobold"
	// Hidden from everyone, including other species.
	// Kobolds can speak it but no one else can understand it.
	flags = TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_NATIVE_SPEAKER
	default_priority = 100
	syllables = list(
		list(
			// Short, guttural clicks and hisses
			"yip", "yap", "kk", "sst", "chk", "hss", "grr", "rk",
			"nik", "tok", "bik", "pik", "zik", "vik", "mik", "rik",
			"uk", "ik", "ak", "ek", "ok", "sk", "tk", "pk",
			"chi", "cha", "cho", "chu", "che",
			"sni", "sna", "sno", "snu", "sne",
			"kri", "kra", "kro", "kru", "kre",
		),
		list(
			"yipyip", "ssstk", "chkchk", "niknik", "toktok",
			"grrbik", "hsskk", "rkpik", "ziknik", "vikrik",
			"snatok", "krichk", "chotk", "snutk", "kresk",
		),
		list(
			"yip", "sst", "kk", "grr", "chk",
			"nik", "tok", "bik", "zik", "vik",
		),
	)

// Kobolds get a name list too - short, grunty sounding names
GLOBAL_LIST_INIT(kobold_names, world.file2list("strings/names/kobold.txt"))

/datum/language/kobold/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	if(!force_use_syllables && length(GLOB.kobold_names))
		return capitalize(pick(GLOB.kobold_names))
	return ..()

// The language holder: Kobolds ONLY speak and understand Kobold.
// They do NOT understand Common. Common is NOT in their understood list.
// This means they cannot communicate with any other species at all.
/datum/language_holder/kobold
	understood_languages = list(
		/datum/language/kobold = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/kobold = list(LANGUAGE_ATOM),
	)
	// Explicitly block Common so even if something tries to grant it, it doesn't work
	blocked_speaking = list(
		/datum/language/common = list(LANGUAGE_ATOM),
	)
	blocked_understanding = list(
		/datum/language/common = list(LANGUAGE_ATOM),
	)

// ===================
// =   O R G A N S   =
// ===================

/obj/item/organ/tongue/kobold
	name = "kobold tongue"
	desc = "A small, forked tongue that clicks and rasps. Produces sounds utterly alien to civilized races."
	organ_traits = list(TRAIT_SPEAKS_CLEARLY)
	modifies_speech = TRUE
	// Kobolds like scavenged, stolen, or raw foods
	liked_foodtypes  = MEAT | RAW | JUNKFOOD | SUGAR
	disliked_foodtypes = GRAIN | DAIRY | CLOTH
	toxic_foodtypes  = TOXIC
	languages_native = list(/datum/language/kobold)
	// Speech modification: kobolds mix in yips and clicks even when translated
	var/static/list/kobold_speech_replacements = list(
		new /regex(@"\byes\b",  "g") = "yip",
		new /regex(@"\bYes\b",  "g") = "Yip",
		new /regex(@"\bYES\b",  "g") = "YIP",
		new /regex(@"\bno\b",   "g") = "nik",
		new /regex(@"\bNo\b",   "g") = "Nik",
		new /regex(@"\bNO\b",   "g") = "NIK",
		new /regex(@"\bgood\b", "g") = "grrk",
		new /regex(@"\bGood\b", "g") = "Grrk",
		new /regex(@"\bGOOD\b", "g") = "GRRK",
		new /regex(@"\bbad\b",  "g") = "sskk",
		new /regex(@"\bBad\b",  "g") = "Sskk",
		new /regex(@"\bBAD\b",  "g") = "SSKK",
		new /regex(@"\brun\b",  "g") = "yipyip",
		new /regex(@"\bRun\b",  "g") = "Yipyip",
		new /regex(@"\bRUN\b",  "g") = "YIPYIP",
		new /regex(@"\bhelp\b", "g") = "yip yip yip",
		new /regex(@"\bHelp\b", "g") = "Yip yip yip",
		new /regex(@"\bHELP\b", "g") = "YIP YIP YIP",
	)

/obj/item/organ/tongue/kobold/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/speechmod, replacements = kobold_speech_replacements, should_modify_speech = CALLBACK(src, PROC_REF(should_modify_speech)))

/obj/item/organ/tongue/kobold/get_possible_languages()
	return ..() + list(/datum/language/kobold)

/// Kobold eyes: large, sensitive pupils adapted for cave darkness.
/// They have TRUE night vision, but suffer in bright light
/// (the bright light penalty is handled by the species proc, not the eye organ).
/obj/item/organ/eyes/kobold
	name = "kobold eyes"
	desc = "Large, slit-pupilled eyes that gleam in the dark. \
		They see perfectly in near-total darkness, but wince and water in bright light."
	organ_traits = list(TRAIT_TRUE_NIGHT_VISION)
