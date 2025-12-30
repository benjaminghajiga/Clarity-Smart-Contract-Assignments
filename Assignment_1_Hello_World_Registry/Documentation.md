# Assignment 1: Hello World Registry

## Student Information
- Name: [Benjamin Ghajiga]
- Date: [December 29 2025]

## Contract Overview
The Hello World Registry is a simple smart contract that allows users to store, retrieve, and delete personalized greeting messages on the Stacks blockchain. Each user is identified by their principal address and can manage their own message independently. Messages are stored in a map data structure with a maximum length of 500 UTF-8 characters.

## Assumptions Made
- Messages must be non-empty strings to be stored
- Each user can only have one active message at a time (setting a new message overwrites the old one)
- Once a message is deleted, it cannot be recovered
- Message length is limited to 500 UTF-8 characters
- Users can only delete their own messages (enforced by using tx-sender)
- Reading messages is public - anyone can view any user's message

## Design Decisions and Tradeoffs

### Decision 1: Using string-utf8 instead of string-ascii
- **What I chose:** Used `(string-utf8 500)` for message storage
- **Why:** UTF-8 supports international characters and emojis, making the registry more accessible globally
- **Tradeoff:** UTF-8 strings consume more storage space than ASCII strings, but provide better user experience for non-English speakers

### Decision 2: Simple validation with length check
- **What I chose:** Validated empty messages using `(> (len message) u0)`
- **Why:** Prevents users from storing meaningless empty entries in the registry
- **Tradeoff:** This is a simple check that doesn't validate message quality or content, but keeps the contract simple and gas-efficient

### Decision 3: No message existence check in delete-message
- **What I chose:** Allow deletion to succeed even if no message exists
- **Why:** Simplifies the contract and makes the function idempotent (calling it multiple times has the same effect)
- **Tradeoff:** Users won't receive explicit feedback if they try to delete a non-existent message, but this avoids unnecessary error handling

### Decision 4: Separate get-message and get-my-message functions
- **What I chose:** Created two separate read-only functions instead of one
- **Why:** Improves user experience by providing a convenient shorthand for getting your own message
- **Tradeoff:** Slight code duplication, but significantly better UX and clearer contract interface

## How to Use This Contract

### Function: set-message
- **Purpose:** Store or update a personalized greeting message for the caller
- **Parameters:** 
  - `message`: A UTF-8 string up to 500 characters containing the greeting
- **Returns:** `(ok true)` on success, `(err u100)` if message is empty
- **Example:**
```clarity
(contract-call? .hello-world-registry set-message u"Hello, Stacks community!")
```

### Function: get-message
- **Purpose:** Retrieve the greeting message for any user
- **Parameters:** 
  - `user`: The principal address of the user whose message you want to retrieve
- **Returns:** `(some "message")` if the user has set a message, `none` otherwise
- **Example:**
```clarity
(contract-call? .hello-world-registry get-message 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Function: get-my-message
- **Purpose:** Retrieve the caller's own greeting message
- **Parameters:** None
- **Returns:** `(some "message")` if caller has set a message, `none` otherwise
- **Example:**
```clarity
(contract-call? .hello-world-registry get-my-message)
```

### Function: delete-message
- **Purpose:** Delete the caller's greeting message from the registry
- **Parameters:** None
- **Returns:** `(ok true)` on success
- **Example:**
```clarity
(contract-call? .hello-world-registry delete-message)
```

## Known Limitations
- Maximum message length is limited to 500 characters
- No message history - updating a message permanently overwrites the previous one
- No moderation system - users can set any message content within the character limit
- No way to list all users who have set messages
- Cannot retrieve deleted messages
- No access control - all messages are publicly readable

## Future Improvements
- Add a message history feature to track previous versions
- Implement a character counter or preview function
- Add timestamp tracking to show when messages were last updated
- Create a message feed to list recent updates from all users
- Add optional privacy settings (private vs public messages)
- Implement message reactions or likes from other users
- Add batch operations to retrieve multiple messages efficiently
- Create events/logging for message updates for better dapp integration

## Testing Notes
- Tested using Clarinet console with multiple simulated principals
- Verified all four main functions work correctly (set, get, get-my, delete)
- Confirmed empty message validation returns correct error code (u100)
- Tested message updates properly overwrite previous messages
- Verified get-message returns `none` for users who haven't set messages
- Tested delete-message successfully removes entries from the map
- Confirmed UTF-8 character support works with emojis and international characters
- Validated cross-user functionality where User A can read User B's message