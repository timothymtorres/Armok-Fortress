#define SPECIES_DWARF "dwarf"

// ==============================
// = K O B O L D   D E F I N E S =
// ==============================

/// The luminosity threshold above which a kobold suffers bright-light penalty.
/// Standard lit station areas are ~0.7–1.0. We trigger at 0.6 to catch most lit rooms.
#define KOBOLD_BRIGHT_LIGHT_THRESHOLD    0.6

/// The luminosity threshold below which a kobold feels comfortably at home in the dark.
#define KOBOLD_COMFORTABLE_DARK_THRESHOLD 0.3

/// The multiplicative movespeed slowdown applied when a kobold is in bright light.
/// Positive values = slower. 0.3 = 30% slower movement.
#define KOBOLD_LIGHT_SLOWDOWN            0.3

/// Species ID string for kobolds
#define SPECIES_KOBOLD "kobold"
