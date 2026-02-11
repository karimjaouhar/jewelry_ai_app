# Architecture & Technical Spec - Jewelry AI App (Private)

## Purpose
Private Android-first Flutter app that generates photorealistic marketing images of models wearing real jewelry from user-provided reference photos. The app wraps a generative image API and enforces strict prompt templates to preserve jewelry fidelity.

## Goals
- Minimal user typing: structured UI -> deterministic prompt construction.
- High fidelity: preserve shape, stones, metal tone, proportions, and details.
- Support multiple reference photos per request.
- Simple history of prior generations with reuse.
- Private distribution (APK), no public release.

## Non-Goals (v1)
- Manual editing tools (masking, retouching).
- Public sharing, authentication, payments, analytics.

## Target Platforms
- Android (primary). iOS optional later.
- Flutter stable channel.

## Tech Stack
- Flutter (Material 3).
- State management: Provider (`ChangeNotifier`).
- HTTP: `dio`.
- Image selection: `image_picker`.
- API key storage: `flutter_secure_storage`.
- History storage: `shared_preferences`.
- File storage: `path_provider` for local image saving.
- Sharing: `share_plus`.

## Core User Flow (Implemented)
1. Upload jewelry photo(s) (camera or gallery).
2. Select jewelry type: Necklace / Earrings / Ring / Bracelet / Anklet / Other.
3. Choose model profile:
   - Gender presentation: woman / man / neutral.
   - Age: teen / 20s / adult / senior.
   - Skin tone: light / tanned / brown / dark.
4. Choose setting:
   - Studio
   - Studio natural (recommended)
   - Lifestyle + preset (beach / street / cafe / evening)
5. Choose composition:
   - Close-up (recommended)
   - Mid shot
   - Lifestyle wide
6. Generate (currently 1 variation per request).
7. View results, share, and reuse from history.

## Prompt Engineering (Implemented)
`PromptBuilder.build(request)` returns:
- System rules (global fidelity constraints)
- User prompt (structured request)
- Negative constraints (e.g., no text, no watermarks, no anatomy errors)

Key rules:
- Preserve jewelry exactly as reference (shape, stones, metal tone, proportions).
- Do not add or remove jewelry.
- Placement rules by jewelry type.
- Style rules based on setting and composition.

## API Integration
- Endpoint: Gemini `gemini-3-pro-image-preview:generateContent`.
- Request uses inline base64 reference images + structured prompt text.
- Response expects inline base64 images.
- Error handling maps to friendly messages (invalid key, rate limit, network, empty result).

## Data Model (Implemented)
### GenerationRequest
- `imageFilePaths` (List<String>)
- `jewelryType` (enum)
- `modelGender` (enum)
- `modelAge` (enum)
- `skinTone` (enum)
- `settingType` (enum)
- `lifestylePreset` (enum, optional)
- `compositionType` (enum)
- `variations` (int, fixed to 1 in UI)
- `seed` (optional)

### GenerationResult
- `imageUrls` (List<String>)
- `seed` (optional)

### HistoryEntry
- `id`, `createdAt`
- `requestSnapshot` (GenerationRequest)
- `outputPaths` (List<String>)

## Project Structure (Current)
```
lib/
  app/ (app.dart, theme.dart, router.dart, theme_controller.dart)
  core/services/ (generation_api_client.dart, secure_storage_service.dart)
  features/
    generate/
      data/ (generation_repository.dart)
      domain/ (enums, models, prompt_builder.dart)
      state/ (generation_flow_controller.dart)
      ui/ (generate_flow_screen.dart, results_screen.dart)
    history/
      data/ (history_store.dart)
      domain/ (history_entry.dart)
      ui/ (history_screen.dart)
    settings/
      ui/ (api_key_screen.dart)
```

## Security & Privacy
- API key stored only in secure storage on device.
- No analytics or remote image logging.
- Images are stored locally and shared only when the user chooses.

## Build & Distribution
- Debug builds for development.
- Release APK for private distribution.
