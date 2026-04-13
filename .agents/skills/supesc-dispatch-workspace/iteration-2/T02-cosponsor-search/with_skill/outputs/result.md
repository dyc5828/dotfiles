# SUPESC-T02 Triage Result

## Ticket
- **ID:** SUPESC-T02
- **Title:** HBN partner showing as deactivated in co-sponsor search
- **Summary:** Support is trying to add LO Bailey Bravo as a co-sponsor to REA Carmen Charlie's account via HB Admin. Bailey has an active Unlimited subscription but shows up with a "preferred partner" tag. The system won't let them add him as a co-sponsor.

## Determination: Category A - Answerable from the codebase

## Analysis

Bailey Bravo's customer profile is in the `preferred_partner` state (state 7). This is a special state in Mikasa for non-REA HBN partners who were transitioned off their subscription as part of the HBN preferred partner migration. The state is defined in `mikasa/app/models/concerns/customer_states_concern.rb` (line 19) and is distinct from `active` (state 2).

This state is the root cause of both symptoms in the ticket:

**Why the "preferred partner" tag appears:** The general customer search in HBAdmin (`lockbox/app/assets/javascripts/employee/customer.es6`, line 50) renders a green badge with the text "Preferred Partner" for customers in this state. That's what support is seeing when they look Bailey up.

**Why he can't be added as a co-sponsor:** The sponsor search field on REA profile edit pages (`lockbox/app/assets/javascripts/employee/sponsorship-search.es6`, line 15) hits the autocomplete endpoint with a hardcoded `state=active` filter:

```
/employee/profiles/autocomplete?query=%QUERY&type=loan_officer&state=active
```

The `build_filter` method in `lockbox/app/controllers/employee/customer_profiles_controller.rb` (line 275) passes this as an exact-match Elasticsearch term filter: `{ term: { state: state_filter } }`. Since Bailey is in `preferred_partner` state rather than `active`, he's excluded from sponsor search results entirely.

Additionally, even if Bailey were found through another path, the `homebot_network_user_status` method in `mikasa/app/models/concerns/customer_profile/connections_concern.rb` (line 28) would classify him as `not_active_homebot_user` because the check requires `!customer.preferred_partner?`:

```ruby
def active_homebot_user?(customer)
  customer.active? && !customer.preferred_partner? && !customer.on_preferred_partner_plan?
end
```

**Why Bailey has a subscription but is stuck in this state:** The ticket says Bailey has an active Unlimited subscription. The `preferred_partner` state transition (`mikasa/app/domains/homebot_network/transition_to_preferred_partner.rb`) cancels the subscription and closes the billing account as part of the transition. If Bailey later got a new Unlimited subscription (resubscribed), his state would not automatically update. The `RecalculateCustomerState` interactor (line 18) explicitly blocks recalculation for `preferred_partner` customers unless they're no longer on an HBN plan AND have a subscription. In Bailey's case, he has a non-HBN subscription (Unlimited), so recalculation would actually proceed if triggered - but it may never have been triggered after the new subscription was created.

**Resolution path:** Bailey's customer profile state needs to be recalculated or manually transitioned from `preferred_partner` to `active`. If he has an active Unlimited subscription and is assigned to an office, calling `RecalculateCustomerState` for his profile should transition him to `active`, which would make him appear in sponsor search and be eligible for co-sponsorship. This can be done from a Rails console in Mikasa.

## Routing

**Category A** - This is answerable from the codebase. The behavior is working as coded. The issue is that Bailey's profile state is stale after resubscribing. The fix is an operational state recalculation, not a code change.

### Slack thread reply (dry run - would reply to Slack-synced comment)

Bailey Bravo's profile is in a "preferred partner" state, which is a special internal state for HBN partners who were previously transitioned off their subscription. This state excludes him from the co-sponsor search because that search only returns loan officers in the "active" state.

Since Bailey now has an active Unlimited subscription, his profile state just needs to be recalculated to transition him back to "active." This can be done from the Rails console in Mikasa:

```
RecalculateCustomerState.call(customer: CustomerProfile.find(<marcus_profile_id>))
```

Once his state is recalculated to "active," he'll appear in the sponsor search and can be added as Carmen Charlie's co-sponsor.

### Follow-up comment (dry run - would post as top-level comment)

Closing this out since the behavior is clear from the codebase. If this doesn't fully answer the question or there's something else needed on top of this, feel free to reopen the ticket.

### Actions (dry run - not executed)
- Reply to Slack-synced comment thread with the answer above
- Close the ticket (mark as Done)
- Post follow-up closing comment

## Key Files Referenced
- `mikasa/app/models/concerns/customer_states_concern.rb` - State machine with `preferred_partner` (state 7)
- `mikasa/app/models/concerns/customer_profile/connections_concern.rb` - `homebot_network_user_status` and `active_homebot_user?` checks
- `lockbox/app/assets/javascripts/employee/sponsorship-search.es6` - Sponsor search with `state=active` filter
- `lockbox/app/controllers/employee/customer_profiles_controller.rb` - `build_filter` and `autocomplete` methods
- `mikasa/app/interactors/recalculate_customer_state.rb` - State recalculation logic
- `mikasa/app/domains/homebot_network/transition_to_preferred_partner.rb` - How users enter preferred_partner state
- `lockbox/app/assets/javascripts/employee/customer.es6` - General search UI with Preferred Partner badge
