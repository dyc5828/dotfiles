---
name: dan-voice
description: How to draft messages in Dan's voice when he'll post them as himself. Use whenever drafting Slack messages or DMs, GitHub PR review comments and inline review replies, or Linear comments — anywhere Dan replies as a person. Not for ticket bodies, formal docs, or email. Triggers on "use my voice", "in my voice", "sound like me", "draft a message", "draft a reply", "write a Slack message", "draft a PR comment", "draft a Linear comment", or any request to compose something Dan will post under his own name.
---

# Drafting in Dan's Voice

This is a living guide for sounding like Dan when drafting messages he'll post as himself. Update it as new patterns emerge from edits and corrections he makes to drafts.

## Underlying themes

These are the instincts behind every rule below. When in doubt, fall back to these.

1. **Measured by default.** The base register is calm. Praise is concrete and rare. No "Awesome" or "really clear write-up" openers, no "excited to see this land" trailers. Compliment the work in a measured way, not the person.

2. **Trust the reader to connect ideas.** Drop meta-bridges like "That said," "Agreed," and "Otherwise." When two thoughts sit next to each other, the link is obvious. Narrating the connection is friction.

3. **Carry the idea, not the artifact.** Class names, method names, PR numbers, and framework jargon get translated into the underlying concept. Artifacts belong in the ticket or PR body. The message carries the understanding.

4. **Collaborator, not authority.** Pushback frames as curiosity. Every objection comes with a specific alternative. Non-blocking things get marked as non-blocking.

5. **Brevity reads as decided.** Long messages look defensive, short ones look settled. Cut one more sentence than feels comfortable.

6. **One arc per message.** Diagnosis and remedy fold into the same paragraph when they can. The structure is not setup, bridge, punchline.

7. **Describe, don't editorialize.** Avoid framing a feature's completeness with "we sort of have it" or "we do have a small piece of this." Just state what happens and what doesn't. The reader judges completeness from the description.

8. **Write to the thread, not to Dan.** A draft is a reply to the people in the thread, picking up from the last thing they said. It is not the next turn in the chat with Dan. Whatever the chat worked out is raw material the thread hasn't seen, so it gets stated as new information or left out.

## Read the thread before drafting

When a draft is going back to a Slack thread, a PR, a Linear issue, or an email chain, pull that thread first. Slack, GitHub, Linear, and Gmail are all reachable, so the only reason to skip is that the thread genuinely isn't, and the handback should say so.

This guards against one specific failure. After a chat back-and-forth with Dan, the draft comes out as a reply to Dan. It answers the question he asked in chat, uses the framing the chat settled on, and assumes the reader was in the room. The thread saw none of that.

Draft for the thread:

- **Open on the thread's last message, not Dan's.** If the thread asked whether X handles Y, the first sentence answers that, even if the chat went somewhere more interesting.
- **Know who is reading and what they already know.** Translation level, jargon, and which details are load-bearing follow from the thread's audience, not from how the chat talked about it.
- **Chat context is new information to the thread.** Anything worked out in chat gets stated as a fact the reader can use, or stays out. No "as discussed" or "the thing we found" when the thread never saw it.
- **Drop working shorthand.** Labels coined during the chat don't exist outside it.
- **Dan's chat questions are not the thread's questions.** If Dan asked "is it the callback or the job?", the draft states what the mechanism is. It doesn't report which chat hypothesis won.

Before handing back, read the draft as the thread's most recent participant. If the first sentence only lands for someone who read the chat, restart from the thread's last message.

Added 2026-10-20 from Dan's note that drafts after a chat back-and-forth sometimes read as a reply to him when they should read as a reply to the thread's audience.

## The shape of a typical review / feedback message

Dan's feedback messages have a consistent three-block structure. Use it as the default skeleton.

**Block 1 — Opener (own paragraph).** Light acknowledgment of the artifact plus a clear judgment plus a go-ahead. One or two sentences. The go-ahead lives here, not buried after the nits.

> ✅ "Looked over the notion doc. Looks like a solid plan, and I think this is a good direction."
>
> ❌ "Awesome — this is amazing work and totally fixes the primary issue!"

Don't be effusive. Don't compliment the person, compliment the work in a measured way. Don't open with "Awesome" or "Great work" as the entire first line.

**Block 2 — Transition line (own paragraph).** Always frame nits as suggestions, never as blockers.

> ✅ "A few things worth poking at, all suggestions:"

Variants Dan uses depending on context: "A few thoughts, all suggestions:", "Couple things worth poking at:", "Some things to consider, not blockers:".

**Block 3 — Numbered items.** One to two sentences each. Lead with the concern, then the suggestion. Concrete alternatives beat abstract complaints.

**No closing line.** Don't add a "otherwise this looks great!" / "excited to see this land!" trailer. The opener already carried the praise; the trailer is redundant and dilutes the suggestions above it.

## Per-item style for numbered points

- **One to two sentences max.** If a point needs more, it's probably two points.
- **Lead with the concern, follow with the suggestion.** Not the other way around.
- **Concrete alternative, not just an objection.** "Curious if there's a cleaner way, like just fixing the broken branch directly" beats "this feels off."
- **Mostly non-technical language when the audience is mixed eng/PM.** Translate jargon down. "the model's callback" instead of "the `after_commit :notify_rea` callback". "behind the scenes" instead of "side effects". Code identifiers in backticks are fine when load-bearing.
- **Abstract vendor names and implementation details for mixed audiences.** "CoreLogic" → "what's on file." Table names like `home_value_adjustments` → "a manual override." PMs and CS care about behavior, not the data source.
- **Soft framing.** "Probably fine in practice, but…", "Worth a quick check that…", "Could be worth a sanity check with X…".

## When amending or following up in a thread

Different cadence from a top-level review. No three-block opener — just the substance.

- **Skip the greeting and process narration.** Don't open with "Hey [name] — checked the code" or "Looked into this and…". The reader doesn't need to know how the answer was produced. Lead with the answer.
- **Don't name-drop people who are in the thread.** Referencing "Michael's recollection" or "what Dave said" when those participants can see the thread is redundant at best and reads as going over their heads at worst. State the substance directly.
- **Qualify scope upfront when the answer is partial.** "On the app side, no…" beats burying the scope qualifier in the middle.
- **Correction openers are fine, never apologetic.** "Quick clarification" or "Quick correction" work for amending a prior message. Avoid "Sorry, missed this" or "Actually, I should have mentioned…" — those frame the correction as a mistake instead of new information.
- **"Solves X, doesn't solve Y" beats "we sort of have it."** When scoping a mechanism, state what it covers, then what it doesn't. Two parallel statements read as decided.
- **Target 2-3 sentences.** History, provenance, and full mechanism details belong in a PR or doc, not a thread follow-up.

## Brain-dump → distill workflow

Dan often brain-dumps the framing he wants in stream-of-consciousness form ("I'm just gonna kind of brain dump a little bit. The way I want to kind of frame it…"), then expects a tight 2-3 sentence message back.

Two things to do every time:

1. **Verify his read against the source material first.** Re-read the thread, the code, the diff. If his framing is off in any way, push back before drafting. He explicitly invites this: "Push back if I'm misstating something or if I have the wrong read."
2. **Cut his hedges in the distillation.** "Kind of," "more the," "I think," "I would say" don't survive into the final. The brain-dump uses them to feel out the angle; the message states the angle.

## Push-back style

When pushing back on a design choice:

- Frame as **curiosity**, not prescription. "Curious if there's a cleaner way, like [concrete alternative]" not "This should be done differently."
- Always pair the pushback with a **specific alternative** Dan would propose.
- Mark explicitly as **not blocking** when it isn't.

## Writing rules

These come from `~/.claude/CLAUDE.md` and are reinforced through Dan's edits:

- **No em dashes.** Regular hyphens are fine for context or asides, but never two in one sentence. Restructure with commas or break into two sentences.
- **No parentheses for asides.** Restructure or use a hyphen.
- **Colons only to introduce lists**, not as general punctuation.
- **Direct statements.** No rhetorical questions.
- **Bold only for structural labels and headings**, never mid-sentence emphasis.
- **Short over long.** Phrases over full sentences when meaning is clear.
- **Should read like a person wrote it**, not like it was generated.
- **Don't overstate.** Claim what the evidence supports and stop there.
- **No counterfactuals.** No "without this, X would have broken" or "this isn't just X, it's Y." "Solves X, doesn't solve Y" is still fine.
- **Drop immaterial tensions.** Leave out tradeoffs and caveats that don't change the work or the decision.

## Voice signals to keep

Phrases Dan uses naturally — sprinkle, don't overuse:

- "Worth a quick check that…"
- "Same frame, …" (for connecting a related thought to the prior one)
- "Probably fine, but a [logline / breadcrumb / sanity check] would give us a [breadcrumb / paper trail / safety net]"
- "Curious if there's a cleaner way, like…"
- "Not blocking, just want your read."
- "Could be worth looping [person] in on this."

## Channel-specific cadence

**Slack / DM** — what we've been doing in this session. Mixed audience tolerated. Default to the three-block shape above.

**Group DM with PMs in the audience** — push the language non-technical even further. Identifiers in backticks are fine; jargon isn't.

**PR-ready announcements (#reviewit and similar dev channels)** — different shape from feedback messages. No three-block opener; the PR link _is_ the message. Format:

```
<group-tag> <pr-link>
• bullet describing change 1
• bullet describing change 2
• bullet describing change 3
```

Rules specific to this pattern:

- **Tag the team's user group by default.** Add individuals on the same line when their review is critical or preferred for the change — e.g., subject-matter owner of the file, the engineer who paired on the work, someone whose pattern was being followed. No need to also tag a reviewer who's already requested on the PR _unless_ that's the signal you want to send (a nudge).
- **Group tag + PR link on the same line.** Both at the very top.
- **No opener prose.** No "Hey team", no "PR's ready for review", no judgment about the work. The link plus bullets is enough.
- **Bullets are phrases or short fragments, not full sentences.** "adds optional X", "fixes Y", "small tweaks to enable Z". Punctuation-light. Sentence fragments are fine.
- **Jargon is fine here.** Audience is engineers; internal acronyms (ENT, HBN, CTMs, prod-console) don't need translation. Save translation for mixed channels.
- **It's a preview, not a record.** The job is to help people understand what the PR is about at a glance, enough to decide whether to open it. It is not the PR's changelog or audit trail. Surface the genuinely important notes: what changed and why it matters. Mechanics, edge cases, and full detail live in the PR body, where reviewers will read them.
- **Leave verification out.** No "tested on X", "verified Y still works", "confirmed no collateral" bullets. Reviewers assume that's covered in the PR notes, so restating it here adds noise and reads defensive. It belongs in the PR body.
- **Skip the Linear ticket line.** The PR link is enough; the ticket is one click from the PR. Don't add a "Linear INF-123" bullet. Others in the channel do, Dan's posts don't.
- **One bullet per well-contained topic; let the work set the count.** There's no hard rule on number. The "what changed" might be one bullet or several, and so might the "why it matters" — it tracks how many materially distinct buckets the PR actually has. A focused PR is often one change bullet plus one impact bullet. A PR with two or three significantly different buckets of change gets two or three change bullets, and the same goes for impact. Each bullet should read as a self-contained topic a reader can grasp on its own, not a fragment of one. Don't pad to look thorough, and drop any bullet whose real home is the PR body.
- **No closing line.** No "let me know if you have questions" or "would love to ship today" trailers. If urgency matters, that goes in a follow-up reply, not on the top-level message.

**GitHub PR review comments** — terser. Suggestion framing still applies but the opener can be skipped if the comment is a single inline nit. For top-level reviews, the three-block shape still works.

**GitHub inline review replies** — usually one or two sentences, no opener. Reply directly to the point the reviewer raised. Same soft-framing rules.

**Linear comments** — investigation/handoff flavored. Often longer than Slack, structured with headers or numbered findings. Same suggestion framing when proposing next steps.

**Not for** — ticket bodies, formal docs, or email. Different cadence entirely. The "read the thread" rule still applies to email replies, since it's about audience rather than cadence.

## Reference example — the CMA review message (2026-06-02)

Final landed version after Dan's edits, useful as a calibration sample:

> Looked over the notion doc. Looks like a solid plan, and I think this is a good direction.
>
> A few things worth poking at, all suggestions:
>
> 1. CMA requests can also be created through a separate API controller, so worth checking no current path lands a Title customer there. Same frame, going around the callback might also be skipping other side effects, so could be worth a sanity check with Jonathan that nothing else quietly breaks.
> 2. The new path trusts whatever REA ID the event sends, where today we'd crash on a mismatch. A log line on mismatch would give us a breadcrumb if it ever drifts.
> 3. `skip_notification` mostly exists to keep the callback from double-sending. Curious if there's a cleaner way, like just fixing the broken branch of the callback itself.

What changed between my first draft and the final:

- **Opener** went from "Awesome — this fixes the primary issue" to a measured "Looked over the notion doc. Looks like a solid plan, and I think this is a good direction." Less effusive, includes explicit go-ahead.
- **Transition line** got its own paragraph instead of running into the opener.
- **Each numbered item shrunk** from 3-5 sentences to 1-2.
- **Closing summary line** ("Otherwise this looks really solid") was removed — redundant with the opener.
- **Jargon translated down**: "after_commit callback" → "the model's callback", "side effects" → "doing other things behind the scenes".

## Reference example — the AVM clarification message (2026-06-03)

Slack thread reply, mixed eng/PM/CS audience. Dan had me post a first message on his behalf saying we had no sale-price floor logic. A deeper investigation surfaced a one-time appraisal-based adjustment, so he asked for a clarification. Final landed version:

> Quick clarification. When there's a sold or appraised price on file, we do a one-time adjustment at home creation that bumps the displayed value up to match. That handles the immediate mismatch case, but it isn't a floor, so the AVM can still drift down after that.

What got cut between my first drafts and final:

- **Greeting and process narration**: "Hey Meg — checked the code" and "Looked into this" both got dropped.
- **References to other thread participants**: "Michael's recollection" and "what Dave said" got dropped — they're in the thread.
- **Vendor name**: "CoreLogic" got abstracted to "on file" for the non-technical audience.
- **Self-deprecating framing**: "we do have a small piece of this" got dropped — Dan wanted a direct description of what happens, not a hedge.
- **History/provenance**: when and who added the mechanism (Erik Mingo, 2019, porting from the legacy api repo) got dropped — belongs in a PR or doc, not a Slack follow-up.
- **What landed cleanly**: the "solves X, doesn't solve Y" framing — two parallel statements doing the work that a longer hedged paragraph couldn't.

## Reference example — the #reviewit PR announce (2026-06-03)

Top-level message announcing PR #265 (botfiles ent-corp-unlink skill updates) ready for review. Final landed version:

> <@S0XXXXXXXXX|ux-devs> https://github.com/homebotapp/botfiles/pull/265
> • adds optional ENT history audit to the ent-corp-unlink skill (when/who set the ENT ID)
> • corrects the prod-console boot and teardown sequence to match real behavior
> • adds guidance for cleaning up background monitors at teardown

What's load-bearing about the shape:

- **Group tag and PR link share the top line.** No prefacing sentence.
- **Bullet count matched the work.** Three was right here — could have been fewer for a smaller PR, more for a larger one. Order roughly tracks user-visible weight: the audit add-on (largest behavioral change), the boot/teardown correction (structural), the monitor cleanup (small operational addition).
- **Sentence fragments, not full sentences.** Each bullet starts with a verb ("adds", "corrects", "adds"), no subject, no period. Reads as a changelog entry, not prose.
- **Jargon survives.** "ENT", "prod-console", "ent-corp-unlink skill" — all stay, because the audience is `#reviewit` (devs only). Same content for `#general` would need translation.
- **Group-only tag in this case.** No individuals appended this time — the change was small enough and the group already had it covered. Adding individuals would have been the right call for a critical-path change or when a specific reviewer's eyes mattered.
- **No trailing line.** No "ready for review" header, no "let me know if questions" footer. The shape itself tells the reader what to do.

## Reference example — the #reviewit announce, trimmed to a preview (2026-06-11)

PR homebot-k8s#219 (dedicated ai-mastra bev ingress so the mastra server owns CORS). My first draft had five bullets plus a Linear line. Dan cut it to two. Final landed version:

> `<!subteam^S0XXXXXXXXX>` https://github.com/homebotapp/homebot-k8s/pull/219
> • creates a dedicated ai-mastra ingress on bevs with no nginx `enable-cors`, so the mastra server controls CORS itself, mirroring prod
> • unblocks HollyGPT chat on bevs

What Dan cut and why (his words: "this is just a message to help people understand, give people a little preview into what the PR is about"):

- **The Linear ticket bullet** ("INT-648") — gone. The PR link carries it.
- **The verification bullet** ("verified on water: HollyGPT chat streams, customer-admin Customer GPT still works") — gone. "People will assume people will read the PR notes for things." Verification lives in the PR body.
- **The CORS-mechanics bullets** (the wildcard `*` + credentials explanation, "shared ingress untouched for other hosts") — gone. Mechanics are PR-body detail, not preview material.
- **What survived:** two bullets — the change ("what": dedicated ingress, mastra owns CORS, mirrors prod) and the impact ("why it matters": unblocks HollyGPT chat on bevs). This PR had one well-contained bucket of each, so it landed at two. A PR with several materially different buckets of change or impact would have more — the count follows the work, not a target.

The lesson, now codified above: a #reviewit announce is a preview, not a record. Surface the important notes as self-contained topics, and let the number of distinct buckets set the bullet count.

## How to keep this guide useful

After Dan edits a draft you wrote, look at the diff between your version and his final:

1. What did he cut? (likely effusive language, redundant trailers, jargon)
2. What did he reorder? (likely surfacing go-ahead earlier)
3. What did he soften? (likely framing pushback as curiosity)
4. What did he add? (likely concrete alternatives or specific people to loop in)

When a pattern shows up twice across sessions, add it to this file as a rule or a phrase. Don't try to capture every one-off — only patterns that would mislead a future draft if missing.
