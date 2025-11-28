class Viewport {
  float centerX = 0.5;
  float centerY = 0.5;
  float zoom = 800.0;

  void applyTransform(PApplet app) {
    app.translate(app.width * 0.5f, app.height * 0.5f);
    app.scale(zoom);
    app.translate(-centerX, -centerY);
  }

  void panScreen(float dx, float dy) {
    float wx = -dx / zoom;
    float wy = -dy / zoom;
    centerX += wx;
    centerY += wy;
  }

  void zoomAt(float factor, float sx, float sy) {
    PVector before = screenToWorld(sx, sy);
    zoom *= factor;
    PVector after = screenToWorld(sx, sy);
    centerX += (before.x - after.x);
    centerY += (before.y - after.y);
  }

  PVector screenToWorld(float sx, float sy) {
    float wx = (sx - width * 0.5f) / zoom + centerX;
    float wy = (sy - height * 0.5f) / zoom + centerY;
    return new PVector(wx, wy);
  }

  PVector worldToScreen(float wx, float wy) {
    float sx = (wx - centerX) * zoom + width * 0.5f;
    float sy = (wy - centerY) * zoom + height * 0.5f;
    return new PVector(sx, wy);
  }
}
