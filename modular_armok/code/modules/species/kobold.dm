/**
 * KOBOLDS — Small, cowardly, cave-dwelling reptilian thieves.
 *
 * Based on Dwarf Fortress lore:
 *   - Live in pitch-black, trap-riddled caves
 *   - Speak an unlearnable yapping language no other race has ever deciphered
 *   - No writing, no metallurgy, no concept of property — they just take things
 *   - Weak, cowardly, and considered vermin by every civilization
 *
 * SETUP REQUIREMENTS (add these to your defines):
 *   - #define SPECIES_KOBOLD "kobold"  -> code/__DEFINES/mobs.dm or similar
 *   - Language icon "kobold" in 'modular_armok/icons/ui/chat/df_language.dmi'
 *   - Do NOT add /datum/language/kobold to GLOB.dwarf_fortress_roundstart_languages.
 *     It's meant to be unlearnable by non-kobolds. That's the whole point.
 */

/// Turf lumcount (0-1) above which a kobold starts squinting.
#define KOBOLD_BRIGHT_LIGHT_THRESHOLD 0.5
/// Turf lumcount below which darkness feels cozy
#define KOBOLD_COMFY_DARK_THRESHOLD 0.2
/// Percent-per-second chance to apply a brief blur while in bright light
#define KOBOLD_SQUINT_PROB 8
/// Time a kobold can go without picking something up before their paws start itching
#define KOBOLD_ACQUISITION_CRAVING_TIME (10 MINUTES)

// =======================
// =    S P E C I E S    =
// =======================

/datum/species/kobold
	name = "\improper Kobold"
	plural_form = "Kobolds"
	id = SPECIES_KOBOLD
	examine_limb_id = SPECIES_LIZARD // Riding on lizard sprites. Kobolds are just worse lizards.

	inherent_traits = list(
		TRAIT_MUTANT_COLORS,            // Scale colour
		TRAIT_DWARF,                    // Dwarf-height via the height filter
		TRAIT_GRABWEAKNESS,             // Pushovers — anyone can grab and choke them out
		TRAIT_LIGHT_STEP,               // Thieves' feet: quiet, avoids caltrops/glass
		TRAIT_SKITTISH,                 // Cowardly — dives into crates/lockers when grabbed on harm intent
		TRAIT_FREERUNNING,              // Scrambles over tables fast — good for fleeing
		TRAIT_TACKLING_FRAIL_ATTACKER,  // Tiny frame splatters against walls when tackling goes wrong
		TRAIT_THIEF,                    // Core thief trait — reduces steal time, suppresses theft notifications
	)

	inherent_biotypes = MOB_ORGANIC | MOB_HUMANOID | MOB_REPTILE

	// Stripped-down lizard feature set. Kobolds don't get horns, frills, or spines.
	// They are not majestic. They are scrungly.
	mutant_organs = list(
		/obj/item/organ/snout = "Round",
		/obj/item/organ/tail/lizard = "Smooth",
	)

	mutanttongue = /obj/item/organ/tongue/kobold
	mutanteyes = /obj/item/organ/eyes/kobold
	mutantbrain = /obj/item/organ/brain/kobold

	species_language_holder = /datum/language_holder/kobold

	// Cold-blooded cave reptile
	coldmod = 1.5
	heatmod = 0.67
	bodytemp_heat_damage_limit = BODYTEMP_HEAT_LAVALAND_SAFE
	bodytemp_cold_damage_limit = (BODYTEMP_COLD_DAMAGE_LIMIT - 10)

	// Weak, slow to recover, and nobody wants to pay a kobold
	stunmod = 1.2
	payday_modifier = 0.6

	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT

	meat = /obj/item/food/meat/slab/human/mutant/lizard
	skinned_type = /obj/item/stack/sheet/animalhide/carbon/lizard
	exotic_bloodtype = BLOOD_TYPE_LIZARD
	death_sound = 'sound/mobs/humanoids/lizard/deathsound.ogg'

	// Always digitigrade — they're basically cave animals
	digitigrade_customization = DIGITIGRADE_FORCED

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/lizard,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/lizard,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/lizard,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/lizard,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/lizard,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/lizard,
	)

	// Things a kobold family would treasure
	family_heirlooms = list(
		/obj/item/flashlight/lantern, // Cave lamp
		/obj/item/knife/shiv,         // Crude pointy thing
	)

	/// world.time of the last item the kobold picked up. Drives the kleptomaniac mood cycle.
	var/last_acquisition_time = 0

/// Cold-blooded — no natural body temp stabilisation, same as lizards
/datum/species/kobold/body_temperature_core(mob/living/carbon/human/humi, seconds_per_tick)
	return

/datum/species/kobold/on_species_gain(mob/living/carbon/human/new_kobold, datum/species/old_species, pref_load, regenerate_icons)
	. = ..()
	if(!ishuman(new_kobold))
		return

	// Grace period — don't spawn already itchy
	last_acquisition_time = world.time

	// COMSIG_ATOM_ENTERED fires whenever an item enters the mob's direct contents (hands,
	// pockets, worn slots). It does NOT fire for slot-to-slot shuffling since loc doesn't
	// change. Bags are their own atom so taking from a worn bag DOES fire — we filter that below.
	RegisterSignal(new_kobold, COMSIG_ATOM_ENTERED, PROC_REF(on_something_entered))

/datum/species/kobold/on_species_loss(mob/living/carbon/human/former_kobold, datum/species/new_species, pref_load)
	UnregisterSignal(former_kobold, COMSIG_ATOM_ENTERED)
	former_kobold.clear_mood_event("kobold_shiny")
	former_kobold.clear_mood_event("kobold_no_shiny")
	former_kobold.clear_mood_event("kobold_bright_light")
	former_kobold.clear_mood_event("kobold_comfy_dark")
	return ..()

/datum/species/kobold/spec_life(mob/living/carbon/human/kobold, seconds_per_tick)
	. = ..()
	if(kobold.stat >= UNCONSCIOUS)
		return

	handle_kleptomaniac_urges(kobold)

/// The Urges. Go too long without taking something and the paws get itchy.
/datum/species/kobold/proc/handle_kleptomaniac_urges(mob/living/carbon/human/kobold)
	if(world.time > last_acquisition_time + KOBOLD_ACQUISITION_CRAVING_TIME)
		kobold.clear_mood_event("kobold_shiny")
		kobold.add_mood_event("kobold_no_shiny", /datum/mood_event/kobold_no_shiny)

/**
 * Fires when anything enters the kobold's direct contents.
 * Filters out internal stuff (limbs, organs, implants) and shuffling from our own worn storage.
 *
 * Kobolds have zero sense of value — a rusted fork is as precious as a captain's ID.
 * We don't check item worth. Any acquisition feeds the compulsion.
 */
/datum/species/kobold/proc/on_something_entered(mob/living/carbon/human/kobold, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER

	if(!isitem(arrived))
		return
	var/obj/item/thing = arrived
	if(thing.item_flags & ABSTRACT)
		return
	// Limbs being attached, organs inserted, implants going in — surgery isn't shopping
	if(isbodypart(thing) || isorgan(thing) || istype(thing, /obj/item/implant))
		return
	// Fishing something out of a bag we're already wearing isn't really new
	if(old_loc?.loc == kobold)
		return

	last_acquisition_time = world.time
	kobold.clear_mood_event("kobold_no_shiny")
	kobold.add_mood_event("kobold_shiny", /datum/mood_event/kobold_shiny)

/datum/species/kobold/prepare_human_for_preview(mob/living/carbon/human/human)
	human.dna.features[FEATURE_MUTANT_COLOR] = "#8a7a5c" // Muddy cave brown
	human.update_body(is_creating = TRUE)

// Reuse lizard vocals — they're reptilian enough
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

/datum/mood_event/kobold_shiny
	description = "Thing! Got thing! Mine now! Good good good!"
	mood_change = 2
	timeout = KOBOLD_ACQUISITION_CRAVING_TIME // Lines up with when the urge returns

/datum/mood_event/kobold_no_shiny
	description = "Paws itchy. Need take thing. ANY thing. Been too long..."
	mood_change = -3

/datum/mood_event/kobold_bright_light
	description = "Bright! Too bright! Eyes burning, head hurting, want dark!"
	mood_change = -3

/datum/mood_event/kobold_comfy_dark
	description = "Dark. Safe. Good place for hiding, good place for taking."
	mood_change = 1

// ===========================
// =   D E S C  /  P E R K S =
// ===========================

/datum/species/kobold/get_physical_attributes()
	return "Kobolds are tiny, scrawny cave reptiles. They see perfectly in pitch darkness but are \
		blinded and colorblind in bright light. They can't hold their own in a grapple, are \
		physically incapable of reading or writing, and speak only in incomprehensible yapping."

/datum/species/kobold/get_species_description()
	return "Small, cowardly, cave-dwelling creatures with an insatiable compulsion to steal. \
		Kobolds speak a primitive yapping language no other race has ever deciphered, have no \
		concept of writing or property, and are regarded by every civilization as somewhere \
		between 'nuisance' and 'vermin'."

/datum/species/kobold/get_species_lore()
	return list(
		"Kobolds dwell in cramped, trap-riddled caves far from the sun. They have no cities, no \
		writing, no metalwork — only the dark, the tribe, and the endless need to take. Other races \
		do not trade with kobolds. Kobolds do not trade. Kobolds take.",

		"No scholar has ever translated the kobold tongue, and no kobold has ever been taught to \
		speak anything else. Whether this is a limitation of their minds or their throats is a \
		question nobody has ever cared enough to answer.",

		"A kobold's life revolves around three things: finding objects, hiding from anything larger \
		than itself, and yapping at other kobolds about the first two. Dwarves consider them a \
		petty annoyance. Everyone else barely considers them at all.",
	)

/// Override the default temperature perks with a single cold-blooded entry, lizard-style
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
			SPECIES_PERK_DESC = "Kobolds see perfectly in complete darkness. Bright light, however, \
				causes blurring and temporary colorblindness. Wear sunglasses — or stick to the shadows.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_SHOE_PRINTS,
			SPECIES_PERK_NAME = "Cave Skulker",
			SPECIES_PERK_DESC = "Kobolds step lightly, scramble over obstacles fast, and instinctively \
				dive into the nearest hiding spot when something grabs at them.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_HAND_SPARKLES,
			SPECIES_PERK_NAME = "Born Thief",
			SPECIES_PERK_DESC = "Kobolds are natural thieves. They steal faster and more quietly than \
				any other race.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
			SPECIES_PERK_ICON = FA_ICON_HAND_SPARKLES,
			SPECIES_PERK_NAME = "Compulsive Taker",
			SPECIES_PERK_DESC = "Kobolds have no concept of property. Picking things up is joy. \
				Going too long without acquiring something new is misery.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_BOOK,
			SPECIES_PERK_NAME = "No Written Word",
			SPECIES_PERK_DESC = "Kobolds cannot read or write. Books, consoles, signs — \
				all meaningless scratches.",
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
			SPECIES_PERK_DESC = "Nobody respects a kobold. Paychecks are substantially cut — \
				you're lucky they pay you at all.",
		),
	)

// =======================
// =   L A N G U A G E   =
// =======================

/**
 * The kobold language. Deliberately unlearnable.
 *
 * In DF, nobody has ever translated it — it's just noise to everyone else. We enforce this by:
 *   1. NOT adding it to GLOB.dwarf_fortress_roundstart_languages (can't pick it in chargen)
 *   2. The kobold tongue organ only returns this language from get_possible_languages()
 *   3. No mutual_understanding with anything
 *
 * The only ways another race could ever speak this are tongue transplant or admin shenanigans.
 * Both of which are funny, so that's fine.
 */
/datum/language/kobold
	name = "Kobold"
	desc = "The frantic yapping tongue of cave kobolds. It has never been translated, has no written \
		form, and sounds to outsiders like a pack of agitated small dogs."
	key = "k"
	icon = 'modular_armok/icons/ui/chat/df_language.dmi'
	icon_state = "kobold"
	flags = TONGUELESS_SPEECH | LANGUAGE_HIDE_ICON_IF_NATIVE_SPEAKER
	default_priority = 100
	// No mutual_understanding. Not with anyone. Not ever.
	syllables = list(
		// Short yips — the filler
		list(
			"yip", "yap", "yep", "yop", "yik",
			"kik", "kak", "kek", "kok", "kuk",
			"rik", "rak", "rek", "rok", "ruk",
			"tik", "tak", "tek", "tok",
			"nik", "nak", "nek", "nok",
			"sik", "sak", "sek", "sok",
			"yi",  "ya",  "ki",  "ka",  "ri",  "ra",
		),
		// Scratchy consonant clusters — the "words"
		list(
			"grik", "grak", "grek", "grok",
			"skrit", "skrat", "skret",
			"klik", "klak", "klek", "klok",
			"snik", "snak", "snek",
			"flik", "flak", "flek",
			"trik", "trak", "trok",
			"stok", "stolk", "strob",
		),
		// Longer compounds — the "concepts"
		list(
			"yippik", "yappak", "kikrik", "rakkak",
			"skritti", "grakko", "snikka", "trokki",
			"klakkek", "yekkit", "tokkuk", "stobnus",
		),
	)

// DF kobold names are nonsense compounds. No surnames — kobolds have no family structure.
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
	var/syllable_count = rand(2, 4)
	for(var/i in 1 to syllable_count)
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
 * Kobold brain: carries TRAIT_ILLITERATE directly so that it travels with the organ.
 *
 * Putting illiteracy on the brain rather than the species datum means:
 *   - A transplanted human brain lets a kobold read (they got smarter, narratively fine)
 *   - A kobold brain in a human makes them illiterate (it's a dumb lizard brain, what did you expect)
 * This is the correct behaviour for an organ-level trait.
 */
/obj/item/organ/brain/kobold
	name = "kobold brain"
	desc = "Tiny, surprisingly dense, and completely devoid of any understanding of the written word. \
		Studies suggest it is structurally incapable of processing abstract symbols."
	organ_traits = list(TRAIT_ILLITERATE)

/**
 * The kobold tongue enforces the language barrier at the organ level.
 * get_possible_languages() returns ONLY kobold — the throat just can't make other sounds.
 *
 * No speechmod. No regex. Kobolds don't speak anything intelligible to begin with,
 * so mangling non-kobold words would only matter if someone gave them a foreign tongue via surgery,
 * at which point they should just speak normally (it's a normal tongue now).
 *
 * Transplant edge cases:
 *   - Kobold tongue into a human: human can only yap. Hilarious.
 *   - Human tongue into a kobold: kobold can speak common but loses kobold. A fair trade.
 */
/obj/item/organ/tongue/kobold
	name = "kobold tongue"
	desc = "A thin, twitchy little tongue. It looks incapable of producing anything but sharp yips."
	say_mod = "yaps"
	organ_traits = list(TRAIT_SPEAKS_CLEARLY)
	liked_foodtypes = MEAT | GORE | GROSS | BUGS // Cave scavengers. They eat whatever.
	disliked_foodtypes = VEGETABLES | DAIRY | CLOTH
	toxic_foodtypes = TOXIC
	languages_native = list(/datum/language/kobold)

/// Hard restriction: only kobold is physically producible by this throat.
/obj/item/organ/tongue/kobold/get_possible_languages()
	return list(/datum/language/kobold)

/**
 * Kobold eyes: built for total darkness, punished by light.
 *
 * In bright light (above KOBOLD_BRIGHT_LIGHT_THRESHOLD turf lumcount), the eyes:
 *   - Periodically apply a brief blur (squinting)
 *   - Apply a monochrome client colour (everything washes out)
 *   - Add a bad mood event
 * Sunglasses (flash_protect >= 0, net 0 with our -1 base) fully negate the effect.
 *
 * Behaves like /obj/item/organ/eyes/night_vision/maintenance_adapted in structure,
 * but uses blur + colorblind instead of organ damage, so the effect is temporary
 * and reversible rather than a death spiral.
 *
 * The on_life proc handles the per-tick effect. We register/unregister it cleanly
 * on insert/remove so there's no dangling state.
 */
/obj/item/organ/eyes/kobold
	name = "kobold eyes"
	desc = "Enormous, dark-adapted eyes with slitted pupils. They glitter in shadow and \
		shrink to agonised pinpricks in the light."
	icon_state = "lizard_eyes"   // Reuse lizard eye icon — kobolds are lizard-adjacent
	synchronized_blinking = FALSE
	// Sensitive to flash — any flash hits one step harder. Net with sunglasses (+1) = 0, cancels the glare.
	flash_protect = FLASH_PROTECTION_SENSITIVE
	organ_traits = list(
		TRAIT_TRUE_NIGHT_VISION, // Full darkvision — they live in zero-light caves
		TRAIT_REFLECTIVE_EYES,   // Eyeshine in dim light. Pure flavour.
	)
	pupils_name = "slit pupils"
	penlight_message = "have vertically slit pupils that contract sharply under the light"

/obj/item/organ/eyes/kobold/on_mob_insert(mob/living/carbon/receiver, special, movement_flags)
	. = ..()
	// We use on_life for the per-tick light check instead of a signal,
	// because lumcount needs to be polled — there's no signal for "turf got brighter".
	// on_life is already called by the organ system while inserted, so no extra registration needed.

/obj/item/organ/eyes/kobold/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	// Clean up any lingering light sensitivity effects when the eyes come out.
	// This covers surgery, species change, and death-state organ removal.
	_clear_light_effects(organ_owner)
	return ..()

/**
 * Per-tick light sensitivity handler.
 *
 * Called by the organ's own on_life proc (inherited from /obj/item/organ).
 * Checks the owner's current turf lumcount and applies or clears effects accordingly.
 */
/obj/item/organ/eyes/kobold/on_life(seconds_per_tick, times_fired)
	. = ..()
	if(!owner || owner.stat >= UNCONSCIOUS)
		_clear_light_effects(owner)
		return

	// Sunglasses or better cancel the effect entirely. flash_protect -1 + eyewear +1 = 0.
	if(owner.get_eye_protection() >= FLASH_PROTECTION_NONE)
		_clear_light_effects(owner)
		return

	var/turf/standing = get_turf(owner)
	if(isnull(standing))
		return

	var/light_amount = standing.get_lumcount()

	if(light_amount >= KOBOLD_BRIGHT_LIGHT_THRESHOLD)
		// We're in the bright zone. Apply misery.
		if(!HAS_TRAIT_FROM_ONLY(owner, TRAIT_COLORBLIND, /obj/item/organ/eyes/kobold))
			owner.add_client_colour(/datum/client_colour/monochrome, REF(src))
			ADD_TRAIT(owner, TRAIT_COLORBLIND, /obj/item/organ/eyes/kobold)
		owner.add_mood_event("kobold_bright_light", /datum/mood_event/kobold_bright_light)
		owner.clear_mood_event("kobold_comfy_dark")
		// Periodic squinting — short, capped blur so it doesn't stack into true blindness
		if(SPT_PROB(KOBOLD_SQUINT_PROB, seconds_per_tick))
			owner.adjust_eye_blur_up_to(2 SECONDS, 4 SECONDS)

	else if(light_amount < KOBOLD_COMFY_DARK_THRESHOLD)
		// Cozy dark. Clear light pain.
		_clear_light_effects(owner)
		owner.add_mood_event("kobold_comfy_dark", /datum/mood_event/kobold_comfy_dark)

	else
		// Dim — neither painful nor cozy. Clear everything.
		_clear_light_effects(owner)

/// Removes all light-sensitivity side effects from the target mob.
/// Safe to call even if the effects aren't currently applied.
/obj/item/organ/eyes/kobold/proc/_clear_light_effects(mob/living/carbon/target)
	if(isnull(target))
		return
	// Only remove OUR colorblind application, not any from quirks or other sources
	if(HAS_TRAIT_FROM_ONLY(target, TRAIT_COLORBLIND, /obj/item/organ/eyes/kobold))
		target.remove_client_colour(REF(src))
		REMOVE_TRAIT(target, TRAIT_COLORBLIND, /obj/item/organ/eyes/kobold)
	target.clear_mood_event("kobold_bright_light")
	target.clear_mood_event("kobold_comfy_dark")

#undef KOBOLD_BRIGHT_LIGHT_THRESHOLD
#undef KOBOLD_COMFY_DARK_THRESHOLD
#undef KOBOLD_SQUINT_PROB
#undef KOBOLD_ACQUISITION_CRAVING_TIME
