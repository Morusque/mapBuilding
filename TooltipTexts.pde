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
  TOOLTIP_TEXTS.put("site_fuzz", "Add random jitter to the placement.");
  TOOLTIP_TEXTS.put("site_mode", "Choose the placement algorithm:\n- grid: simple squares\n- poisson-disc: evenly spaced but organic\n- hexagonal: honeycomb layout.");
  TOOLTIP_TEXTS.put("sites_generate", "Rebuild all site seeds using the chosen parameters.");
  TOOLTIP_TEXTS.put("sites_keep", "Keep properties preserves properties such as biome assignement while regenerating cells.");
  TOOLTIP_TEXTS.put("sites_reset_all", "Clear all data: cells, zones, biomes, paths, structures, labels.");

  // elevation mode
  TOOLTIP_TEXTS.put("elevation_water_level", "Sets sea level.");
  TOOLTIP_TEXTS.put("elevation_brush_radius", "Brush radius.");
  TOOLTIP_TEXTS.put("elevation_brush_strength", "Brush strength.");
  TOOLTIP_TEXTS.put("elevation_raise", "Brush adds altitude. \nWill normalize emerged lands if maximum is exeeded.");
  TOOLTIP_TEXTS.put("elevation_lower", "Brush lowers altitude.  \nWill normalize submerged lands if minimum is exeeded.");
  TOOLTIP_TEXTS.put("elevation_noise", "Change frequency of Perlin noise when using Generate or Vary. \nHigh values = more details.");
  TOOLTIP_TEXTS.put("elevation_generate_perlin", "Generate terrain from Perlin noise.");
  TOOLTIP_TEXTS.put("elevation_vary", "Apply subtle random offsets to the current elevation.");
  TOOLTIP_TEXTS.put("elevation_plateau", "Create random flatter areas on the current elevation set.");

  // biomes mode
  TOOLTIP_TEXTS.put("biome_gen_mode", "Choose generation modes: \n- Propagation: expand seeds from every biome using a set of rules \n- Reset: fills entire map with selected biome \n- Fill gaps: replaces regions set to None by extending nearby regions \n- Replace gaps: replaces None reginos by new biomes \n- Fill under: sets cells under value threshold to selected biome \n- Fill above: sets cells above value threshold to selected biome \n- Extend: increases selected biome sizes \n- Shrink: decreases selected biome sizes \n- Spots: adds a spot of selected biome somewhere \n- Vary: move some cells around \n- Beaches : set selected biome region somewhere near coastlines \n- Full : arbitrary multiphase generation process");
  TOOLTIP_TEXTS.put("biome_gen_apply", "Execute the selected generation method using the chosen value.");
  TOOLTIP_TEXTS.put("biome_value_water", "Sync the value slider with the current sea level.");
  TOOLTIP_TEXTS.put("biome_paint", "Paint selected biome while dragging with the brush.");
  TOOLTIP_TEXTS.put("biome_fill", "Fill the clicked region with the selected biome type.");
  TOOLTIP_TEXTS.put("biome_add", "Add a new biome type.");
  TOOLTIP_TEXTS.put("biome_remove", "Remove the selected biome type.");
  TOOLTIP_TEXTS.put("biome_name", "Edit biome name.");
  TOOLTIP_TEXTS.put("biome_hue", "Adjust hue for selected biome type.");
  TOOLTIP_TEXTS.put("biome_brush", "Brush radius.");
  TOOLTIP_TEXTS.put("biome_palette", "Select this biome type.");

  // zones mode
  TOOLTIP_TEXTS.put("zones_reset", "Remove all zones.");
  TOOLTIP_TEXTS.put("zones_regenerate", "Generated a new arrangement of zones.");
  TOOLTIP_TEXTS.put("zones_brush", "Brush radius.");
  TOOLTIP_TEXTS.put("zones_exclude_water", "Exclude water from the selected zone. \nExclude from all zones if no zone selected.");
  TOOLTIP_TEXTS.put("zones_exclusive", "Prevent any zone to overlap selected one. \nKeep each cell assigned to a single zone if no zone selected.");
  TOOLTIP_TEXTS.put("zones_four_color", "Attempt to recolor the graph so touching zones use four distinct colors. \nMight not succeed in overlapping scenarios.");
  TOOLTIP_TEXTS.put("zones_list_new", "Create a new zone entry.");
  TOOLTIP_TEXTS.put("zones_list_deselect", "Deselect any active zone.");

  // paths mode
  TOOLTIP_TEXTS.put("paths_route_mode", "Route mode: \n- Ends : straight lines \n- Pathfind : terrain-aware routes");
  TOOLTIP_TEXTS.put("paths_flattest", "Set how much to prefer flat routes over slopes when pathfinding.");
  TOOLTIP_TEXTS.put("paths_avoid_water", "Avoid going through seas when pathfinding.");
  TOOLTIP_TEXTS.put("paths_eraser", "Remove segments by dragging the brush.");
  TOOLTIP_TEXTS.put("paths_list_new", "Create a new path using selected path type.");
  TOOLTIP_TEXTS.put("paths_list_deselect", "Deselect any path.");
  TOOLTIP_TEXTS.put("render_paths_bri", "Scale path brightness for rendering/export.");
  TOOLTIP_TEXTS.put("paths_type_add", "Add another path type palette entry.");
  TOOLTIP_TEXTS.put("paths_type_remove", "Remove the selected path type. \nExisting paths keep their parameters.");
  TOOLTIP_TEXTS.put("paths_palette", "Select a path type preset.");
  TOOLTIP_TEXTS.put("paths_type_name", "Edit name of active path type.");
  TOOLTIP_TEXTS.put("paths_type_hue", "Set hue for the active path type.");
  TOOLTIP_TEXTS.put("paths_type_weight", "Set stroke width for active path type.");
  TOOLTIP_TEXTS.put("paths_min_weight", "Clamp how thin the tapered path can become.");
  TOOLTIP_TEXTS.put("paths_taper", "End of path touching the sea will appear with a bigger stroke width than the other end.");
  TOOLTIP_TEXTS.put("paths_generate", "Auto-generate rivers, roads, and bridges.");

  // structures mode
  TOOLTIP_TEXTS.put("snap_water", "Snap to sea when placing new structures.");
  TOOLTIP_TEXTS.put("snap_biomes", "Snap to frontiers bewteen biomes when placing new structures.");
  TOOLTIP_TEXTS.put("snap_underwater_biomes", "Snap to underwater biomes when placing new structures.");
  TOOLTIP_TEXTS.put("snap_zones", "Snap to zone lines when placing new structures.");
  TOOLTIP_TEXTS.put("snap_paths", "Snap to paths when placing new structures.");
  TOOLTIP_TEXTS.put("snap_structures", "Snap to other structures when placing new structures.");
  TOOLTIP_TEXTS.put("snap_elevation", "Snap to the elevation contours defined by the divisions slider.");
  TOOLTIP_TEXTS.put("snap_elevation_divisions", "Number of elevation grid lines for snapping.");
  TOOLTIP_TEXTS.put("structures_size", "Structure size of upcoming structures.");
  TOOLTIP_TEXTS.put("structures_angle", "Angle offset for placed structure.");
  TOOLTIP_TEXTS.put("structures_ratio", "Ratio bewteen vertical and horizontal dimensions, when applicable.");
  TOOLTIP_TEXTS.put("structures_shape", "Shape of upcoming structures.");
  TOOLTIP_TEXTS.put("structures_snap_mode", "Define how structures are snapped: \n- none : no snapping \n- next : like houses next to a road \n- center : right in the middle of snapping guide");
  TOOLTIP_TEXTS.put("structures_deselect", "Deselect any selected structure.");
  TOOLTIP_TEXTS.put("structures_detail_name", "Click to rename selected structure.");
  TOOLTIP_TEXTS.put("structures_detail_size", "Selected structure's size.");
  TOOLTIP_TEXTS.put("structures_detail_angle", "Selected structure's angle.");
  TOOLTIP_TEXTS.put("structures_detail_hue", "Selected structure hue.");
  TOOLTIP_TEXTS.put("structures_detail_alpha", "Selected structure transparency.");
  TOOLTIP_TEXTS.put("structures_detail_sat", "Selected structure saturation.");
  TOOLTIP_TEXTS.put("structures_detail_stroke", "Selected structure's outlines width.");

  // labels mode
  TOOLTIP_TEXTS.put("labels_deselect", "Deselect currently edited label.");
  TOOLTIP_TEXTS.put("labels_size", "Text height.");

  // rendering mode
  TOOLTIP_TEXTS.put("render_preset", "Drag the slider to pick a preset and hit Apply to swap render.");

  // export mode
  TOOLTIP_TEXTS.put("export_png", "Export the current view as a PNG.");
  TOOLTIP_TEXTS.put("export_scale", "Multiply the output raster size. \nSome elements such as outlines are resolution agnostic.");
  TOOLTIP_TEXTS.put("export_map_json", "Export full map data to JSON (exports/map_latest.json).");
  TOOLTIP_TEXTS.put("import_map_json", "Import map data from exports/map_latest.json.");
  TOOLTIP_TEXTS.put("export_svg", "Export a simplified layered SVG (background, borders, paths, structures, labels, legend).");
  TOOLTIP_TEXTS.put("export_geojson", "Export map features (zones, paths, structures, labels) as GeoJSON FeatureCollection.");
  
}

String tooltipFor(String key) {
  if (key == null) return null;
  if (key.equals("biome_gen_value")) return tooltipForBiomeValue();
  return TOOLTIP_TEXTS.get(key);
}

String tooltipForBiomeValue() {
  int idx = constrain(biomeGenerateModeIndex, 0, biomeGenerateModes.length - 1);
  switch (idx) {
    case 0: return "Propagation: number of starting seeds (from few to many).";
    case 1: return "Reset: (no use).";
    case 2: return "Fill gaps: (no use).";
    case 3: return "Replace gaps: number of seeds scaled to empty area.";
    case 4: return "Fill under: sets elevation threshold.";
    case 5: return "Fill above: sets elevation threshold.";
    case 6: return "Extend: how many outward growth passes.";
    case 7: return "Shrink: how many erosion passes.";
    case 8: return "Spots: number of spots to paint.";
    case 9: return "Vary: strength/iterations of variation.";
    case 10: return "Slice spot: thickness around the chosen elevation (value slider).";
    case 11: return "Full: (no use).";
  }
  return "Value slider meaning depends on chosen generation mode.";
}
