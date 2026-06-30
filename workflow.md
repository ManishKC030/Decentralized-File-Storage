# Decentralized File Storage — Project Workflow & Architecture

> A full-stack dApp that lets users upload files to IPFS and mint an ERC-721 NFT as a permanent on-chain certificate of ownership. The file bytes live off-chain (IPFS via Pinata), while the smart contract stores the IPFS CID, file name, uploader address, and timestamp.

---

## 1. Project Overview

| Layer | Technology | Purpose |
|-------|------------|---------|
| Smart Contract | Solidity + Foundry | Owns the canonical file registry and mints NFTs |
| Frontend | React 19 + Vite + Tailwind CSS + ethers.js | Wallet connection, file upload UI, blockchain reads/writes |
| Off-chain Storage | IPFS via Pinata | Stores the actual file bytes |
| Network | Ethereum Sepolia (chainId `11155111`) | Current testnet deployment |

### Deployed Contract

- **Contract Address:** `Your Contract address after deployment`
- **Network:** Sepolia Testnet
- **Deployer:** `0x27e71efeebc06fd5271329326977115f8624899e`
- **Deployment Tx:** `0xc2b69b48f53d5e8b0fba19f9585168d2b839e41329e51fe47ec8ba015974cc4f`

---

## 2. Repository Structure

```
Decentralized-File-Storage/
├── frontend/                          # React Vite application
│   ├── src/
│   │   ├── App.jsx                    # Main UI + all business logic
│   │   ├── main.jsx                   # React root renderer
│   │   ├── index.css                  # Tailwind import
│   │   └── abi/
│   │       └── FileStorageNFT.json    # Contract ABI + bytecode
│   ├── package.json
│   ├── vite.config.js
│   └── index.html
│
├── storage_forge/                     # Foundry Solidity project
│   ├── src/
│   │   └── FileStorageNFT.sol         # Core smart contract
│   ├── script/
│   │   └── DeployFileStorage.s.sol    # Deployment script
│   ├── test/
│   │   └── FileStorageNFT.t.sol       # Foundry tests
│   ├── foundry.toml
│   └── broadcast/                     # Deployment broadcast logs
│       └── DeployFileStorage.s.sol/
│           └── 11155111/
│               └── run-latest.json
│
└── workflow.md                        # This file
```

---

## 3. Smart Contract Layer

### File: `storage_forge/src/FileStorageNFT.sol`

The contract inherits from OpenZeppelin's battle-tested libraries:

- `ERC721` — standard non-fungible token behavior (ownership, transfers, approvals).
- `Ownable` — records the deployer as the contract owner (currently only used for the standard ownership pattern, not for file-level access control).

### State Variables

| Name | Type | Purpose |
|------|------|---------|
| `tokenCounter` | `uint256` | Monotonically increasing ID for the next uploaded file |
| `files` | `mapping(uint256 => FileData)` | On-chain metadata vault keyed by `tokenId` |

### Struct: `FileData`

```solidity
struct FileData {
    string cid;        // IPFS content identifier
    string fileName;   // Original file name
    address uploader;  // Wallet that uploaded the file
    uint256 timestamp; // block.timestamp at mint
}
```

### Events

| Event | Purpose |
|-------|---------|
| `FileUploaded(uint256 indexed tokenId, address indexed uploader, string cid, string fileName)` | Emitted every time a new file is minted. Indexed fields make it cheap to query uploads by user or tokenId. |
| `Approval` / `ApprovalForAll` / `Transfer` / `OwnershipTransferred` | Inherited from OpenZeppelin ERC721 and Ownable. |

### Core Functions

#### `uploadFile(string _cid, string _fileName) → uint256`

**Flow:**

1. Reads the current `tokenCounter` as the new `tokenId`.
2. Calls `_safeMint(msg.sender, tokenId)` to mint an ERC-721 token.
3. Writes a `FileData` struct into the `files` mapping.
4. Emits `FileUploaded`.
5. Increments `tokenCounter`.
6. Returns the minted `tokenId`.

**Who calls it:** The React frontend after uploading the file to Pinata/IPFS.

#### `getFile(uint256 tokenId) → FileData`

Returns the stored metadata for a given file. Used by the frontend to render the vault list.

#### `isOwner(uint256 tokenId, address user) → bool`

Convenience wrapper around `ownerOf(tokenId) == user`. Useful for UI gating or third-party verification.

### Inherited ERC721 Functions Available

| Function | Purpose |
|----------|---------|
| `ownerOf(uint256 tokenId)` | Current owner of a file NFT |
| `balanceOf(address owner)` | How many file NFTs a user owns |
| `transferFrom` / `safeTransferFrom` | Transfer ownership of a file NFT |
| `approve` / `setApprovalForAll` | Delegate transfer rights |
| `tokenURI(uint256 tokenId)` | Metadata URI (default empty — upgrade opportunity) |

### Deployment Script

**File:** `storage_forge/script/DeployFileStorage.s.sol`

```solidity
contract DeployFileStorage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        FileStorageNFT fileStorage = new FileStorageNFT();
        vm.stopBroadcast();
    }
}
```

Run from `storage_forge/`:

```bash
source .env
forge script script/DeployFileStorage.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Tests

**File:** `storage_forge/test/FileStorageNFT.t.sol`

| Test | What it checks |
|------|----------------|
| `test_UploadFile` | Correct tokenId, counter increment, ownership, stored metadata, timestamp, and `isOwner` |
| `test_MultipleUploads` | Multiple users can upload and receive sequential tokenIds |

Run tests:

```bash
cd storage_forge
forge test
```

---

## 4. Frontend Layer

### File: `frontend/src/App.jsx`

This is a single-file React application that handles wallet connection, IPFS upload, and blockchain interaction.

### Environment Variables (required)

Create `frontend/.env`:

```bash
VITE_CONTRACT_ADDRESS=0xe0900aef8b1125fc29f4ce3bf490446eb83e928d
VITE_PINATA_JWT=your_pinata_jwt_here
```

> `frontend/.gitignore` already excludes `.env` so secrets are not committed.

### Important React Functions

#### `connectWallet()`

- Checks for `window.ethereum` (MetaMask or any injected wallet).
- Requests account access via `eth_requestAccounts`.
- Stores the connected address in React state.

#### `getContract(signerOrProvider)`

- Creates an `ethers.Contract` instance using the imported ABI and `VITE_CONTRACT_ADDRESS`.
- Used for both read-only calls (provider) and state-changing calls (signer).

#### `loadFiles()`

- Called automatically after wallet connection and after every successful upload.
- Reads `tokenCounter()` from the contract.
- Loops `0 → tokenCounter - 1` and calls `getFile(i)` for each tokenId.
- Builds an array of file objects and reverses it (newest first).
- Gracefully skips entries that fail (e.g., burned tokens or out-of-range reads).

#### `handleFileChange(e)`

- Captures the selected file from the native file input.
- Auto-fills the `fileName` state with the original file name.

#### `uploadToPinata()`

- Validates that `VITE_PINATA_JWT` is configured.
- Builds a `FormData` payload with the selected file.
- POSTs to `https://api.pinata.cloud/pinning/pinFileToIPFS`.
- Returns `res.data.IpfsHash` (the CID).

#### `handleForge()`

The main user-facing flow:

1. Validates a file is selected.
2. Calls `uploadToPinata()` to push the file to IPFS.
3. Gets a signer from the browser wallet.
4. Calls `contract.uploadFile(cid, fileName)`.
5. Waits for `tx.wait()` confirmation.
6. Refreshes the vault list via `loadFiles()`.

### UI Sections

| Section | Description |
|---------|-------------|
| Header | Branding + Connect Wallet / connected account display |
| Forge New Asset | File drop zone, optional name input, and mint button |
| Vault Contents | Paginated-style list of all minted files with "Open IPFS" links |

---

## 5. End-to-End Workflow

```
┌─────────────┐      ┌─────────────────┐      ┌──────────────────────┐
│   User      │      │  React Frontend │      │  Pinata / IPFS       │
│  Selects    │ ───> │  uploadToPinata │ ───> │  pinFileToIPFS       │
│   File      │      │                 │      │  returns CID         │
└─────────────┘      └─────────────────┘      └──────────────────────┘
                              │
                              │ CID + fileName
                              ▼
                       ┌──────────────────────┐
                       │ FileStorageNFT       │
                       │ uploadFile(cid,name) │
                       │ mints ERC-721        │
                       └──────────────────────┘
                              │
                              │ event FileUploaded
                              ▼
                       ┌──────────────────────┐
                       │ Frontend loadFiles   │
                       │ renders vault list   │
                       └──────────────────────┘
```

### Data Flow Summary

1. **Off-chain:** File bytes → Pinata → IPFS → CID.
2. **On-chain:** CID + metadata → `uploadFile()` → NFT mint + `FileData` struct.
3. **Read:** Frontend calls `tokenCounter()` and `getFile(i)` to rebuild the public file registry.

---

## 6. Important Functions Reference

### Smart Contract

| Function | Visibility | Mutability | Description |
|----------|------------|------------|-------------|
| `uploadFile(string, string)` | `public` | non-payable | Mints NFT and stores file metadata |
| `getFile(uint256)` | `public` | `view` | Returns `FileData` for a tokenId |
| `isOwner(uint256, address)` | `public` | `view` | Checks NFT ownership |
| `files(uint256)` | `public` | `view` | Direct mapping accessor |
| `tokenCounter()` | `public` | `view` | Total number of mints |

### Frontend

| Function | Responsibility |
|----------|----------------|
| `connectWallet()` | MetaMask connection |
| `getContract()` | Ethers contract instance factory |
| `loadFiles()` | Fetch all file metadata from chain |
| `uploadToPinata()` | Push file to IPFS |
| `handleForge()` | Orchestrate upload + mint + refresh |
| `handleFileChange()` | Capture native file input |

---

## 7. Possible Upgrades & Improvements

### A. On-Chain Metadata & NFT Usability

- **Dynamic `tokenURI`:** Override `tokenURI()` to return a JSON metadata URI (e.g., `ipfs://...` or an on-chain data URI) so marketplaces can display the file.
- **File type / size / checksum:** Add `fileType`, `fileSize`, and `sha256` fields to `FileData` for integrity verification and richer metadata.
- **Enumerable tokens:** Use `ERC721Enumerable` so users can easily list tokenIds they own without scanning the entire registry.

### B. Access Control & Privacy

- **Private files:** Add an encryption layer — encrypt files client-side before uploading to IPFS and store decryption keys only for authorized addresses.
- **Granular sharing:** Add `shareFile(tokenId, user)` mapping so non-owners can view/download without owning the NFT.
- **Revoke access:** Implement access revocation and expiring share links.

### C. Storage Efficiency & Costs

- **Indexed loop optimization:** Replace the frontend loop over `tokenCounter` with:
  - An `ERC721Enumerable` extension, or
  - A mapping `userFiles[address][]` maintained in `uploadFile()`.
- **Batch mints:** Allow users to upload multiple files in a single transaction to save gas.
- **CID validation:** Add basic CID format checks in the contract to prevent junk uploads.

### D. Reliability & UX

- **Indexed event queries:** Use `ethers.getLogs` on `FileUploaded` instead of scanning `getFile(i)` from block 0; this is faster and more decentralized-friendly.
- **IPFS gateway fallback:** Support multiple gateways (ipfs.io, dweb.link, Cloudflare) in case one is slow or blocked.
- **Upload progress:** Show Pinata upload percentage and blockchain confirmation status.
- **Error boundaries:** Add React error boundaries and toast notifications instead of `alert()`.

### E. Security

- **Reentrancy guard:** Although `_safeMint` is used, consider `ReentrancyGuard` if future extensions accept value.
- **Pausable uploads:** Use OpenZeppelin `Pausable` to halt minting in emergencies.
- **Input sanitization:** Validate `_cid` and `_fileName` lengths to avoid unexpected gas costs.

### F. Multi-Chain & DevOps

- **Hardhat + Foundry dual setup:** Currently only Foundry is used; adding Hardhat can simplify some CI/tooling workflows.
- **Deployment verification:** The broadcast log shows a Sepolia deployment; automate verification with `forge verify-contract`.
- **GitHub Actions:** The project has `.github/workflows/test.yml` in `storage_forge` — extend it to run frontend lint/build as well.

### G. Token Economics (optional)

- **Mint fee:** Charge a small ETH fee for uploads to discourage spam and fund maintenance.
- **Token-gated access:** Require holding a separate membership NFT or ERC-20 token to upload.

---

## 8. Quick Start Commands

### Smart Contract

```bash
cd storage_forge
forge build
forge test
forge fmt
```

### Frontend

```bash
cd frontend
npm install
cp .env.example .env   # or create .env manually
npm run dev
```

---

## 9. Key Takeaways

- The dApp is a **minimal but functional** decentralized file vault.
- It demonstrates the classic **"IPFS for bytes, blockchain for ownership"** pattern.
- The smart contract is intentionally simple: mint-on-upload plus a metadata mapping.
- The frontend handles the full UX loop: wallet → IPFS → mint → read-back.
- The biggest upgrade opportunities are **metadata enrichment**, **indexed per-user lookups**, **client-side encryption**, and **better event-based data fetching**.
