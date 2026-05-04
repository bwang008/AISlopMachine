# Agent Log & Technical Gotchas

## Godot 4 Image Import Issues with AI Generation
**Issue**: When using the `generate_image` tool, the output file might end up with a `.png` file extension but actually contain WebP or corrupted header data. When imported into Godot 4, the engine throws the following error:
```
WARNING: drivers/png/png_driver_common.cpp:56 - Not a PNG file
ERROR: drivers/png/png_driver_common.cpp:69 - Condition "!success" is true. Returning: ERR_FILE_CORRUPT
```

**Solution**: Do not rely on basic shell `Copy-Item` or `cp` commands when bringing AI-generated images into Godot's `res://` directory. Instead, run the image through Python's Pillow (PIL) library to explicitly encode and save it as a true PNG.

**Example Fix Script**:
```python
python -c "from PIL import Image; img = Image.open('source.png'); img.save('destination.png', 'PNG')"
```
