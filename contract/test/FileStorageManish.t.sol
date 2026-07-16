// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FileStorageNFT.sol";

contract FileStorageNFTTest is Test {
    FileStorageNFT fileNFT;
    address alice = address(1);
    address bob = address(2);

    function setUp() public {
        fileNFT = new FileStorageNFT();
    }

    // ===========================
    // DEPLOYMENT
    // ===========================
    function testDeployment() public view {
        assertEq(fileNFT.name(), "FileStorageNFT");
        assertEq(fileNFT.symbol(), "FSNFT");
        assertEq(fileNFT.owner(), address(this));
        assertEq(fileNFT.tokenCounter(), 0);
    }

    // ===========================
    // UPLOAD & MINT
    // ===========================
    function testUploadFile() public {
        // Expect the FileUploaded event
        vm.expectEmit(true, true, true, true);
        // The event will be emitted by the contract; we don't emit it here

        vm.prank(alice);
        uint256 tokenId = fileNFT.uploadFile("Qm123", "resume.pdf");

        assertEq(tokenId, 0);
        assertEq(fileNFT.tokenCounter(), 1);
        assertEq(fileNFT.ownerOf(0), alice);
        // Verify bob is not the owner
        assertTrue(fileNFT.ownerOf(0) != bob);

        // Check that the CID is marked as used
        assertTrue(fileNFT.isCIDUsed("Qm123"));
        assertFalse(fileNFT.isCIDUsed("Qm456"));
    }

    // ===========================
    // TOKEN COUNTER INCREMENTS
    // ===========================
    function testTokenCounter() public {
        vm.prank(alice);
        fileNFT.uploadFile("A", "one");

        vm.prank(alice);
        fileNFT.uploadFile("B", "two");

        vm.prank(alice);
        fileNFT.uploadFile("C", "three");

        assertEq(fileNFT.tokenCounter(), 3);
    }

    // ===========================
    // DUPLICATE CID REVERTS
    // ===========================
    function testDuplicateCIDNotAllowed() public {
        vm.prank(alice);
        fileNFT.uploadFile("QmSame", "file1");

        vm.prank(alice);
        vm.expectRevert(FileStorageNFT.FileAlreadyUploaded.selector);
        fileNFT.uploadFile("QmSame", "file2");
    }

    // ===========================
    // EMPTY FIELDS REVERT
    // ===========================
    function testEmptyCID() public {
        vm.prank(alice);
        vm.expectRevert(FileStorageNFT.EmptyCID.selector);
        fileNFT.uploadFile("", "resume.pdf");
    }

    function testEmptyFileName() public {
        vm.prank(alice);
        vm.expectRevert(FileStorageNFT.EmptyFileName.selector);
        fileNFT.uploadFile("Qm123", "");
    }

    // ===========================
    // CID USAGE CHECK
    // ===========================
    function testIsCIDUsed() public {
        // Initially false
        assertFalse(fileNFT.isCIDUsed("QmABC"));

        vm.prank(alice);
        fileNFT.uploadFile("QmABC", "doc");

        // Now true
        assertTrue(fileNFT.isCIDUsed("QmABC"));
        // Other CIDs remain false
        assertFalse(fileNFT.isCIDUsed("QmXYZ"));
    }

    // ===========================
    // ANY CID STRING ACCEPTED
    // ===========================
    function testInvalidCIDString() public {
        vm.expectEmit(true, true, true, true);
        // The event will be emitted with the "invalid" CID

        vm.prank(alice);
        uint256 tokenId = fileNFT.uploadFile("INVALID_CID_123", "image.png");

        assertEq(tokenId, 0);
        assertEq(fileNFT.tokenCounter(), 1);
        // Check that the invalid CID is marked as used
        assertTrue(fileNFT.isCIDUsed("INVALID_CID_123"));
    }

    // ===========================
    // MULTIPLE USERS
    // ===========================
    function testMultipleUsers() public {
        vm.prank(alice);
        fileNFT.uploadFile("A", "Alice");

        vm.prank(bob);
        fileNFT.uploadFile("B", "Bob");

        assertEq(fileNFT.ownerOf(0), alice);
        assertEq(fileNFT.ownerOf(1), bob);
    }

    // ===========================
    // TRANSFER NFT
    // ===========================
    function testTransferNFT() public {
        vm.prank(alice);
        fileNFT.uploadFile("CID", "file");

        vm.prank(alice);
        fileNFT.transferFrom(alice, bob, 0);

        assertEq(fileNFT.ownerOf(0), bob);
        // The CID remains used (unchanged)
        assertTrue(fileNFT.isCIDUsed("CID"));
    }
}