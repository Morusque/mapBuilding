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

    // Light fill, slightly tinted to see cell structure
    app.fill(235);
    app.stroke(180);
    app.strokeWeight(1.0f / viewport.zoom);

    app.beginShape();
    for (PVector v : vertices) {
      app.vertex(v.x, v.y);
    }
    app.endShape(CLOSE);

    app.popStyle();
  }
}
