# Assignment 2: Simple Voting System

## Student Information
- Name: Benjamin Ghajiga
- Date: 30-12-2025

## Contract Overview
The Simple Voting System is a decentralized voting contract that allows users to create proposals and vote on them in a transparent, tamper-proof manner. Each proposal has a defined voting period measured in blocks, and each user can cast exactly one vote (yes or no) per proposal. The contract prevents double-voting, tracks vote tallies in real-time, and enforces voting deadlines automatically based on block height.

## Assumptions Made
- Voting duration is specified in blocks (not time), as block height is more reliable on-chain
- Once a vote is cast, it cannot be changed or withdrawn
- Proposals cannot be deleted or modified after creation
- Voting ends at the specified block height (inclusive), meaning users can vote at the end-height block
- Anyone can create a proposal (no permission required)
- Anyone can vote on any proposal (no voting restrictions based on token holdings or other criteria)
- Vote tallies are publicly visible at all times
- Proposal IDs start at 1 and increment sequentially

## Design Decisions and Tradeoffs

### Decision 1: Using composite keys for vote tracking
- **What I chose:** Used `{proposal-id: uint, voter: principal}` as the key for the votes map
- **Why:** This creates a unique identifier for each user's vote on each proposal, allowing efficient lookup to prevent double-voting
- **Tradeoff:** Composite keys use more storage than a single key, but provide better data organization and prevent the need for nested maps. This makes queries more efficient and the contract logic simpler.

### Decision 2: Block height for voting deadlines
- **What I chose:** Used block height instead of timestamps for proposal end times
- **Why:** Block height is deterministic and cannot be manipulated, whereas timestamps can have slight variations. This provides more reliable and predictable voting periods.
- **Tradeoff:** Block height is less intuitive for users (they need to know average block time), but it's more secure and prevents timing attacks. For Stacks, blocks are approximately 10 minutes apart.

### Decision 3: Storing vote counts in proposal data
- **What I chose:** Store yes-votes and no-votes directly in the proposal map and update them on each vote
- **Why:** Provides instant access to vote tallies without needing to iterate through all votes
- **Tradeoff:** Requires updating the proposal map on every vote (more writes), but makes reading results much more efficient. Since reading happens more frequently than voting, this is a good tradeoff.

### Decision 4: Immutable votes
- **What I chose:** Once cast, votes cannot be changed or withdrawn
- **Why:** Simplifies the contract logic and prevents vote manipulation strategies where users could change votes based on current tallies
- **Tradeoff:** Less flexibility for voters who change their mind, but ensures vote integrity and prevents gaming the system. This also reduces gas costs by avoiding additional change/withdraw functions.

### Decision 5: No minimum duration validation
- **What I chose:** Allow any duration value including very short (even 1 block) or very long voting periods
- **Why:** Provides maximum flexibility for different use cases (urgent decisions vs long deliberations)
- **Tradeoff:** Could allow proposals with impractical durations, but trusts users to set reasonable values. Adding validation would restrict legitimate use cases.

## How to Use This Contract

### Function: create-proposal
- **Purpose:** Create a new voting proposal with a specified duration
- **Parameters:** 
  - `title`: A UTF-8 string up to 100 characters describing the proposal
  - `description`: A UTF-8 string up to 500 characters with detailed information
  - `duration`: Number of blocks the voting period will last (uint)
- **Returns:** `(ok proposal-id)` with the new proposal's ID on success
- **Example:**
```clarity
(contract-call? .voting-system create-proposal u"Fund Community Project" u"Proposal to allocate 10,000 STX for community development initiatives" u1000)
```

### Function: vote
- **Purpose:** Cast a vote on an active proposal
- **Parameters:** 
  - `proposal-id`: The ID of the proposal to vote on (uint)
  - `vote-for`: true to vote YES, false to vote NO (bool)
- **Returns:** `(ok true)` on success, or error codes: `(err u200)` if proposal not found, `(err u201)` if voting is closed, `(err u202)` if already voted
- **Example:**
```clarity
(contract-call? .voting-system vote u1 true)
```

### Function: get-proposal
- **Purpose:** Retrieve complete details about a proposal
- **Parameters:** 
  - `proposal-id`: The ID of the proposal to look up (uint)
- **Returns:** `(some proposal-data)` with all proposal details if found, `none` if proposal doesn't exist
- **Example:**
```clarity
(contract-call? .voting-system get-proposal u1)
```

### Function: has-voted
- **Purpose:** Check if a specific user has already voted on a proposal
- **Parameters:** 
  - `proposal-id`: The ID of the proposal (uint)
  - `user`: The principal address of the user to check
- **Returns:** `true` if the user has voted, `false` if they haven't
- **Example:**
```clarity
(contract-call? .voting-system has-voted u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Function: get-vote-totals
- **Purpose:** Get the current yes and no vote counts for a proposal
- **Parameters:** 
  - `proposal-id`: The ID of the proposal (uint)
- **Returns:** `{yes-votes: uint, no-votes: uint}` with current tallies, or `{yes-votes: u0, no-votes: u0}` if proposal doesn't exist
- **Example:**
```clarity
(contract-call? .voting-system get-vote-totals u1)
```

## Known Limitations
- No way to cancel or delete a proposal once created
- Votes cannot be changed or withdrawn after being cast
- No quorum requirements - a proposal with only one vote is treated the same as one with thousands
- No ability to delegate votes to another user
- Maximum title length is 100 characters and description is 500 characters
- No built-in mechanism to execute actions based on voting results (would need separate contract)
- Cannot retrieve a list of all proposals or iterate through them
- No voting power weighting (all votes count equally regardless of stake)
- Proposal creator has no special privileges (cannot close voting early or modify proposal)

## Future Improvements
- Add quorum requirements (minimum number of votes needed for validity)
- Implement weighted voting based on token holdings
- Add proposal categories or tags for better organization
- Create a proposal feed to list all active/past proposals
- Add ability for creator to cancel proposals before voting starts
- Implement execution logic to automatically carry out approved proposals
- Add delegation system for users to assign their voting power
- Include vote abstention as a third option beyond yes/no
- Add time-lock periods between proposal creation and voting start
- Implement proposal deposits to prevent spam
- Add comments or discussion threads for each proposal
- Create events/logging for better dapp integration and vote tracking
- Add proposal templates for common voting scenarios

## Testing Notes
- Tested using Clarinet console with multiple simulated principals
- Created multiple proposals with varying durations and verified sequential ID assignment
- Confirmed votes are correctly tallied for both yes and no options
- Verified double-voting prevention by attempting to vote twice from same principal (correctly returns ERR-ALREADY-VOTED u202)
- Tested voting period enforcement by attempting to vote after end-height (correctly returns ERR-VOTING-CLOSED u201)
- Confirmed non-existent proposal queries return ERR-NOT-FOUND (u200)
- Validated has-voted function correctly identifies voting status for different users
- Tested get-vote-totals returns accurate counts throughout voting process
- Verified proposal data persistence and retrieval with get-proposal
- Tested edge cases: voting at exactly end-height block, minimum duration (u1), very large durations
- Confirmed creator field correctly stores proposal creator's principal
- Validated that multiple users can vote on same proposal without conflicts