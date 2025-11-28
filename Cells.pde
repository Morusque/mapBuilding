class Cell {
  int siteIndex;
  ArrayList<PVector> vertices;

  Cell(int siteIndex, ArrayList<PVector> vertices) {
    this.siteIndex = siteIndex;
    this.vertices = vertices;
  }

  void draw(PApplet app) {
    if (vertices == null || vertices.size() < 3) return;

    app.pushStyle();
    app.fill(230);
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
