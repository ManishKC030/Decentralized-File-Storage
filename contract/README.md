## FileStorageNFT

`FileStorageNFT` is a Foundry smart contract project for representing uploaded files as ERC-721 NFTs. The file bytes are expected to live off-chain, such as in IPFS, while the contract stores a content identifier and basic upload metadata on-chain.

## Contract Behavior

`src/FileStorageNFT.sol` inherits two OpenZeppelin contracts:

- `ERC721`, which gives each uploaded file a unique transferable NFT token.
- `Ownable`, which records the deployer as the contract owner.

The imports use project-relative Foundry paths:

```solidity
import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
```

These paths resolve against the local `lib` folder configured in `foundry.toml`. They should not start with `/`, because `/lib/...` points to the root of the machine instead of this project.

## Upload Flow

Calling `uploadFile(cid, fileName)`:

1. Uses the current `tokenCounter` as the next token ID.
2. Mints that ERC-721 token to `msg.sender`.
3. Stores the file CID, original file name, uploader address, and block timestamp.
4. Emits `FileUploaded`.
5. Increments `tokenCounter`.

Use `getFile(tokenId)` to read the saved metadata and `isOwner(tokenId, user)` to check whether an address owns a file NFT.

## Commands

```shell
forge build
forge test
forge fmt
```

Run these commands from the `storage_forge` directory.
