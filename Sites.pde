class Site {
  float x;
  float y;
  boolean selected = false;

  Site(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void draw(PApplet app) {
    app.pushStyle();

    float r = 6.0f / viewport.zoom;

    if (selected) {
      app.fill(0, 150, 255);
      app.stroke(0);
      app.strokeWeight(2.0f / viewport.zoom);
    } else {
      app.fill(255);
      app.stroke(0);
      app.strokeWeight(1.5f / viewport.zoom);
    }

    app.ellipse(x, y, r, r);

    app.popStyle();
  }
}
