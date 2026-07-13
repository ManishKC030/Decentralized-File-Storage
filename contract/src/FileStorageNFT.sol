// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract FileStorageNFT is ERC721 {
    uint256 public tokenCounter;

    constructor() ERC721("FileStorageNFT", "FSNFT") {}

    error EmptyCID();
    error EmptyFileName();
    error FileAlreadyUploaded();
    error FileDoesNotExist();

    struct FileData {
        string cid;
        string fileName;
        address uploader;
        uint256 timestamp;
    }

    mapping(uint256 => FileData) private files;
    mapping(string => bool) private uploadedCID;

    event FileUploaded(
        uint256 indexed tokenId,
        address indexed uploader,
        string cid,
        string fileName
    );

    function uploadFile(
        string calldata _cid,
        string calldata _fileName
    ) external returns (uint256 tokenId) {
        if (bytes(_cid).length == 0) revert EmptyCID();

        if (bytes(_fileName).length == 0) revert EmptyFileName();

        if (uploadedCID[_cid]) revert FileAlreadyUploaded();

        tokenId = tokenCounter;

        _safeMint(msg.sender, tokenId);

        files[tokenId] = FileData({
            cid: _cid,
            fileName: _fileName,
            uploader: msg.sender,
            timestamp: block.timestamp
        });

        uploadedCID[_cid] = true;

        emit FileUploaded(
            tokenId,
            msg.sender,
            _cid,
            _fileName
        );

        unchecked {
            ++tokenCounter;
        }
    }

    function getFile(
        uint256 tokenId
    ) external view returns (FileData memory) {
        if (_ownerOf(tokenId) == address(0))
            revert FileDoesNotExist();

        return files[tokenId];
    }

    function isOwner(
        uint256 tokenId,
        address user
    ) external view returns (bool) {
        return ownerOf(tokenId) == user;
    }

    function isCIDUploaded(
        string calldata cid
    ) external view returns (bool) {
        return uploadedCID[cid];
    }
}