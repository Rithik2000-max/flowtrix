# wekan Data Persistence Architecture - 2025-12-23

**Status**: ✅ Latest Current  
**Updated**: 2025-12-23  
**Scope**: All data persistence related to swimlanes, lists, cards, checklists, checklistItems positioning and user preferences

---

## Executive Summary

wekan's data persistence architecture distinguishes between:
- **Board-Level Data**: Shared across all users on a board (positions, widths, heights, order)
- **Per-User Data**: Private to each user, not visible to others (collapse state, label visibility)

This document defines the authoritative source of truth for all persistence decisions.

---

## Data Classification Matrix

### ✅ PER-BOARD LEVEL (Shared - Stored in MongoDB Documents)

| Entity | Property | Storage | Format | Scope |
|--------|----------|---------|--------|-------|
| **Swimlane** | Title | MongoDB | String | Board |
| **Swimlane** | Color | MongoDB | String (ALLOWED_COLORS) | Board |
| **Swimlane** | Background | MongoDB | Object {color} | Board |
| **Swimlane** | Height | MongoDB | Number (-1=auto, 50-2000) | Board |
| **Swimlane** | Position/Sort | MongoDB | Number (decimal) | Board |
| **List** | Title | MongoDB | String | Board |
| **List** | Color | MongoDB | String (ALLOWED_COLORS) | Board |
| **List** | Background | MongoDB | Object {color} | Board |
| **List** | Width | MongoDB | Number (100-1000) | Board |
| **List** | Position/Sort | MongoDB | Number (decimal) | Board |
| **List** | WIP Limit | MongoDB | Object {enabled, value, soft} | Board |
| **List** | Starred | MongoDB | Boolean | Board |
| **Card** | Title | MongoDB | String | Board |
| **Card** | Color | MongoDB | String (ALLOWED_COLORS) | Board |
| **Card** | Background | MongoDB | Object {color} | Board |
| **Card** | Description | MongoDB | String | Board |
| **Card** | Position/Sort | MongoDB | Number (decimal) | Board |
| **Card** | ListId | MongoDB | String | Board |
| **Card** | SwimlaneId | MongoDB | String | Board |
| **Checklist** | Title | MongoDB | String | Board |
| **Checklist** | Position/Sort | MongoDB | Number (decimal) | Board |
| **Checklist** | hideCheckedItems | MongoDB | Boolean | Board |
| **Checklist** | hideAllItems | MongoDB | Boolean | Board |
| **ChecklistItem** | Title | MongoDB | String | Board |
| **ChecklistItem** | isFinished | MongoDB | Boolean | Board |
| **ChecklistItem** | Position/Sort | MongoDB | Number (decimal) | Board |

### 🔒 PER-USER ONLY (Private - User Profile or localStorage)

| Entity | Property | Storage | Format | Users |
|--------|----------|---------|--------|-------|
| **User** | Collapsed Swimlanes | User Profile / Cookie | Object {boardId: {swimlaneId: boolean}} | Single |
| **User** | Collapsed Lists | User Profile / Cookie | Object {boardId: {listId: boolean}} | Single |
| **User** | Hide Minicard Label Text | User Profile / localStorage | Object {boardId: boolean} | Single |
| **User** | Collapse Card Details View | Cookie | Boolean | Single |

---

## Implementation Details

### 1. Swimlanes Schema (swimlanes.js)

```javascript
Swimlanes.attachSchema(
  new SimpleSchema({
    title: { type: String },                    // ✅ Per-board
    color: { type: String, optional: true },    // ✅ Per-board (ALLOWED_COLORS)
    // background: { ...color properties... }   // ✅ Per-board (for future use)
    height: {                                   // ✅ Per-board (NEW)
      type: Number,
      optional: true,
      defaultValue: -1,                         // -1 means auto-height
      custom() {
        const h = this.value;
        if (h !== -1 && (h < 50 || h > 2000)) {
          return 'heightOutOfRange';
        }
      },
    },
    sort: { type: Number, decimal: true, optional: true }, // ✅ Per-board
    boardId: { type: String },                  // ✅ Per-board
    archived: { type: Boolean },                // ✅ Per-board
    // NOTE: Collapse state is per-user only, stored in:
    // - User profile: profile.collapsedSwimlanes[boardId][swimlaneId] = boolean
    // - Non-logged-in: Cookie 'wekan-collapsed-swimlanes'
  })
);
```

### 2. Lists Schema (lists.js)

```javascript
Lists.attachSchema(
  new SimpleSchema({
    title: { type: String },                    // ✅ Per-board
    color: { type: String, optional: true },    // ✅ Per-board (ALLOWED_COLORS)
    // background: { ...color properties... }   // ✅ Per-board (for future use)
    width: {                                    // ✅ Per-board (NEW)
      type: Number,
      optional: true,
      defaultValue: 272,                        // default width in pixels
      custom() {
        const w = this.value;
        if (w < 100 || w > 1000) {
          return 'widthOutOfRange';
        }
      },
    },
    sort: { type: Number, decimal: true, optional: true }, // ✅ Per-board
    swimlaneId: { type: String, optional: true }, // ✅ Per-board
    boardId: { type: String },                  // ✅ Per-board
    archived: { type: Boolean },                // ✅ Per-board
    wipLimit: { type: Object, optional: true }, // ✅ Per-board
    starred: { type: Boolean, optional: true }, // ✅ Per-board
    // NOTE: Collapse state is per-user only, stored in:
    // - User profile: profile.collapsedLists[boardId][listId] = boolean
    // - Non-logged-in: Cookie 'wekan-collapsed-lists'
  })
);
```

### 3. Cards Schema (cards.js)

```javascript
Cards.attachSchema(
  new SimpleSchema({
    title: { type: String, optional: true },    // ✅ Per-board
    color: { type: String, optional: true },    // ✅ Per-board (ALLOWED_COLORS)
    // background: { ...color properties... }   // ✅ Per-board (for future use)
    description: { type: String, optional: true }, // ✅ Per-board
    sort: { type: Number, decimal: true, optional: true }, // ✅ Per-board
    swimlaneId: { type: String },              // ✅ Per-board (REQUIRED)
    listId: { type: String, optional: true },  // ✅ Per-board
    boardId: { type: String, optional: true }, // ✅ Per-board
    archived: { type: Boolean },               // ✅ Per-board
    // ... other fields are all per-board
  })
);
```

### 4. Checklists Schema (checklists.js)

```javascript
Checklists.attachSchema(
  new SimpleSchema({
    title: { type: String },                   // ✅ Per-board
    sort: { type: Number, decimal: true },     // ✅ Per-board
    hideCheckedChecklistItems: { type: Boolean, optional: true }, // ✅ Per-board
    hideAllChecklistItems: { type: Boolean, optional: true }, // ✅ Per-board
    cardId: { type: String },                  // ✅ Per-board
  })
);
```

### 5. ChecklistItems Schema (checklistItems.js)

```javascript
ChecklistItems.attachSchema(
  new SimpleSchema({
    title: { type: String },                   // ✅ Per-board
    sort: { type: Number, decimal: true },     // ✅ Per-board
    isFinished: { type: Boolean },             // ✅ Per-board
    checklistId: { type: String },             // ✅ Per-board
    cardId: { type: String },                  // ✅ Per-board
  })
);
```

### 6. User Schema - Per-User Data (users.js)

```javascript
// User.profile structure for per-user data
user.profile = {
  // Collapse states - per-user, per-board
  collapsedSwimlanes: {
    'boardId123': {
      'swimlaneId456': true,   // swimlane is collapsed for this user
      'swimlaneId789': false
    },
    'boardId999': { ... }
  },

  // Collapse states - per-user, per-board
  collapsedLists: {
    'boardId123': {
      'listId456': true,       // list is collapsed for this user
      'listId789': false
    },
    'boardId999': { ... }
  },

  // Label visibility - per-user, per-board
  hideMiniCardLabelText: {
    'boardId123': true,        // hide minicard labels on this board
    'boardId999': false
  }
}
```

---

## Client-Side Storage (Non-Logged-In Users)

For users not logged in, collapse state is persisted via cookies (localStorage alternative):

```javascript
// Cookie: wekan-collapsed-swimlanes
{
  'boardId123': {
    'swimlaneId456': true,
    'swimlaneId789': false
  }
}

// Cookie: wekan-collapsed-lists
{
  'boardId123': {
    'listId456': true,
    'listId789': false
  }
}

// Cookie: wekan-card-collapsed
{
  'state': false  // is card details view collapsed
}

// localStorage: wekan-hide-minicard-label-{boardId}
true or false
```

---

## Data Flow

### ✅ Board-Level Data Flow (Swimlane Height Example)

```
1. User resizes swimlane in UI
2. Client calls: Swimlanes.update(swimlaneId, { $set: { height: 300 } })
3. MongoDB receives update
4. Schema validation: height must be -1 or 50-2000
5. Update stored in swimlanes collection: { _id, title, height: 300, ... }
6. Update reflected in Swimlanes collection reactive
7. All users viewing board see updated height
8. Persists across page reloads
9. Persists across browser restarts
```

### ✅ Per-User Data Flow (Collapse State Example)

```
1. User collapses swimlane in UI
2. Client detects LOGGED-IN or NOT-LOGGED-IN
3. If LOGGED-IN:
   a. Client calls: Meteor.call('setCollapsedSwimlane', boardId, swimlaneId, true)
   b. Server updates user profile: { profile: { collapsedSwimlanes: { ... } } }
   c. Stored in users collection
4. If NOT-LOGGED-IN:
   a. Client writes to cookie: wekan-collapsed-swimlanes
   b. Stored in browser cookies
5. On next page load:
   a. Client reads from profile (logged-in) or cookie (not logged-in)
   b. UI restored to saved state
6. Collapse state NOT visible to other users
```

---

## Validation Rules

### Swimlane Height Validation
- **Allowed Values**: -1 (auto) or 50-2000 pixels
- **Default**: -1 (auto)
- **Trigger**: On insert/update
- **Action**: Reject if invalid

### List Width Validation
- **Allowed Values**: 100-1000 pixels
- **Default**: 272 pixels
- **Trigger**: On insert/update
- **Action**: Reject if invalid

### Collapse State Validation
- **Allowed Values**: true or false
- **Storage**: Only boolean values allowed
- **Trigger**: On read/write to profile
- **Action**: Remove if corrupted

---

## Migration Strategy

### For Existing Installations

1. **Add new fields to schemas**
   - `Swimlanes.height` (default: -1)
   - `Lists.width` (default: 272)

2. **Populate existing data**
   - For swimlanes without height: set to -1 (auto)
   - For lists without width: set to 272 (default)

3. **Remove per-user storage if present**
   - Check user.profile.swimlaneHeights → migrate to swimlane.height
   - Check user.profile.listWidths → migrate to list.width
   - Remove old fields from user profile

4. **Validation migration**
   - Ensure all swimlaneIds are valid (no orphaned data)
   - Ensure all widths/heights are in valid range
   - Clean corrupted per-user data

---

## Security Implications

### Per-User Data (🔒 Private)
- Collapse state is per-user → User A's collapse setting doesn't affect User B's view
- Hide label setting is per-user → User A's label visibility doesn't affect User B
- Stored in user profile → Only accessible to that user
- Cookies for non-logged-in → Stored locally, not transmitted

### Per-Board Data (✅ Shared)
- Heights/widths are shared → All users see same swimlane/list sizes
- Positions are shared → All users see same card order
- Colors are shared → All users see same visual styling
- Stored in MongoDB → All users can query and receive updates

### No Cross-User Leakage
- User A's preferences never stored in User B's profile
- User A's preferences never affect User B's view
- Each user has isolated per-user data space

---

## Testing Checklist

### Per-Board Data Tests
- [ ] Resize swimlane height → all users see change
- [ ] Resize list width → all users see change
- [ ] Move card between lists → all users see change
- [ ] Change card color → all users see change
- [ ] Reload page → changes persist
- [ ] Different browser → changes persist

### Per-User Data Tests
- [ ] User A collapses swimlane → User B sees it expanded
- [ ] User A hides labels → User B sees labels
- [ ] User A scrolls away → User B can collapse same swimlane
- [ ] Logout → cookies maintain collapse state
- [ ] Login as different user → previous collapse state not visible
- [ ] Reload page → collapse state restored for user

### Validation Tests
- [ ] Set swimlane height = 25 → rejected (< 50)
- [ ] Set swimlane height = 3000 → rejected (> 2000)
- [ ] Set list width = 50 → rejected (< 100)
- [ ] Set list width = 2000 → rejected (> 1000)
- [ ] Corrupt localStorage height → cleaned on startup
- [ ] Corrupt user profile height → cleaned on startup

---

## Related Files

| File | Purpose |
|------|---------|
| [models/swimlanes.js](../../../models/swimlanes.js) | Swimlane model with height field |
| [models/lists.js](../../../models/lists.js) | List model with width field |
| [models/cards.js](../../../models/cards.js) | Card model with position tracking |
| [models/checklists.js](../../../models/checklists.js) | Checklist model |
| [models/checklistItems.js](../../../models/checklistItems.js) | ChecklistItem model |
| [models/users.js](../../../models/users.js) | User model with per-user settings |

---

## Glossary

| Term | Definition |
|------|-----------|
| **Per-Board** | Stored in swimlane/list/card document, visible to all users |
| **Per-User** | Stored in user profile/cookie, visible only to that user |
| **Sort** | Decimal number determining visual order of entity |
| **Height** | Pixel measurement of swimlane vertical size |
| **Width** | Pixel measurement of list horizontal size |
| **Collapse** | Hiding swimlane/list/card from view (per-user preference) |
| **Position** | Combination of swimlaneId/listId and sort value |

---

## Change Log

| Date | Change | Impact |
|------|--------|--------|
| 2025-12-23 | Created comprehensive architecture document | Documentation |
| 2025-12-23 | Added height field to Swimlanes | Per-board storage |
| 2025-12-23 | Added width field to Lists | Per-board storage |
| 2025-12-23 | Defined per-user data as collapse + label visibility | Architecture |

---

**Status**: ✅ Complete and Current  
**Next Review**: Upon next architectural change

