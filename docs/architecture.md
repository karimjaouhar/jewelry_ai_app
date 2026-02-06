# Architecture & Technical Specification — Jewelry AI App (Private)

## Purpose
A private Android app (Samsung-first) for generating photorealistic marketing images of models wearing real jewelry from a user-uploaded product photo. The app wraps a generative image API (Nano Banana Pro) and enforces consistent prompt templates + constraints so non-technical users get repeatable results.

## Goals
- Minimal user typing: structured UI → deterministic prompt construction.
- High jewelry fidelity: preserve design, proportions, metal tone, stones; no hallucinated additions.
- Support single and multi-piece compositions (e.g., 3 bracelets stacked).
- Fast, simple workflow and “history” to reuse successful settings.
- Private distribution (APK), not published publicly.

## Non-goals (v1)
- Advanced manual editing tools (masking, compositing, retouching).

---

## Target Platforms
- Android (primary). iOS optional later.
- Flutter stable channel.

## Tech Stack
- Flutter (Material 3).
- State management: Riverpod (preferred) OR Provider (acceptable). Keep it simple.
- HTTP: `http` package or `dio` (choose one; default to `dio` for interceptors/logging).
- Image selection: `image_picker`.
- Local persistence:
  - Secure storage for API key: `flutter_secure_storage`.
  - History metadata storage: `shared_preferences` (v1) or `hive` (v1.1+).
- File storage: `path_provider` to store generated images locally.

## External Services
- Image generation API: Gemini Nano Banana Pro (via API key).
- Optional (later): Upscale/enhance layer (separate API/service or same provider).

---

## Core User Flow (v1)
1. Upload jewelry photo (camera or gallery).
2. Select jewelry type: Necklace / Earrings / Ring / Bracelet / Anklet / Other.
3. Single vs multiple pieces (quantity if multiple).
4. Choose model profile presets:
   - Gender presentation: woman/man/neutral
   - Skin tone: light/medium/deep
   - Optional: hair style preset (useful for earrings/necklaces)
5. Setting:
   - Studio (default)
   - Lifestyle (beach/street/café/evening)
6. Composition:
   - Close-up (default)
   - Mid shot
7. Generate 2–4 variations.
8. Save/share + history entry (inputs + output thumbnails).

---

## Prompt Engineering Approach
Prompting must be generated from structured inputs (no user prompt required).
Key rules:
- Fidelity constraints are mandatory:
  - “Keep the jewelry identical to the reference image: same shape, stones, metal tone, proportions; do not redesign.”
  - “Do not add extra jewelry or decorations.”
- Placement rules depend on jewelry type (necklace drape, earrings visibility, ring hand pose, bracelet stacking).
- Photography style rules:
  - Studio: clean background, softbox lighting, shallow depth of field, sharp focus on jewelry.
  - Lifestyle: realistic environment but jewelry remains sharp and dominant.
- Negatives:
  - No text, watermark, logos.
  - Avoid distorted anatomy, extra fingers, melted metal, incorrect symmetry.

Implementation:
- `PromptBuilder.build(request)` returns:
  - `system` instructions (global rules)
  - `user` prompt (specific request)
  - optional “negative” string if API supports it.

---

## Data Model (v1)
### GenerationRequest
- imageFilePath (or bytes)
- jewelryType (enum)
- pieceCount (int)
- modelGender (enum)
- skinTone (enum)
- setting (enum)
- composition (enum)
- variations (int)
- seed (optional; if supported)

### GenerationResult
- requestId
- createdAt
- outputs: list of generated image file paths
- requestSnapshot: GenerationRequest (serialized)

---

## Error Handling & UX
- Validate inputs before generate.
- Show progress state with cancellable UI (if API supports cancellation).
- Handle typical failures:
  - network errors
  - API key invalid
  - API rate limit
  - model returned empty result
- Provide “Try again” and “Regenerate same settings”.

---

## Security & Privacy
- API key stored only in secure storage on device (v1).
- No analytics.
- No remote logging of images.
- All images stored locally unless user shares externally.

---

## Build & Distribution
- Debug builds for development.
- Release APK for private distribution.
- No Play Store publishing.
- Optional app signing for stable install updates.

---

## Implementation Milestones
V1:
- Clean UI shell + routing
- Upload image step
- Config screen for options
- PromptBuilder
- API integration for image generation
- Display results grid + save/share
- History list (simple)

V1.1:
- Upscale pass (optional)
- Better local database (Hive)

