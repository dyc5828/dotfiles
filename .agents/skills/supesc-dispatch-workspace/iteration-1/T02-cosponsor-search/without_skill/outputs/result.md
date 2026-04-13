## Routing Decision

**Route to: Customer Experience**

## Comment

Routing to **Customer Experience** -- this is an HBN/co-sponsorship issue in the Lockbox HB Admin tooling.

**What's happening:** The support agent is trying to add LO Bailey Bravo as a co-sponsor to REA Carmen Charlie's account via HB Admin. Bailey has an active Unlimited subscription, but the co-sponsor search shows him with a "preferred partner" tag and blocks the addition.

**Root cause analysis:** Bailey Bravo's `customer_profiles.state` is likely stuck in the `preferred_partner` state (enum value 7) even though he has an active subscription. The `preferred_partner` state is intended for non-REA HBN partners who have been transitioned off their subscription. If Bailey was previously an HBN-only partner and then upgraded to an Unlimited subscription, his state may not have been recalculated back to `active`.

The co-sponsor search in HB Admin (`lockbox/app/assets/javascripts/employee/sponsorship-search.es6`) filters the autocomplete endpoint with `state=active`, which means anyone in `preferred_partner` state is excluded from co-sponsor search results entirely. Meanwhile, the HB Admin profile page (`lockbox/app/views/employee/users/_alerts.html.erb`) only shows a "deactivated" warning for the `onboarding` state -- so Bailey's profile page may appear normal despite his state being `preferred_partner`, which the support agent interprets as "active status."

**Why CX:** This touches HBN team membership logic, the `preferred_partner` state machine, and co-sponsorship workflows -- all owned by the Customer Experience team. There is an existing rake task (`homebot_network:fix_preferred_partner_states`) in Mikasa specifically for fixing customers stuck in `preferred_partner` state who shouldn't be. The fix likely involves running that task for this user or manually recalculating their state, followed by investigating why the state transition didn't fire when the subscription was activated.

**Relevant code paths:**
- `mikasa/app/models/concerns/customer_states_concern.rb` -- state machine with `preferred_partner` state
- `mikasa/app/interactors/recalculate_customer_state.rb` -- state recalculation (note: line 18 short-circuits for `preferred_partner` state if on an HBN plan or no subscription)
- `mikasa/lib/tasks/homebot_network/fix_preferred_partner_states.rake` -- existing fix task
- `lockbox/app/assets/javascripts/employee/sponsorship-search.es6` -- co-sponsor search filters by `state=active`
