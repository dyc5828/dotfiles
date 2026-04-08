# Naming Suggestions: Microservice Early-Warning Degradation Detector

Here are several name options organized by the angle they take on what your tool does.

---

## Top Recommendations

### 1. Canary

A direct reference to the "canary in a coal mine" - the classic early-warning system. Canaries detected toxic gases before miners were affected, which maps perfectly to detecting service degradation before full outages. Short, memorable, and immediately communicates the purpose to any engineer.

**Variants:** Canary, CanaryWatch, Canary Engine

### 2. Tremor

Earthquakes produce small tremors before the main event. Your tool detects the "tremors" in your microservice ecosystem - latency spikes and error rate changes that precede a full failure. It's visceral, short, and conveys both the detection of small signals and the implication that something bigger is coming.

### 3. Sentry

Evokes a guard standing watch, scanning the horizon for threats. It communicates vigilance and proactive defense. One caveat: the error-tracking product Sentry already occupies this name in the observability space, so it could cause confusion depending on your stack.

### 4. Harbinger

Means "a person or thing that announces or signals the approach of something." It has a slightly ominous tone that fits well for a degradation detector - you want people to pay attention when it speaks up.

### 5. Undertow

Before a wave crashes visibly on the surface, dangerous currents build underneath. Undertow captures the idea that degradation often starts below the surface - in dependency chains and upstream latency - before it becomes a visible outage. It also suggests the pulling-down force that cascading failures create.

---

## Additional Options

### Functional / Descriptive Angle

- **Pulse** - Like checking a patient's vital signs. Simple and conveys continuous health monitoring.
- **Drift** - Services "drift" from healthy baselines before they crash. Suggests gradual deviation, which matches your latency and error rate correlation.
- **Tidewatch** - Tides shift before storms arrive. Implies watching for the slow, measurable changes that precede major disruptions.

### Metaphorical / Evocative Angle

- **Seismograph** - The instrument that detects tremors. More literal than "Tremor" but clearly communicates signal detection. Could shorten to **Seismo**.
- **Lookout** - The crew member at the top of the mast, spotting danger before the ship reaches it. Plain-spoken and clear.
- **Weathervane** - Shifts direction with the wind before the storm hits. Implies sensitivity to early directional changes in service health.

### Mythology / Cultural Angle

- **Cassandra** - The Greek figure who could see the future but was cursed to not be believed. A wry, self-aware name for an alerting tool - and a nod to the Apache Cassandra project's naming tradition of using mythology in infra tooling.
- **Augur** - Roman priests who interpreted signs and omens to predict future events. Captures both the predictive nature and the idea of reading multiple signals together.

---

## My Pick

**Tremor** is the strongest choice. It is short, memorable, and metaphorically precise. It captures exactly what your tool does - detecting small vibrations in the system that signal a larger failure is building. It works well in conversation ("Tremor flagged the payments service"), in documentation, and in dashboards. It also does not collide with any major existing tools in the observability space.

**Canary** is the safest choice if you want something that requires zero explanation. Everyone on the team will instantly understand the metaphor.
