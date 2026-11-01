# RFL Project Format — draft v1

The shared format must be versioned and forward-compatible.

```json
{
  "format": "rfl-project",
  "version": 1,
  "document": {"width": 2480, "height": 3508, "dpi": 300, "unit": "px"},
  "layers": [
    {"id": "layer-1", "name": "Desenho", "type": "raster", "visible": true, "opacity": 1.0, "blend_mode": "normal", "asset": "assets/layer-1.png"}
  ]
}
```

The current Android prototype only reads the basic layer name/visibility/opacity fields and writes a preliminary JSON file. This draft is not yet a complete interchange contract with the Windows app. Do not overwrite existing `.rfl` projects using this draft.
