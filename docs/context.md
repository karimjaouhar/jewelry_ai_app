# Context — Jewelry AI App

## What This Is

This project is a **private mobile application** built for a jewelry business to generate **photorealistic marketing images** of models wearing their real jewelry.

The user uploads a photo of a jewelry piece (usually a clean product shot on a white background), selects a few options (jewelry type, number of pieces, model profile, and setting), and the app generates high-quality images of a model wearing that exact jewelry.

The app is **not public**, **not consumer-facing**, and **not a general AI image tool**. It exists to solve a very specific workflow problem for a small jewelry business.

---

## Why This Exists

### The Problem

Using generative image models directly is unreliable for non-technical users:

- Results vary depending on how prompts are written
- Important constraints are often forgotten
- Jewelry is sometimes altered, redesigned, or misrepresented
- Multi-piece requests (e.g. stacked bracelets) fail frequently
- The user must “learn” how to talk to the model to get good results

This makes direct use of AI tools frustrating and inconsistent for everyday business use.

### The Goal

The goal of this app is to:
- Remove prompt-writing entirely from the user experience
- Replace it with a **guided, structured workflow**
- Encode best-practice prompting once, and reuse it every time
- Produce **consistent, realistic, usable images** with minimal effort

The app acts as a **reliable wrapper** around the AI model, not a creative playground.

---

## How It Works (Conceptually)

### User Perspective

From the user’s point of view, the process is simple:

1. Upload a jewelry photo
2. Select what type of jewelry it is
3. Indicate whether there are multiple pieces
4. Choose what kind of model should wear it
5. Choose a studio or lifestyle setting
6. Generate images and save the ones they like

The user never sees or writes a prompt.

---

### System Perspective

Under the hood, the app:

1. Collects structured inputs from the UI
2. Converts those inputs into a **strict, templated prompt**
3. Applies global rules that prioritize:
   - Jewelry fidelity
   - Realistic proportions
   - Professional photography quality
4. Sends the prompt and reference image to the image generation API
5. Displays multiple variations and stores results locally

The “intelligence” of the app lives primarily in:
- Prompt templates
- Category-specific rules (necklace vs earrings vs ring, etc.)
- Strong negative constraints to prevent hallucinations

---

## Design Philosophy

This app is designed with the following principles:

- **Consistency over creativity**  
  Accurate representation of the jewelry is more important than artistic variation.

- **Structure beats flexibility**  
  Limited options with strong defaults produce better results than open-ended input.

- **Private and focused**  
  Built for one business, one workflow, and one clear outcome.

- **Simple UI, strong backend logic**  
  The user experience should feel easy, while the system quietly enforces correctness.

---

## What This App Is Not

To avoid scope creep, it’s important to be clear about what this app is *not*:

- Not a general-purpose AI image generator
- Not a design tool for creating new jewelry
- Not a public SaaS product
- Not a catalog or inventory system
- Not a replacement for professional photoshoots in all cases

It is a **practical tool for producing marketing visuals quickly and reliably**.

---

## Success Definition

This app is successful if:

- A non-technical user can generate a usable image in under one minute
- The generated images closely match the original jewelry
- Results are consistent across repeated use
- The user no longer needs to “figure out how to prompt” the AI

If those conditions are met, the app has achieved its purpose.

