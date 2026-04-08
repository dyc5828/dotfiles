# Naming: Adaptive Action Sequences ("Smart Macros")

## 1. Core Function

This feature records a sequence of user actions, stores them, and replays them later - but with intelligence. Unlike static macros that blindly repeat fixed steps, these sequences adapt to context changes. If the UI shifted, if data moved, if the environment changed, the replay adjusts.

The fundamental mechanism is not just "recording and playback." It is **learned behavior that re-navigates**. The feature understands the intent behind each step, not just the literal action, so it can find its way even when the terrain changes.

This is closer to muscle memory than to a script. A script breaks when the world changes. Muscle memory adapts - you can catch a ball thrown at a different angle because you learned the pattern, not the coordinates.

## 2. Metaphor Domains

- **Navigation/pathfinding** - something that finds its way through changing terrain
- **Physical grooves and tracks** - a worn path that guides motion but allows variation
- **Weaving/textile** - a pattern that repeats but adapts to the material
- **Musical performance** - a musician who plays from memory but improvises around changes
- **Tool use/trades** - a practiced hand that adjusts technique to the workpiece
- **Water/flow** - a current that finds its path around obstacles
- **Kinetics/motion** - a rehearsed movement that adjusts in real time

## 3. Candidate Names

1. **Groove** - A worn channel that guides repeated motion. Grooves are created by repetition and naturally guide things along the same path, but they are physical - they work with the material, not against it. Implies practiced, reliable repetition with a tactile feel.

2. **Trace** - The path left behind by a previous traversal. A trace is both the record of what happened and a guide for what comes next. It carries a sense of following footsteps while remaining free to adapt.

3. **Stride** - A practiced, repeatable movement pattern. A stride adapts to terrain - you lengthen or shorten it going uphill, adjust on uneven ground. It is learned, rhythmic, and responsive.

4. **Reflex** - An automatic response shaped by experience. Reflexes are fast, adaptive, and context-aware. They fire in response to the situation, not from a fixed script. Has strong kinetic immediacy.

5. **Lathe** - A tool that repeats a shaping motion but produces different results depending on the material and operator intent. Implies precision and controlled repetition.

6. **Shuttle** - In weaving, the shuttle carries thread back and forth through the warp, repeating the same motion but building something adaptive and patterned. Also implies reliable back-and-forth transit.

7. **Rut** - Similar to groove but rawer. A rut is a track worn by repeated passage. Slightly negative connotation in everyday speech ("stuck in a rut"), which may work against it despite the strong physical metaphor.

## 4. Evaluation of Strongest Candidates

**Groove** is the strongest name here. It immediately communicates repeated, practiced motion - "getting into a groove" is a universally understood idiom for hitting a flow of productive repetition. The physical metaphor is exact: a groove is carved by doing the same thing repeatedly, and once established, it guides future motion along the same path. It is short, tactile, warm, and has positive connotations of mastery and flow. It is also highly brandable and unlikely to collide with existing product names in this space.

**Trace** is the runner-up. It captures the "record and follow" aspect cleanly. "Retracing your steps" is a natural description of what this feature does. It feels lighter and more precise than Groove, which may suit a feature that is meant to be subtle rather than prominent. The risk is that Trace already appears in developer tooling contexts - stack traces, distributed tracing - which could create some ambiguity.

**Stride** has a strong kinetic quality and naturally implies adaptation - you adjust your stride to the terrain. It feels active and confident. The main concern is that it leans slightly toward movement/travel rather than the "repeat a sequence" aspect. But for a feature that emphasizes the adaptive, intelligent side of replaying actions, it communicates the right thing.

## 5. Evaluation of the Existing Candidate: "Reel"

**What works about Reel:**
- Short and concrete. You can picture a physical reel.
- It captures the "record and play back" aspect - a film reel stores a sequence and replays it.
- Pleasant to say, easy to spell, brandable.

**What does not work:**
- A reel plays back the same thing every time. It is a fixed recording. The defining feature of this product is that it *adapts* to context changes, but "reel" implies rigid, identical playback. The metaphor actively works against the smartest part of the feature.
- "Reel" has been heavily claimed by social media - Instagram Reels, TikTok-style content. The word now carries strong associations with short-form video content, which creates noise.
- The physical metaphor of a reel is mechanical and passive. Thread on a reel, film on a reel - these are storage mechanisms, not intelligent systems. There is no sense of adaptation or responsiveness in the object.

**Verdict:** Reel is a decent name for a basic macro or recording feature, but it undersells and slightly misrepresents the adaptive intelligence that makes this feature distinctive. The social media association is also a practical concern. You can do better.

## Summary

| Rank | Name | Key Strength |
|------|------|-------------|
| 1 | **Groove** | Practiced repetition that adapts to the material. Warm, tactile, positive. |
| 2 | **Trace** | Record and re-follow. Precise, light, developer-friendly. |
| 3 | **Stride** | Rhythmic motion that adjusts to terrain. Active and confident. |
| 4 | **Reflex** | Automatic, shaped by experience. Strong kinetic feel but slightly clinical. |
| 5 | **Shuttle** | Repeating motion that builds something patterned. Slightly niche. |
| 6 | **Lathe** | Controlled repetition, different results per material. Strong but narrow. |
| 7 | **Rut** | Good physical metaphor undermined by negative everyday connotation. |

**Recommendation:** Go with **Groove**. It captures both the repetition and the adaptiveness, it feels good to say, and it has none of the baggage that Reel carries.
