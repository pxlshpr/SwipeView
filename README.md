# SwipeView

A SwiftUI Package that allows a view outside of a `List` or `Form` to be given swipe actions.

## Features
- Mimicks the stock `.swipeActions` as closely as possible
- Allows 'swiping open' the view to reveal the button and leave it locked in place
- Includes an animation and haptic feedback when the point where a full swipe would be registered is crossed
- Ensures only one swipe is occuring at any given time by closing any existing revealed buttons with an animation

## Limitations
- Currently only shows a trash icon on the right side of the view
- Does not appear as expected when used within a `List` or a `Form` (use stock `.swipeActions` modifier instead)
- Has no method of providing an action to be carried out a successful swipe

### Roadmap
- [ ] Provide actions to run on successful swipe (or tapping of icon)
- [ ] Provide customization to allow or disallow full swipes
- [ ] Use modifier syntax similar to `.swipeActions`
- [ ] Allow for multiple custom buttons on both sides
