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

    function testDeployment() public {
        assertEq(fileNFT.name(), "FileStorageNFT");
        assertEq(fileNFT.symbol(), "FSNFT");
        assertEq(fileNFT.owner(), address(this));
        assertEq(fileNFT.tokenCounter(), 0);
    }

    function testUploadFile() public {
        vm.prank(alice);

        uint256 tokenId = fileNFT.uploadFile("Qm123", "resume.pdf");

        FileStorageNFT.FileData memory file = fileNFT.getFile(tokenId);

        assertEq(file.cid, "Qm123");
        assertEq(file.fileName, "resume.pdf");
        assertEq(file.uploader, alice);

        assertEq(fileNFT.ownerOf(tokenId), alice);
        assertEq(fileNFT.tokenCounter(), 1);
    }

    function testRetrieveFile() public {
        vm.prank(alice);

        fileNFT.uploadFile("QmABC", "notes.txt");

        FileStorageNFT.FileData memory file = fileNFT.getFile(0);

        assertEq(file.cid, "QmABC");
        assertEq(file.fileName, "notes.txt");
    }

    function testTokenCounter() public {

        vm.prank(alice);
        fileNFT.uploadFile("A", "one");

        vm.prank(alice);
        fileNFT.uploadFile("B", "two");

        vm.prank(alice);
        fileNFT.uploadFile("C", "three");

        assertEq(fileNFT.tokenCounter(), 3);
    }

    function testDuplicateCIDAllowed() public {

        vm.prank(alice);
        fileNFT.uploadFile("QmSame", "file1");

        vm.prank(alice);
        fileNFT.uploadFile("QmSame", "file2");

        assertEq(fileNFT.tokenCounter(), 2);

        assertEq(fileNFT.getFile(0).cid, "QmSame");
        assertEq(fileNFT.getFile(1).cid, "QmSame");
    }

    function testNFTOwner() public {

        vm.prank(alice);
        fileNFT.uploadFile("CID", "doc");

        assertEq(fileNFT.ownerOf(0), alice);

        assertTrue(fileNFT.isOwner(0, alice));
        assertFalse(fileNFT.isOwner(0, bob));
    }

    function testEmptyCID() public {

        vm.prank(alice);

        fileNFT.uploadFile("", "resume.pdf");

        assertEq(fileNFT.getFile(0).cid, "");
    }

    function testEmptyFileName() public {

        vm.prank(alice);

        fileNFT.uploadFile("Qm123", "");

        assertEq(fileNFT.getFile(0).fileName, "");
    }

    function testInvalidCIDString() public {

        vm.prank(alice);

        fileNFT.uploadFile("INVALID_CID_123", "image.png");

        assertEq(
            fileNFT.getFile(0).cid,
            "INVALID_CID_123"
        );
    }

    function testMultipleUsers() public {

        vm.prank(alice);
        fileNFT.uploadFile("A", "Alice");

        vm.prank(bob);
        fileNFT.uploadFile("B", "Bob");

        assertEq(fileNFT.ownerOf(0), alice);
        assertEq(fileNFT.ownerOf(1), bob);
    }

    function testTransferNFT() public {

        vm.prank(alice);
        fileNFT.uploadFile("CID", "file");

        vm.prank(alice);
        fileNFT.transferFrom(alice, bob, 0);

        assertEq(fileNFT.ownerOf(0), bob);

        FileStorageNFT.FileData memory file =
            fileNFT.getFile(0);

        assertEq(file.cid, "CID");
        assertEq(file.fileName, "file");
    }
}