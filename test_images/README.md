# Test Images — Local Monument Recognition

These images are for testing the **offline** monument scanner. No internet,
API key, or Google Cloud billing is required — recognition runs on-device.

## How to test

1. Run the app: `flutter run`
2. Open the **Heritage Scanner** screen.
3. Tap the **gallery / photo-library icon** (top-right) and pick one of the
   images below — OR transfer them to your phone and point the camera at them
   on another screen.

| File | Should detect as | Opens |
|------|------------------|-------|
| `TEST_sphinx_1.jpg` | The Great Sphinx | Sphinx AR experience |
| `TEST_sphinx_2.jpg` | The Great Sphinx | Sphinx AR experience |
| `TEST_khafre_pyramid_1.jpg` | Pyramid of Khafre | Khafre Pyramid AR experience |
| `TEST_khafre_pyramid_2.jpg` | Pyramid of Khafre | Khafre Pyramid AR experience |

## Notes

- The recognizer currently supports **two monuments**: the **Great Sphinx**
  and the **Pyramid of Khafre**. Any other image returns an honest
  "No monument recognised" message instead of a wrong guess.
- It works best with clear, front-on shots similar to these. Photos that show
  *both* the Sphinx and the pyramid together are intentionally ambiguous.
- Reference photos live in `assets/monuments/` (`sphinx*.jpg`,
  `khafre_pyramid*.jpg`); any of those will also be recognized.
