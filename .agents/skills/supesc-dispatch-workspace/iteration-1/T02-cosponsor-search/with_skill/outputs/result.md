# SUPESC-T02 Triage Result

## Routing Decision

**Route to: Customer Experience**

**Category: B - Routable to a team**

This ticket involves HBN partner states, co-sponsorship management, and the co-sponsor search in HB Admin - all of which fall under the Customer Experience team's surface area (CEP features: HBN, partners, co-sponsors, co-sponsorship management).

## Analysis

The co-sponsor search in HB Admin (`lockbox/app/assets/javascripts/employee/sponsorship-search.es6`) queries the autocomplete endpoint with a hard filter of `state=active`:

```
/employee/profiles/autocomplete?query=%QUERY&type=loan_officer&state=active
```

The autocomplete controller (`lockbox/app/controllers/employee/customer_profiles_controller.rb`) passes this state filter directly into an Elasticsearch term query via `build_filter`, which means only customer profiles with `state: "active"` (enum value 2) are returned.

Bailey Bravo's customer profile is in the `preferred_partner` state (enum value 7). This state is distinct from `active` and is used for non-REA HBN partners who have been transitioned off their subscription. Because the co-sponsor search only returns `active` LOs, Bailey does not appear in the co-sponsor search results.

The ticket mentions Bailey has an "active Unlimited subscription," but the `preferred_partner` state transition (`mikasa/app/domains/homebot_network/transition_to_preferred_partner.rb`) explicitly cancels the subscription and closes the billing account before transitioning the profile state. This suggests either:

1. A data inconsistency where Bailey was transitioned to `preferred_partner` state but his subscription wasn't properly cancelled (or was reactivated afterward), or
2. The support agent is reading "active" from a different indicator on the HB Admin page (e.g., the user account status vs. the customer profile state).

Either way, production data access is needed to confirm Bailey's actual customer profile state and subscription status. The CX team can investigate and determine whether Bailey needs to be re-activated (if the preferred_partner transition was incorrect) or whether the co-sponsor search should also include preferred_partner profiles as eligible sponsors.

## Comment to Post on Ticket

**Routing: Customer Experience**

This is an HBN partner state issue affecting the co-sponsor search in HB Admin. The co-sponsor search only returns loan officers in "active" profile state, but Bailey Bravo's profile appears to be in "preferred partner" state - a separate state used for HBN partners who were transitioned off their subscription plan. That's why he shows the "preferred partner" tag in search and can't be selected as a co-sponsor.

The ticket says Bailey has an active Unlimited subscription, which would be unusual for a preferred partner profile since that transition normally cancels the subscription. CX team will need to check Bailey's actual profile state and subscription in production to determine whether his profile needs to be re-activated or whether the transition to preferred partner was done in error.
