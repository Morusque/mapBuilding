import java.util.HashMap;

HashMap<String, String> TOOLTIP_TEXTS = new HashMap<String, String>();

void initTooltipTexts() {
  TOOLTIP_TEXTS.clear();

  // top modes bar
  TOOLTIP_TEXTS.put("tool_cells", "Work on cells placement.");
  TOOLTIP_TEXTS.put("tool_elevation", "Work on topography.");
  TOOLTIP_TEXTS.put("tool_biomes", "Work on natural regions.");
  TOOLTIP_TEXTS.put("tool_zones", "Work on arbitrary administrative regions.");
  TOOLTIP_TEXTS.put("tool_paths", "Work on routes and rivers.");
  TOOLTIP_TEXTS.put("tool_structures", "Work on constructed elements.");
  TOOLTIP_TEXTS.put("tool_labels", "Work on additional texts.");
  TOOLTIP_TEXTS.put("tool_render", "Work on colors, style, display rules.");
  TOOLTIP_TEXTS.put("tool_export", "Export as a file.");

  // cells mode
  TOOLTIP_TEXTS.put("site_density", "Number of cells to place to seed the world space.");
  TOOLTIP_TEXTS.put("site_fuzz", "Add random jitter to break up the strict grid.");
  TOOLTIP_TEXTS.put("site_mode", "Choose the placement algorithm:\n- grid: simple squares\n- poisson-disc: evenly spaced but organic\n- hexagonal: honeycomb layout.");
  TOOLTIP_TEXTS.put("sites_generate", "Rebuild all site seeds using the chosen parameters.");
  TOOLTIP_TEXTS.put("sites_keep", "Keep properties preserves biomes/zones while regenerating sites.");

  // elevation mode
  TOOLTIP_TEXTS.put("elevation_water_level", "Water level slider raises or lowers the sea plane.");
  TOOLTIP_TEXTS.put("elevation_brush_radius", "Brush radius controls the width of elevation strokes.");
  TOOLTIP_TEXTS.put("elevation_brush_strength", "Brush strength controls how quickly height changes per stroke.");
  TOOLTIP_TEXTS.put("elevation_raise", "Enable raise mode to add altitude.");
  TOOLTIP_TEXTS.put("elevation_lower", "Enable lower mode to cut into the terrain.");
  TOOLTIP_TEXTS.put("elevation_noise", "Noise scale changes the frequency of Perlin generation.");
  TOOLTIP_TEXTS.put("elevation_generate_perlin", "Generate terrain from Perlin noise.");
  TOOLTIP_TEXTS.put("elevation_vary", "Vary applies subtle random offsets to the current elevation.");
  TOOLTIP_TEXTS.put("elevation_plateau", "Make plateaux grows flat plateaus from the selected cells.");

  // biomes mode
  TOOLTIP_TEXTS.put("biome_gen_mode", "Choose generation modes: \n- Propagation: place regions frmo all available biomes \n- Reset: fills entire map with selected biome \n- Fill gaps: replaces regions set to None by extending nearby regions \n- Replace gaps: replaces None reginos by new biomes \n- Fill under: sets cells under value threshold to selected biome \n- Fill above: sets cells above value threshold to selected biome \n- Extend: increases selected biome sizes \n- Shrink: decreases selected biome sizes \n- Spots: adds a spot of selected biome somewhere \n- Vary: move some cells around \n- Beaches : set selected biome region somewhere near coastlines \n- Full : arbitrary multiphase generation process");
  TOOLTIP_TEXTS.put("biome_gen_value", "Value slider depends on chosen generation mode:...");
  TOOLTIP_TEXTS.put("biome_gen_apply", "Execute the selected generation method using the chosen value.");
  TOOLTIP_TEXTS.put("biome_value_water", "Sync the value slider with the current sea level.");
  TOOLTIP_TEXTS.put("biome_paint", "Paint selected biome while dragging with the brush.");
  TOOLTIP_TEXTS.put("biome_fill", "Fill the clicked region with the selected biome type.");
  TOOLTIP_TEXTS.put("biome_add", "Add a new biome swatch (duplicates the current one).");
  TOOLTIP_TEXTS.put("biome_remove", "Remove the selected biome type if it is not locked.");
  TOOLTIP_TEXTS.put("biome_name", "Edit the descriptive name of the active biome.");
  TOOLTIP_TEXTS.put("biome_hue", "Adjust the hue for the active biome type.");
  TOOLTIP_TEXTS.put("biome_brush", "Control how wide your painting brush is.");
  TOOLTIP_TEXTS.put("biome_palette", "Pick a biome swatch to make it active before painting.");

  // zones mode
  TOOLTIP_TEXTS.put("zones_reset", "Reset clears the selected zone assignments.");
  TOOLTIP_TEXTS.put("zones_regenerate", "Regenerate rebuilds zones from their seeds.");
  TOOLTIP_TEXTS.put("zones_brush", "Zone brush radius in world units.");
  TOOLTIP_TEXTS.put("zones_exclude_water", "Exclude water removes water cells from the selected zone.");
  TOOLTIP_TEXTS.put("zones_exclusive", "Make exclusive keeps each cell assigned to a single zone.");
  TOOLTIP_TEXTS.put("zones_four_color", "Attempt to recolor the graph so touching zones use distinct colors.");
  TOOLTIP_TEXTS.put("zones_list_new", "Create a new zone entry.");
  TOOLTIP_TEXTS.put("zones_list_deselect", "Deselect any active zone.");

  // paths mode
  TOOLTIP_TEXTS.put("paths_route_mode", "Route mode: Ends draws straight lines, Pathfind uses terrain-aware routes.");
  TOOLTIP_TEXTS.put("paths_flattest", "Flattest slope bias nudges the pathfinder toward flatter paths.");
  TOOLTIP_TEXTS.put("paths_avoid_water", "Avoid water keeps routes away from rivers and lakes.");
  TOOLTIP_TEXTS.put("paths_eraser", "Eraser mode removes segments while you drag.");
  TOOLTIP_TEXTS.put("paths_list_new", "Create a new path (starts from an empty route).");
  TOOLTIP_TEXTS.put("paths_list_deselect", "Deselect the current path to start fresh.");
  TOOLTIP_TEXTS.put("paths_type_add", "Add another path type palette entry.");
  TOOLTIP_TEXTS.put("paths_type_remove", "Remove the selected path type (existing paths keep their style).");
  TOOLTIP_TEXTS.put("paths_palette", "Select a path type swatch before drawing.");
  TOOLTIP_TEXTS.put("paths_type_name", "Edit the name of the active path type.");
  TOOLTIP_TEXTS.put("paths_type_hue", "Set the hue for the active path type.");
  TOOLTIP_TEXTS.put("paths_type_weight", "Set the drawn stroke width for the active path type.");
  TOOLTIP_TEXTS.put("paths_min_weight", "Clamp how thin the tapered path can become.");
  TOOLTIP_TEXTS.put("paths_taper", "Enable tapering so each stroke starts thin and finishes thick.");

  // structures mode
  TOOLTIP_TEXTS.put("snap_water", "Snap edits to the coastline/water mask so the cursor jumps to shores.");
  TOOLTIP_TEXTS.put("snap_biomes", "Snap brushing to biome outlines for precise overlays.");
  TOOLTIP_TEXTS.put("snap_underwater_biomes", "Snap underwater operations to the submerged biomes.");
  TOOLTIP_TEXTS.put("snap_zones", "Snap to zone outlines when editing while in zone mode.");
  TOOLTIP_TEXTS.put("snap_paths", "Snap to existing path nodes for neat road placement.");
  TOOLTIP_TEXTS.put("snap_structures", "Snap to the structure grid to align new builds.");
  TOOLTIP_TEXTS.put("snap_elevation", "Snap to the elevation grid defined by the divisions slider.");
  TOOLTIP_TEXTS.put("snap_elevation_divisions", "Elevation divisions controls the number of horizontal grid lines for snapping.");
  TOOLTIP_TEXTS.put("structures_size", "Structure size adjusts the bounding box of each new element.");
  TOOLTIP_TEXTS.put("structures_angle", "Angle offset rotates each placed structure.");
  TOOLTIP_TEXTS.put("structures_ratio", "Rectangle ratio is width / height for rectangular shapes.");
  TOOLTIP_TEXTS.put("structures_shape", "Pick the shape of the next placed structure.");
  TOOLTIP_TEXTS.put("structures_snap_mode", "Snap mode defines how structures adhere to existing grids or next edges.");
  TOOLTIP_TEXTS.put("structures_deselect", "Deselect the currently highlighted structure.");
  TOOLTIP_TEXTS.put("structures_detail_name", "Rename the selected structure.");
  TOOLTIP_TEXTS.put("structures_detail_size", "Fine-tune the selected structure's size.");
  TOOLTIP_TEXTS.put("structures_detail_angle", "Fine-tune the selected structure's angle.");
  TOOLTIP_TEXTS.put("structures_detail_hue", "Adjust the hue of the selected structure.");
  TOOLTIP_TEXTS.put("structures_detail_alpha", "Adjust the transparency of the selected structure.");
  TOOLTIP_TEXTS.put("structures_detail_sat", "Adjust the saturation of the selected structure.");
  TOOLTIP_TEXTS.put("structures_detail_stroke", "Adjust the stroke weight of the selected structure's outlines.");

  // labels mode
  TOOLTIP_TEXTS.put("labels_deselect", "Deselect the currently edited label.");
  TOOLTIP_TEXTS.put("labels_size", "Label size slider controls the default text height.");

  // rendering mode
  TOOLTIP_TEXTS.put("render_contours", "Contour sliders change spacing and alpha; heavy settings may trigger the loading bar.");
  TOOLTIP_TEXTS.put("render_labels_arbitrary", "Show arbitrary labels when checked; outlines and outline alpha are disabled for now.");
  TOOLTIP_TEXTS.put("render_preset", "Drag the slider to pick a preset and hit Apply to swap render colors/contours.");

  // export mode
  TOOLTIP_TEXTS.put("export_png", "Export the current view as a PNG.");
  TOOLTIP_TEXTS.put("export_scale", "Resolution scale multiplies the output raster size.");
}

String tooltipFor(String key) {
  if (key == null) return null;
  if (key.equals("biome_gen_value")) return tooltipForBiomeValue();
  return TOOLTIP_TEXTS.get(key);
}

String tooltipForBiomeValue() {
  int idx = constrain(biomeGenerateModeIndex, 0, biomeGenerateModes.length - 1);
  switch (idx) {
    case 0: return "Propagation: slider controls how aggressively the active biome expands from seeds.";
    case 1: return "Reset: slider sets how much the biome clears others (low = polite, high = full override).";
    case 2: return "Fill gaps: higher values push the biome into empty cells.";
    case 3: return "Replace gaps: fills empty zones from scratch before expanding.";
    case 4: return "Fill under: positive values push the biome below the sea level.";
    case 5: return "Fill above: positive values push the biome to higher ground.";
    case 6: return "Extend: slider controls how much the biome grows outward.";
    case 7: return "Shrink: slider controls how much the biome retracts from edges.";
    case 8: return "Spots: slider determines spot size and strength.";
    case 9: return "Vary: slider adjusts randomness to produce different variations.";
    case 10: return "Beaches: slider maps to beach width (scaled later to 1-100).";
    case 11: return "Full: slider mixes the selected biome over the entire map.";
  }
  return "Value slider is 0..1; see the generation mode for context.";
}
