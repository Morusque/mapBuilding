# Map Builder

Concise map sketcher with editable cells, elevation, biomes, zones, paths, structures, labels, and flexible rendering/export.

## Modes
- **Cells**: create/regenerate the base grid, relax/center, run “fully generate” to build a demo map end-to-end.
- **Elevation**: random elevation, plateaux smoothing, sea level, slice spot (former beaches) at any height, lighting (azimuth/altitude/strength), contours.
- **Biomes**: assign biomes by painting or full generation; per-biome pattern index, saturation, brightness, fill alpha, underwater alpha, outlines; patterns come from `data/patterns/*`.
- **Zones**: draw or auto-generate regions, exclude water, set names/colors/comments; outlines alpha/sat/bri sliders; labels can show zone names.
- **Paths**: create path types and instances; width, tapering, water matching, saturation scale, alpha; snapping to cells/structures; comments and labels per path.
- **Structures**: generic shapes (rect, circle, triangle, etc.) with size, angle (absolute), ratio, alignment (none/next/center), hue/sat/alpha/stroke, name/comment; snapping to paths/frontiers/structures; generator clusters circles/rectangles near paths/coasts without overlaps.
- **Labels**: arbitrary labels and generated names (syllable mash); toggle label types; comments per label; generation adds a handful of names at sensible spots.
- **Rendering**: land/water colors, biome fills/patterns/background patterns, biome sat/bri, cell border alpha, water depth, coastlines and ripples, water hatching (angle/length/spacing/alpha), elevation shading/contours, zone strokes, path saturation, label outline, padding/presets.
- **Export**: PNG with scale/padding; SVG layered (background, water, biomes, zones, coasts, paths, structures, text) with data attributes; JSON includes all elements plus comments.

## Generation helpers
- “Generate everything from there” (Cells mode) runs: elevation generate → 5× plateaux → biomes full generate → zones regenerate + exclude water → paths generate → structures generate → labels generate.
- Each mode also has its own generate/regenerate controls for focused tweaks.

## Comments
- Paths, zones, structures, labels each have a comment field (single-line for now); shown in their attribute panels, applied to multi-selection when set; exported in JSON and as non-rendered SVG metadata.

## Gallery
![Rendered map](images/map_20251209_135501.png)
![Rendered map](images/map_20251209_135027.png)
![Rendered map](images/map_20251209_135103.png)
![Rendered map](images/map_20251209_135140.png)
![Rendered map](images/map_20251209_135158.png)
![Rendered map](images/map_20251209_135225.png)
![Rendered map](images/map_20251209_135245.png)
![Rendered map](images/map_20251209_135302.png)
![Rendered map](images/map_20251209_135321.png)
![Rendered map](images/map_20251207_144206.png)
![Rendered map](images/map_20251207_150909.png)
