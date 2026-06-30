// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FileStorageNFT} from "../src/FileStorageNFT.sol";

contract FileStorageNFTBehaviorTest is Test {
    FileStorageNFT private nft;

    address private uploader = address(0xA11CE);

    event FileUploaded(uint256 indexed tokenId, address indexed uploader, string cid, string fileName);

    function setUp() public {
        nft = new FileStorageNFT();
    }

    function testConstructorSetsErc721DetailsAndOwner() public view {
        assertEq(nft.name(), "FileStorageNFT");
        assertEq(nft.symbol(), "FSNFT");
        assertEq(nft.owner(), address(this));
    }

    function testUploadFileMintsNftAndStoresMetadata() public {
        string memory cid = "ipfs://bafybeigdyrzt";
        string memory fileName = "report.pdf";

        vm.prank(uploader);
        vm.expectEmit(true, true, false, true);
        emit FileUploaded(0, uploader, cid, fileName);
        uint256 tokenId = nft.uploadFile(cid, fileName);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(tokenId), uploader);
        assertTrue(nft.isOwner(tokenId, uploader));
        assertEq(nft.tokenCounter(), 1);

        FileStorageNFT.FileData memory file = nft.getFile(tokenId);
        assertEq(file.cid, cid);
        assertEq(file.fileName, fileName);
        assertEq(file.uploader, uploader);
        assertEq(file.timestamp, block.timestamp);
    }
}
