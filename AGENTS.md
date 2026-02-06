# AGENTS.md — Codex Instructions (Jewelry AI App)

You are an AI coding agent working inside a Flutter project. Follow these rules strictly.

## High-Level Context
This is a private Android app for a jewelry business. It generates photorealistic images of models wearing jewelry from a reference product photo. The key requirement is CONSISTENCY and FIDELITY to the jewelry (no redesigning/hallucinating).

The app uses a structured flow (upload → type → piece count → model profile → setting → composition → generate). Prompting must be templated and generated from user selections. Users should not need to write prompts.

## Primary Constraints
1. Do NOT create overly complex architecture. Prefer simple, readable code.
2. Keep the UI minimal and clean. Material 3, white backgrounds, ecommerce feel.
3. Preserve jewelry fidelity:
   - prompts must include strong constraints to keep jewelry identical to reference.
4. Do not hardcode secrets:
   - API key must be read from secure storage (`flutter_secure_storage`) or entered by user.
5. Android-first. Avoid iOS-only changes unless necessary.
6. Prefer deterministic, testable functions (PromptBuilder should be unit-testable).

## Coding Standards
- Dart style: effective_dart.
- Separate UI / state / data logic.
- Prefer Riverpod (if already introduced). If not yet introduced, use Provider or ValueNotifier to keep MVP fast.
- Avoid massive widget build methods—extract widgets.
- Add small comments only where necessary.
- Provide meaningful error messages.

## Project Structure Expectations
Use (or create) this structure:

lib/
  app/ (app.dart, theme, routing)
  features/generate/ (ui, state, domain, data)
  core/ (services, widgets, utils)

Do not dump everything into main.dart.

## Development Approach (Order of Work)
1. Create baseline routing + theme.
2. Implement "Step 1 Upload" screen with image_picker.
3. Add configuration UI (dropdowns/chips) for jewelry type, count, model, setting, composition.
4. Implement domain models: GenerationRequest/Result.
5. Implement PromptBuilder with category-specific rules.
6. Implement API client and integrate generation call.
7. Build results grid, save/share, and history.
8. Add basic tests for PromptBuilder.

## PromptBuilder Requirements
PromptBuilder must:
- Accept a `GenerationRequest`.
- Emit a structured prompt:
  - global fidelity rules
  - category placement rules
  - photography style rules
  - composition rules (close-up emphasis)
  - negative constraints
Keep prompts concise but strict.

Do not allow user free-form prompting in v1.

## What to Do When Unsure
- Make a reasonable default:
  - Studio + close-up defaults.
  - 2 variations default.
  - Neutral safe negative constraints.
- Prefer shipping MVP behavior over adding options.
- Document assumptions in code comments or docs.

## Deliverables When You Add Features
Whenever you implement a new feature:
- Update relevant files cleanly (no dead code).
- Ensure app runs (`flutter run`) without analyzer errors.
- Keep dependencies minimal and documented (pubspec.yaml).
- Provide a short note in your response about what changed and where.

## Forbidden
- Do not add backend servers, authentication, or payments in v1.
- Do not add analytics SDKs.
- Do not create a public release workflow.

