/**
 * KOBOLDS — Small, cowardly, cave-dwelling reptilian thieves.
 *
 * DF lore: pitch-black trap caves, unlearnable yapping language, no writing,
 * no property concepts, universally regarded as vermin.
 *
 * SETUP:
 *   - #define SPECIES_KOBOLD "kobold"
 *   - Language icon "kobold" in 'modular_armok/icons/ui/chat/df_language.dmi'
 *   - Do NOT add /datum/language/kobold to GLOB.dwarf_fortress_roundstart_languages.
 *     It's deliberately unlearnable by non-kobolds.
 */

// =======================
// =    S P E C I E S    =
// =======================

/datum/species/kobold
	name = "\improper Kobold"
	plural_form = "Kobolds"
	id = SPECIES_KOBOLD
	examine_limb_id = SPECIES_LIZARD

	// Behavioural traits live on the brain now (ILLITERATE, THIEF).
	// Light handling lives on the eyes. This list is purely physical/anatomical.
	inherent_traits = list(
		TRAIT_MUTANT_COLORS,
		TRAIT_DWARF,                    // Dwarf height via the height filter
		TRAIT_GRABWEAKNESS,             // Pushovers — anyone can grab and choke them out
		TRAIT_LIGHT_STEP,               // Thieves' feet: quiet, avoids caltrops/glass
		TRAIT_SKITTISH,                 // Cowardly — dives into crates when grabbed on harm intent
		TRAIT_FREERUNNING,              // Scrambles over tables fast
		TRAIT_TACKLING_FRAIL_ATTACKER,  // Tiny frame splatters against walls
	)

	inherent_biotypes = MOB_ORGANIC | MOB_HUMANOID | MOB_REPTILE

	// No horns, frills, or spines. Kobolds are scrungly, not majestic.
	mutant_organs = list(
		/obj/item/organ/snout = "Round",
		/obj/item/organ/tail/lizard = "Smooth",
	)

	mutantbrain = /obj/item/organ/brain/lizard/kobold
	mutanttongue = /obj/item/organ/tongue/kobold
	mutanteyes = /obj/item/organ/eyes/kobold

	species_language_holder = /datum/language_holder/kobold

	coldmod = 1.5
	heatmod = 0.67
	bodytemp_heat_damage_limit = BODYTEMP_HEAT_LAVALAND_SAFE
	bodytemp_cold_damage_limit = (BODYTEMP_COLD_DAMAGE_LIMIT - 10)

	stunmod = 1.2
	payday_modifier = 0.6

	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT

	meat = /obj/item/food/meat/slab/human/mutant/lizard
	skinned_type = /obj/item/stack/sheet/animalhide/carbon/lizard
	exotic_bloodtype = BLOOD_TYPE_LIZARD
	death_sound = 'sound/mobs/humanoids/lizard/deathsound.ogg'

	digitigrade_customization = DIGITIGRADE_FORCED

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/lizard,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/lizard,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/lizard,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/lizard,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/lizard,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/lizard,
	)

	family_heirlooms = list(
		/obj/item/flashlight/lantern,
		/obj/item/knife/shiv,
	)

/// Cold-blooded — no natural body temp stabilisation, same as lizards
/datum/species/kobold/body_temperature_core(mob/living/carbon/human/humi, seconds_per_tick)
	return

/datum/species/kobold/prepare_human_for_preview(mob/living/carbon/human/human)
	human.dna.features[FEATURE_MUTANT_COLOR] = "#8a7a5c" // Muddy cave brown
	human.update_body(is_creating = TRUE)

/datum/species/kobold/get_hiss_sound(mob/living/carbon/human/kobold)
	return 'sound/mobs/humanoids/lizard/lizard_hiss.ogg'

/datum/species/kobold/get_scream_sound(mob/living/carbon/human/kobold)
	return pick(
		'sound/mobs/humanoids/lizard/lizard_scream_1.ogg',
		'sound/mobs/humanoids/lizard/lizard_scream_2.ogg',
		'sound/mobs/humanoids/lizard/lizard_scream_3.ogg',
	)

/datum/species/kobold/get_laugh_sound(mob/living/carbon/human/kobold)
	return 'sound/mobs/humanoids/lizard/lizard_laugh1.ogg'

// =======================
// =   M O O D L E T S   =
// =======================

/datum/mood_event/kobold_bright_light
	description = "Bright! Too bright! Eyes burning, can't see colour, want dark!"
	mood_change = -3

// ===========================
// =   D E S C  /  P E R K S =
// ===========================

/datum/species/kobold/get_physical_attributes()
	return "Kobolds are tiny, scrawny cave reptiles. Their eyes see perfectly in pitch darkness \
		but wash out to a blurry grey mess in bright light. They can't hold their own in a grapple \
		and are physically incapable of reading, writing, or forming any word that isn't kobold yapping."

/datum/species/kobold/get_species_description()
	return "Small, cowardly, cave-dwelling creatures with an instinct for theft. \
		Kobolds speak a primitive yapping language no other race has ever deciphered, \
		have no concept of writing or property, and are regarded by every civilization \
		as somewhere between 'nuisance' and 'vermin'."

/datum/species/kobold/get_species_lore()
	return list(
		"Kobolds dwell in cramped, trap-riddled caves far from the sun. They have no cities, no \
		writing, no metalwork — only the dark, the tribe, and the endless need to take. Other \
		races do not trade with kobolds. Kobolds do not trade. Kobolds take.",

		"No scholar has ever translated the kobold tongue, and no kobold has ever been taught to \
		speak anything else. Whether this is a limitation of their minds or their throats is a \
		question nobody has ever cared enough to answer.",

		"A kobold's life revolves around three things: finding objects, hiding from anything larger \
		than itself, and yapping at other kobolds about the first two. Dwarves consider them a \
		petty annoyance. Everyone else barely considers them at all.",
	)

/datum/species/kobold/create_pref_temperature_perks()
	return list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = "thermometer-empty",
		SPECIES_PERK_NAME = "Cold-blooded",
		SPECIES_PERK_DESC = "Kobolds are reptilian and cannot regulate their own body temperature. \
			Heat is fine. Cold kills them fast.",
	))

/datum/species/kobold/create_pref_unique_perks()
	return list(
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_EYE,
			SPECIES_PERK_NAME = "Nocturnal",
			SPECIES_PERK_DESC = "Kobold eyes see perfectly in total darkness and can be tuned to \
				several levels of dark adaptation. In bright light, though, their vision blurs and \
				washes out to grey. Sunglasses fix it — or just stay in the shadows.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_HAND_SPARKLES,
			SPECIES_PERK_NAME = "Sticky Paws",
			SPECIES_PERK_DESC = "Kobolds lift things off people faster and quieter than anyone \
				should be comfortable with. Pickpocketing is practically a reflex.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_SHOE_PRINTS,
			SPECIES_PERK_NAME = "Cave Skulker",
			SPECIES_PERK_DESC = "Kobolds step lightly, scramble over obstacles fast, and \
				instinctively dive into the nearest hiding spot when something grabs at them.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_BOOK,
			SPECIES_PERK_NAME = "No Written Word",
			SPECIES_PERK_DESC = "The kobold brain cannot process written language. \
				Books, consoles, signs — all meaningless scratches.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_HAND_ROCK,
			SPECIES_PERK_NAME = "Pushover",
			SPECIES_PERK_DESC = "Kobolds are small and weak. They're easily grabbed, slow to shake \
				off stuns, and crumple when tackled into walls.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_COMMENT_SLASH,
			SPECIES_PERK_NAME = "Incomprehensible",
			SPECIES_PERK_DESC = "The kobold tongue physically cannot form non-kobold words, and \
				no other race can make sense of kobold yapping. Communication will be... creative.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_COINS,
			SPECIES_PERK_NAME = "Vermin",
			SPECIES_PERK_DESC = "Nobody respects a kobold. Paychecks are substantially cut.",
		),
	)

// =======================
// =   L A N G U A G E   =
// =======================

/datum/language/kobold
	name = "Kobold"
	desc = "The frantic yapping tongue of cave kobolds. It has never been translated, has no \
		written form, and sounds to outsiders like a pack of agitated small dogs."
	key = "k"
	icon = 'modular_armok/icons/ui/chat/df_language.dmi'
	icon_state = "kobold"
	flags = TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_NATIVE_SPEAKER
	default_priority = 100
	// No mutual_understanding. Not with anyone. Not ever.
	syllables = list(
		list(
			"yip", "yap", "yep", "yop", "yik",
			"kik", "kak", "kek", "kok", "kuk",
			"rik", "rak", "rek", "rok", "ruk",
			"tik", "tak", "tek", "tok",
			"nik", "nak", "nek", "nok",
			"sik", "sak", "sek", "sok",
			"yi",  "ya",  "ki",  "ka",  "ri",  "ra",
		),
		list(
			"grik", "grak", "grek", "grok",
			"skrit", "skrat", "skret",
			"klik", "klak", "klek", "klok",
			"snik", "snak", "snek",
			"flik", "flak", "flek",
			"trik", "trak", "trok",
			"stok", "stolk", "strob",
		),
		list(
			"yippik", "yappak", "kikrik", "rakkak",
			"skritti", "grakko", "snikka", "trokki",
			"klakkek", "yekkit", "tokkuk", "stobnus",
		),
	)

GLOBAL_LIST_INIT(kobold_name_syllables, list(
	"bil", "bus", "dan", "dak", "dro", "dus", "fli", "gno",
	"gus", "jik", "jli", "ker", "kit", "kro", "lis", "mog",
	"nik", "nus", "pog", "ris", "rus", "sna", "sno", "sto",
	"stolk", "strob", "tli", "tol", "tro", "yer", "zus",
))

/datum/language/kobold/get_random_name(
	gender = NEUTER,
	name_count = default_name_count,
	syllable_min = default_name_syllable_min,
	syllable_max = default_name_syllable_max,
	force_use_syllables = FALSE,
)
	if(force_use_syllables || !length(GLOB.kobold_name_syllables))
		return ..()

	var/name = ""
	for(var/i in 1 to rand(2, 4))
		name += pick(GLOB.kobold_name_syllables)
	return capitalize(name)

/datum/language_holder/kobold
	understood_languages = list(
		/datum/language/kobold = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/kobold = list(LANGUAGE_ATOM),
	)

// ===================
// =   O R G A N S   =
// ===================

/**
 * The kobold brain carries the behavioural traits. Swap it out and a kobold could
 * theoretically learn to read — not that anyone's tried.
 *
 * If /obj/item/organ/brain/lizard ever picks up organ_traits of its own, switch this to
 * `organ_traits = parent_type::organ_traits + list(...)` (515+).
 */
/obj/item/organ/brain/lizard/kobold
	name = "kobold brain"
	desc = "Notably small, even for a reptilian. The regions that would normally handle symbolic \
		reasoning are almost entirely atrophied — what's left is mostly hindbrain, object \
		permanence, and an overwhelming drive to acquire."
	organ_traits = list(
		TRAIT_ILLITERATE,  // The brain genuinely can't parse abstract symbols. It's not stubbornness.
		TRAIT_THIEF,       // Faster, quieter stripping. Less of a skill, more of a compulsion with good hand-eye.
	)

/**
 * The tongue is the hard physical lock on the language barrier.
 * get_possible_languages() returns ONLY kobold — even with a language implant, the throat
 * just can't make those sounds.
 *
 * Transplant edge cases all work correctly:
 *   - Kobold tongue into a human: human can only yap. Hilarious.
 *   - Human tongue into a kobold: kobold can speak common but loses kobold. A real tradeoff.
 */
/obj/item/organ/tongue/kobold
	name = "kobold tongue"
	desc = "A thin, twitchy little tongue. Looks incapable of producing anything but sharp yips."
	say_mod = "yaps"
	organ_traits = list(TRAIT_SPEAKS_CLEARLY)
	liked_foodtypes = MEAT | GORE | GROSS | BUGS // Cave scavengers. They eat whatever.
	disliked_foodtypes = VEGETABLES | DAIRY | CLOTH
	toxic_foodtypes = TOXIC
	languages_native = list(/datum/language/kobold)

/obj/item/organ/tongue/kobold/get_possible_languages()
	return list(/datum/language/kobold)

/// Lumcount threshold. 0.75 is properly bright — full overhead station lighting territory.
/// A penlight or pocket lighter in an otherwise-dark room won't come close to this.
#define KOBOLD_GLARE_LIGHT_THRESHOLD 0.75

/// Filter ID on the game plane masters. Stays attached at identity between glare
/// cycles (a no-op identity matrix costs nothing and means we never have to
/// re-add it, which is what lets the fade-out actually work).
#define KOBOLD_GLARE_FILTER "kobold_eye_glare"
#define KOBOLD_GLARE_FADE_IN (8 SECONDS)
#define KOBOLD_GLARE_FADE_OUT (12 SECONDS)
/// High priority = applied late in the stack = desaturation sits on top of everything else.
#define KOBOLD_GLARE_FILTER_PRIORITY 50

/obj/item/organ/eyes/kobold
	name = "kobold eyes"
	desc = "Enormous, dark-adapted eyes with slitted pupils. They glitter in shadow and \
		shrink to agonised pinpricks in the light."
	icon_state = "lizard_eyes"
	synchronized_blinking = FALSE
	flash_protect = FLASH_PROTECTION_SENSITIVE
	organ_traits = list(
		TRAIT_TRUE_NIGHT_VISION,
		TRAIT_REFLECTIVE_EYES,
	)

	pupils_name = "slit pupils"
	penlight_message = "shrink to pained slits, watering under the beam"

	/// Gate for the to_chat spam and trait/mood bookkeeping. The filter itself
	/// is idempotent either way, this just stops us re-announcing every tick.
	var/glared = FALSE

/obj/item/organ/eyes/kobold/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	glared = FALSE

/obj/item/organ/eyes/kobold/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	// Only place we ever actually REMOVE the filter. Between glare cycles it just
	// sits at identity doing nothing.
	if(organ_owner.hud_used)
		for(var/atom/movable/screen/plane_master/game_plane as anything in organ_owner.hud_used.get_true_plane_masters(RENDER_PLANE_GAME))
			game_plane.remove_filter(KOBOLD_GLARE_FILTER)
	REMOVE_TRAIT(organ_owner, TRAIT_COLORBLIND, REF(src))
	organ_owner.clear_mood_event("kobold_bright_light")
	glared = FALSE
	return ..()

/obj/item/organ/eyes/kobold/on_life(seconds_per_tick)
	. = ..()

	var/in_painful_light = owner.get_eye_protection() <= FLASH_PROTECTION_SENSITIVE \
		&& !owner.is_blind() \
		&& isturf(owner.loc) \
		&& owner.has_light_nearby(light_amount = KOBOLD_GLARE_LIGHT_THRESHOLD)

	if(in_painful_light)
		if(!glared)
			start_glare()
		owner.adjust_eye_blur_up_to(2 SECONDS, 10 SECONDS)
	else if(glared)
		stop_glare()

/**
 * Why we're not using /datum/client_colour here:
 *
 * client_colour's fade_out is architecturally broken — Destroy() removes the datum from
 * the list BEFORE calling animate_client_colour(), and animate_client_colour() always
 * rebuilds filters from scratch (remove all → add blank identity → transition to target).
 * By the time the animation runs, our greyscale is gone from the list, so the filter just
 * gets ripped off instantly in the remove step.
 *
 * Driving the filter directly fixes this: transition_filter() animates from the filter's
 * CURRENT state to the target. We add the filter once (at identity, invisible), transition
 * it to greyscale on glare, transition back to identity on recovery, and only actually
 * remove it when the organ leaves the body.
 *
 * Bonus: walking back into light mid-fade-out just smoothly reverses from wherever the
 * transition had got to. No pop, no timer juggling.
 */
/obj/item/organ/eyes/kobold/proc/start_glare()
	glared = TRUE
	ADD_TRAIT(owner, TRAIT_COLORBLIND, REF(src))
	owner.add_mood_event("kobold_bright_light", /datum/mood_event/kobold_bright_light)
	to_chat(owner, span_warning("The light stabs into your eyes — colour starts bleeding out of the world."))

	if(isnull(owner.hud_used))
		return
	for(var/atom/movable/screen/plane_master/game_plane as anything in owner.hud_used.get_true_plane_masters(RENDER_PLANE_GAME))
		// Might already exist from a previous glare cycle (sitting at identity). Only add if fresh.
		if(isnull(game_plane.get_filter(KOBOLD_GLARE_FILTER)))
			game_plane.add_filter(KOBOLD_GLARE_FILTER, KOBOLD_GLARE_FILTER_PRIORITY, color_matrix_filter())
		// Transition from wherever it is now → greyscale. Works from identity OR mid-fade-out.
		game_plane.transition_filter(KOBOLD_GLARE_FILTER, color_matrix_filter(COLOR_MATRIX_GRAYSCALE), KOBOLD_GLARE_FADE_IN)

/obj/item/organ/eyes/kobold/proc/stop_glare()
	glared = FALSE
	REMOVE_TRAIT(owner, TRAIT_COLORBLIND, REF(src))
	owner.clear_mood_event("kobold_bright_light")
	to_chat(owner, span_notice("Colour slowly seeps back as your pupils readjust."))

	if(isnull(owner.hud_used))
		return
	for(var/atom/movable/screen/plane_master/game_plane as anything in owner.hud_used.get_true_plane_masters(RENDER_PLANE_GAME))
		// Transition from current (greyscale or mid-fade-in) → identity. Filter stays attached.
		game_plane.transition_filter(KOBOLD_GLARE_FILTER, color_matrix_filter(), KOBOLD_GLARE_FADE_OUT)

/obj/item/organ/eyes/kobold/penlight_examine(mob/living/viewer, obj/item/examtool)
	if(!owner.is_blind() && owner.get_eye_protection() <= FLASH_PROTECTION_SENSITIVE)
		to_chat(owner, span_danger("Gah! The beam! Right in the eyes!"))
		owner.adjust_eye_blur_up_to(8 SECONDS * examtool.light_power, 12 SECONDS)
	return span_notice("[owner.p_Their()] eyes [penlight_message].")

#undef KOBOLD_GLARE_LIGHT_THRESHOLD
#undef KOBOLD_GLARE_FILTER
#undef KOBOLD_GLARE_FADE_IN
#undef KOBOLD_GLARE_FADE_OUT
#undef KOBOLD_GLARE_FILTER_PRIORITY
