# Naming: Early Warning Microservice Monitoring Tool

## Core Function

This tool doesn't just "monitor" services. At its core, it **detects degradation before failure** by reading weak signals across a distributed system. It correlates multiple ambient indicators - latency creep, rising error rates, shifting dependency behavior - and synthesizes them into an early warning. The fundamental mechanism is sensing subtle environmental changes that precede a larger event.

## Metaphor Exploration

Several metaphor domains fit here:

- **Seismology / geology.** Seismographs detect tremors that precede earthquakes. The tool is reading vibrations in the system before something cracks.
- **Weather / atmosphere.** Barometers detect pressure drops before storms arrive. The tool is reading atmospheric pressure across the service mesh.
- **Mining / underground safety.** Canaries in coal mines detected toxic gas before it reached lethal levels. The tool is the canary - sensing poison in the environment before anyone notices.
- **Navigation / maritime.** Sonar detects obstacles beneath the surface before a ship hits them. The tool is pinging the depths and reading what comes back.
- **Medicine / physiology.** A physician reads a constellation of vital signs - pulse, temperature, respiration - to catch illness early. The tool is performing triage across services.
- **Forestry / fire detection.** Watchtowers scan for the first wisps of smoke before a fire spreads. The tool is the lookout.

## Candidate Names

1. **Tremor** - A seismic tremor is a small vibration that precedes a quake. The tool detects tremors in your service graph before something breaks. Short, physical, immediately evocative of early warning.

2. **Canary** - The classic metaphor for early danger detection. A canary in the coal mine reacts to toxic conditions before humans do. Widely understood, directly maps to the function.

3. **Barometer** - Measures atmospheric pressure to predict weather changes. The tool reads system pressure - latency, error rates - to predict service failure. Implies measurement and forecasting without implying crisis.

4. **Seam** - In geology, a seam is a thin layer where materials meet and where fractures tend to originate. The tool watches the seams between services - the dependency boundaries where failures first show stress.

5. **Tremor** and **Canary** occupy the "danger detection" space, but here are alternatives from different domains:

6. **Filament** - The thinnest wire in a system, the first thing to burn out when current spikes. Implies sensitivity to overload at the weakest point.

7. **Downdraft** - In meteorology, a downdraft is the descending air current that precedes a storm's worst impact. Implies something moving downward that you can detect before it hits ground level.

8. **Wick** - The part of a candle that burns first and signals how much fuel remains. Also evokes "early wick" of a fuse - catching something before it reaches the charge.

## Evaluation of Strongest Candidates

### Tremor
The strongest candidate. A tremor is universally understood as a small shake that signals something bigger coming. It maps precisely to what the tool does: detecting small oscillations in latency and error rates that precede a full outage. It's one word, six letters, easy to say, easy to type. "Tremor detected a latency spike in the payments service" reads naturally. It implies urgency without panic - a tremor is notable but not catastrophic, which matches the tool's role of early warning rather than incident response. It also has a nice technical feel without being jargon.

### Canary
The most immediately legible name. Everyone in infrastructure knows the "canary in the coal mine" metaphor, and "canary deployments" are already standard vocabulary. That familiarity is both a strength and a slight weakness - it's so common in devops contexts that it might feel generic or clash with existing canary deployment tooling. But for pure metaphorical fit, it's hard to beat. The canary doesn't fix anything; it just dies first, giving you time to react. That's exactly what this tool does.

### Seam
The most interesting candidate. Less obvious than Tremor or Canary, but it captures something the others miss: the tool specifically watches the boundaries between services, where dependency graphs create stress points. A seam is where two materials meet and where fractures propagate. "Seam flagged stress on the order-to-inventory boundary" communicates something precise. It's short, calm, and durable. The risk is that it's less immediately evocative of "early warning" than Tremor or Canary - you'd need to explain it once. But once explained, it sticks.

## Recommendation

**Tremor** is the strongest all-around name. It implies exactly the right mechanism - detecting small vibrations before a larger event - without needing explanation. It's short, concrete, memorable, and avoids collision with existing devops terminology.

**Canary** is the safe pick if you want instant recognition. **Seam** is the pick if you want something more distinctive that rewards a second of thought.
