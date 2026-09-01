# Flow 3A Prompt — Illustrated Header Card Artwork

Create one finished, print-ready header-card artwork before generating the packaged product photo.

Before using this prompt, derive and lock `main_title_ja` from visible content in the user's original photo and save it in `02a-header-card-title.txt`. It must be a newly generated short, natural Japanese phrase—not a fixed default—based on the clearest visible action, gesture, prop, accessory, outfit/season cue, or mood. Normally keep it to 3–8 Japanese characters and one display line. Do not infer a name, identity, occupation, sensitive trait, brand, copyrighted title, or off-image story.

## Input roles

- `Image 1 = 02-crayon-illustration.png; sole source for the person's identity, outfit, pose cues, palette, rough-crayon drawing language, and character design.`
- `Image 2 = assets/flow-3-header-card-typography-reference.png; reference only for the bold, chunky, compact display-letter proportions and left-text/right-character layout.`

Do not copy Image 2's words, logo, character, colors, dots, branding, package, or exact card design.

## Card format and composition

Create only the flat header-card artwork, not the plastic bag or product photo.

- wide horizontal cardstock rectangle, approximately 2.1:1 to 2.4:1
- straight-on front view with all four edges visible
- left half reserved for two text lines
- right half reserved for one character derived from Image 1
- no overlap between the character's face and the text
- clear margins around text and character
- balanced indie-toy label composition with strong readability at small print size

Place the character decisively in the right half. Preserve the recognizable face, hairstyle, outfit, accessories, and rough chibi proportions from Image 1. A three-quarter or full-body crop is acceptable as long as the character remains clear and does not drift into the left text block. Do not add other people, animals, toys, or mascots.

## Exact text

Render exactly two lines on the left half and no other text:

1. Main title: exact `main_title_ja` from `02a-header-card-title.txt`
2. Subtitle: `HANDMADE SOFUBI`

The main title must be one line. In the actual image prompt, include the exact title once and spell its character sequence character by character. The subtitle must be one smaller line and contain exactly: `H-A-N-D-M-A-D-E`, one space, `S-O-F-U-B-I`.

Do not replace the generated phrase with any recurring default or previously used title. Do not translate, paraphrase, duplicate, curve, split, or add punctuation to either line. Do not add a logo, barcode, product number, signature, watermark, copyright line, or decorative pseudo-text. If the user explicitly supplies a replacement title in a later run, replace only `main_title_ja` and keep every other layout rule.

## Typography and illustration style

Use Image 2 only for the overall massing of the letters: large, bold, chunky, slightly condensed, compact Japanese display lettering with a playful hand-cut poster feeling.

Redraw the lettering in the same visual medium as the character from Image 1:

- rough crayon / oil-pastel grain
- thick deep blue-violet or indigo hand-drawn outline
- slightly wobbly edges and naive asymmetry
- uneven pastel fill with visible paper texture
- small gaps, repeated strokes, and slight coloring irregularity
- warm coral-red or orange-red main-title fill with a soft cream border when compatible with Image 1's palette
- smaller hand-lettered block subtitle, visually subordinate but clearly readable

The text must look illustrated together with the character, not pasted on as clean digital typography. Avoid vector-perfect edges, standard computer fonts, glossy 3D letters, metallic effects, photoreal type, or a typography style that clashes with Image 1.

## Background

Build a simple pastel background from Image 1's palette and rough-crayon language. Loose dots, doodles, or broad color areas are allowed, but keep the left text block readable and the right character distinct. Do not reproduce the reference image's exact blue halftone pattern.

## Acceptance criteria

Accept only when:

- exact `main_title_ja` from `02a-header-card-title.txt` is on one line, large, and entirely in the left half
- `HANDMADE SOFUBI` is exact, smaller, on one line, and directly below the title
- the same illustrated person from Image 1 occupies the right half
- all lettering shares the person's rough crayon / oil-pastel style
- the complete flat card is visible with no package, toy, plastic bag, staples, perspective distortion, extra text, copied branding, or watermark

If either text line is misspelled or malformed, make one targeted text-only correction while comparing against `02a-header-card-title.txt`. Preserve the card dimensions, left/right layout, character, palette, rough-crayon style, and every correct character in both lines.
