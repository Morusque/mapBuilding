class Cell {
  int siteIndex;
  ArrayList<PVector> vertices;
  int biomeId;  // index in mapModel.biomeTypes

  Cell(int siteIndex, ArrayList<PVector> vertices, int biomeId) {
    this.siteIndex = siteIndex;
    this.vertices = vertices;
    this.biomeId = biomeId;
  }

  void draw(PApplet app) {
    if (vertices == null || vertices.size() < 3) return;

    app.pushStyle();

    int col = color(230); // default light grey
    if (mapModel != null && mapModel.biomeTypes != null &&
        biomeId >= 0 && biomeId < mapModel.biomeTypes.size()) {
      ZoneType zt = mapModel.biomeTypes.get(biomeId);
      col = zt.col;
    }

    app.fill(col);
    app.stroke(180);
    app.strokeWeight(1.0f / viewport.zoom);

    app.beginShape();
    for (int i = 0; i < vertices.size(); i++) {
      PVector v = vertices.get(i);
      app.vertex(v.x, v.y);
    }
    app.endShape(CLOSE);

    app.popStyle();
  }
}
