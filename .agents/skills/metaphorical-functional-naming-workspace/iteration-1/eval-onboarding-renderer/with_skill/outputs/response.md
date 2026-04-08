# Naming: Onboarding Flow Renderer (Write-Once, Render-Everywhere)

## Core Function

This system takes a single onboarding flow definition and generates platform-specific implementations for web, iOS, Android, and email. The fundamental mechanism is not "onboarding" or "rendering" - it is a one-to-many transformation. A single source of truth enters and multiple distinct, platform-native outputs emerge. The definition is authored once; the system handles the work of producing each platform's specific form.

## Metaphor Exploration

The one-in-many-out mechanism maps to several physical-world domains:

- **Optics** - a prism refracts a single beam into a spectrum of distinct wavelengths
- **Weaving** - a loom takes a pattern definition and produces material output thread by thread
- **Printing** - a plate holds one composition and presses it onto different surfaces
- **Metalwork** - a mold stamps a single design into different materials
- **Craft** - a stencil applies one cutout pattern across different surfaces
- **Ceramics** - a kiln transforms raw material into finished, hardened pieces
- **Textile mechanics** - a shuttle carries the same thread across different warp structures

## Candidate Names

1. **Prism** - A single beam of light enters a prism and refracts into a full spectrum of distinct colors. One input, many outputs - each one different but all originating from the same source. Maps directly to one definition producing web, iOS, Android, and email implementations.

2. **Loom** - A loom takes a defined pattern and weaves it into fabric. The pattern is authored once; the loom handles the mechanics of producing the output. Implies systematic, reliable rendering of a design into material form across different threads and structures.

3. **Mold** - A single shape definition that gets pressed into different materials. The shape stays constant; the material adapts. Implies write-once fidelity - one master form, many resulting artifacts.

4. **Stencil** - A cutout pattern applied across different surfaces. The stencil is the source of truth; each surface receives the same design adapted to its medium. Straightforward and tactile.

5. **Kiln** - Raw material enters, finished pieces come out. Implies transformation and hardening - taking a soft definition and firing it into durable, platform-specific artifacts. Emphasizes the transformation step.

6. **Shuttle** - The part of a loom that carries thread back and forth across the warp. Implies the mechanism that moves content across platforms, threading the same material through different structures.

7. **Plate** - A printing plate holds a single composition and transfers it onto different surfaces. One master, many prints. Implies faithful reproduction across different media.

## Evaluation of Strongest Candidates

### Prism - strongest fit

Prism maps almost exactly to what this system does. White light is a single unified input. The prism refracts it into distinct wavelengths - not copies, but different manifestations of the same source. This mirrors how one onboarding definition becomes distinct web, iOS, Android, and email implementations. Each output is native to its platform, not a carbon copy. The name is short, concrete, immediately legible, and implies the right mechanism without describing the category. It also carries a connotation of clarity and precision. Highly brandable.

### Loom - strong alternative

Loom implies the systematic, mechanical weaving of a defined pattern into a finished product. It captures the "rendering" side of the system well - the work of taking an abstract pattern and producing tangible output. It is warm, physical, and evocative. The slight weakness is that it implies a single output rather than multiple distinct outputs. It also has some namespace collision with the screen recording product Loom, which could cause confusion depending on context.

### Stencil - solid option

Stencil is clean and immediately understood. One pattern, many surfaces. It implies fidelity to the original design while adapting to different materials. It is perhaps more literal than the others - less evocative, more workmanlike - but that can be a strength. The name is calm, durable, and easy to say. The main downside is that "stencil" can imply simplicity or roughness, which may undersell a sophisticated rendering system.

## Recommendation

**Prism** is the strongest name. It captures the exact mechanism - one input refracting into multiple distinct outputs - and does so with a word that feels precise, clean, and durable. It works equally well in conversation, documentation, and code.
