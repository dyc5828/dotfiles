# Naming: Microservice Early Warning / Degradation Detection Tool

## 1. Core Function

This tool doesn't just "monitor" - monitoring implies passive observation and dashboards. What this tool fundamentally does is **sense subtle shifts in a complex system before those shifts become failures**. It correlates multiple weak signals - latency creeping up, error rates ticking, dependency chains straining - and recognizes that the system is sliding toward collapse while everything still looks "green" on a status page.

The underlying mechanism is early detection through sensitivity to vibration, pressure, or tremor in an interconnected structure. It feels the ground shifting before the quake.

## 2. Metaphor Search

Domains worth exploring:

- **Seismology / geology** - detecting tremors, foreshocks, ground shifts before the main event
- **Medicine / physiology** - triage, prodromal symptoms, vital signs that indicate decline before crisis
- **Structural engineering** - stress fractures, load strain, hairline cracks in a structure under pressure
- **Weather / atmosphere** - pressure drops, wind shifts, barometric changes that precede storms
- **Animal senses** - creatures that sense environmental changes before humans can (canaries, dogs before earthquakes)
- **Navigation / maritime** - reading swells, undertow, current changes that signal coming danger
- **Metallurgy** - metal fatigue, stress testing, the creaking before a beam gives way

The strongest metaphor families here are seismic sensing (feeling faint vibrations that precede a larger event) and structural stress detection (noticing the hairline crack or the groan in a load-bearing element).

## 3. Candidate Names

1. **Tremor** - a small seismic vibration that precedes the earthquake. Implies detecting the faint early signal in a system that is about to break.
2. **Canary** - the canary in the coal mine. Reacts to danger before anyone else notices. Immediate, universally understood metaphor for early warning.
3. **Seam** - the line along which something splits apart under stress. Where services meet is where failure begins. Implies watching the joints.
4. **Ripple** - the first visible disturbance spreading outward from a point of impact. Implies catching the effect while it's still small and propagating.
5. **Strain** - the physical deformation of a material under load, measurable before it fractures. Implies sensing the system bending before it breaks.
6. **Swell** - the deep ocean wave that arrives before the storm. Detectable, directional, a reliable precursor signal.
7. **Filament** - the thinnest wire in a circuit, the first thing to heat up and glow when current surges. Implies the most sensitive point in an interconnected system.

## 4. Strongest Candidates

**Tremor** is the standout. It maps almost perfectly to the function: small, measurable vibrations that precede a catastrophic event. The word is short, concrete, tactile - you can feel a tremor. It immediately communicates "early warning of something bigger coming." In the context of microservices, a latency spike or error rate tick is literally a tremor running through the system. It's also calm and professional, not whimsical. Easy to say in conversation: "Tremor flagged the payments service."

**Canary** is the most instantly legible option. Everyone knows what a canary in a coal mine does - it dies first so the miners know to get out. The metaphor is so embedded in engineering culture that "canary deployment" is already standard vocabulary. That familiarity is both a strength (zero explanation needed) and a mild weakness (it's well-worn, and "canary" already has an adjacent meaning in deployment tooling that could cause confusion).

**Strain** deserves consideration for its precision. It's the engineering term for measurable deformation under load - exactly what this tool detects. Latency increasing is the system under strain. Error rates climbing is the material deforming. The word is clean, one syllable, and implies something quantifiable happening right now that predicts what happens next. "Strain detected elevated load on the auth service" reads naturally.
