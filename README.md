# Clarity Smart Contract Assignments - Starter Code Templates

## Submission Guidelines

### Repository Setup

**Students must fork the starter repository and complete assignments in their fork.**

#### Repository Structure

Your forked repository should maintain this structure:

```
clarity-smart-contract-assignments/
│
├── README.md (update with your name and progress)
│
├── Assignment_1_Hello_World_Registry/
│   ├── contract_code.clar
│   ├── Documentation.md
│   └── README.md
│
├── Assignment_2_Voting_System/
│   ├── contract_code.clar
│   ├── Documentation.md
│   └── README.md
│
├── Assignment_3_Timelock_Wallet/
│   ├── contract_code.clar
│   ├── Documentation.md
│   └── README.md
│
├── Assignment_4_Escrow_Contract/
│   ├── contract_code.clar
│   ├── Documentation.md
│   └── README.md
│
└── Assignment_5_NFT_Marketplace/
    ├── contract_code.clar
    ├── Documentation.md
    └── README.md
```

### Submission Process

1. **Fork** the starter repository provided by your instructor
2. **Clone** your forked repository to your local machine:
   ```bash
   https://github.com/Codewithshagbaor/Clarity-Smart-Contract-Assignments.git
   https://github.com/benjaminghajiga/Clarity-Smart-Contract-Assignments.git
   ```

3. **Update** the main README.md (This) with your information:
   ```markdown
   # Clarity Smart Contract Assignments
   
   **Student Name:** Benjamin Ghajiga
   **Cohort:** Cohort 1
   **Submission Date:** 30-12-2025
   
   ## Progress Tracker
   - [x] Assignment 1: Hello World Registry
   - [x] Assignment 2: Voting System
   - [x] Assignment 3: Timelock Wallet
   - [x] Assignment 4: Escrow Contract
   - [x] Assignment 5: NFT Marketplace
   ```

4. **Complete** each assignment in its respective folder:
   - Write your contract code in `contract_code.clar`
   - Document your work in `Documentation.md`

5. **Commit** your work regularly with meaningful messages:
   ```bash
   git add Assignment_1_Hello_World_Registry/
   git commit -m "Complete Assignment 1: Hello World Registry"
   git push origin main
   ```

6. **Submit** by providing your repository URL when all assignments are complete

### File Requirements

**1. contract_code.clar**
- Must be a valid Clarity contract file
- Can be developed in the Clarity playground, then copied to repository
- Must include all required functions
- Should be properly commented

**2. Documentation.md**
- Must be in Markdown format
- Should include the following sections:

```markdown
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

### Git Best Practices

- **Commit often**: Don't wait until all assignments are done
- **Write clear commit messages**: Describe what you changed and why
- **One assignment per commit**: Makes it easier to track progress
- **Don't commit sensitive data**: No private keys or personal information
- **Keep your fork updated**: Pull any updates from the original repository if needed

### Important Notes

- ✅ Fork the starter repository before beginning work
- ✅ Maintain the exact folder structure provided
- ✅ Commit your work regularly with clear messages
- ✅ You can develop in the playground, but code must be in the repository
- ✅ Documentation must explain your design choices, not just describe functions
- ✅ Update the main README.md with your progress
- ✅ Submit your repository URL when ready for grading
- ❌ Do not modify the folder names
- ❌ Do not delete or rename provided files
- ❌ Do not commit compiled files or deployment artifacts
- ❌ Do not wait until the last minute to commit everything

### Final Submission

When all assignments are complete:

1. **Verify** all files are committed and pushed to GitHub
2. **Double-check** that your repository is public (or accessible to instructor)
3. **Test** that your repository URL works in an incognito/private browser window
4. **Submit** your repository URL in the format:
   ```
   https://github.com/YOUR_USERNAME/clarity-smart-contract-assignments
   ```
5. Submission link will be provider in the group chat.
---

## Example Completed Documentation (check Assignment 1)

## Assignment Overview

### Assignment 1: Hello World Registry
A simple registry where users can store and retrieve personalized messages.

**Key Concepts:** Maps, principals, basic storage

### Assignment 2: Voting System
Create proposals and vote on them with one vote per user.

**Key Concepts:** Complex data structures, authorization, preventing double-voting

### Assignment 3: Timelock Wallet
Lock STX tokens that can only be withdrawn after a specified time.

**Key Concepts:** STX transfers, block-height conditions, time-based logic

### Assignment 4: Escrow Contract
Two-party escrow where buyer deposits and can release to seller or get refund.

**Key Concepts:** Multi-party authorization, state machines, financial flows

### Assignment 5: NFT Marketplace
List, buy, and manage NFT sales with marketplace fees.

**Key Concepts:** NFT traits, complex transactions, fee mechanics, custody

## Resources

- [Clarity Language Reference](https://docs.stacks.co/clarity)
- [Clarity Playground](https://platform.hiro.so/projects)
- [SIP-009 NFT Standard](https://github.com/stacksgov/sips)
- [Stacks Documentation](https://docs.stacks.co)

## Grading Criteria

- **Functionality** (40%): Does the contract work as specified?
- **Code Quality** (25%): Is the code clean, well-organized, and properly commented?
- **Security** (20%): Are edge cases handled? No obvious vulnerabilities?
- **Testing** (15%): Are test cases comprehensive and well-documented?

Good luck with your assignments! 🚀
