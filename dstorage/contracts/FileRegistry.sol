// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FileRegistry {
    struct File {
        address owner;
        string cid;             // IPFS CID
        string fileName;        // e.g. "invoice.pdf" (NEW)
        string fileType;        // e.g. "application/pdf" (NEW)
        address[] hosts;        // devices storing this file
        uint256 fileSize;       // Size in bytes (NEW)
        uint256 timestamp;
    }

    mapping(string => File) private fileMap;

    event FileRegistered(string cid, string fileName, address indexed owner);

    // Updated Register Function
    function registerFile(
        string memory _cid,
        string memory _fileName,
        string memory _fileType,
        uint256 _fileSize,
        address[] calldata _hosts
    ) external {
        require(fileMap[_cid].owner == address(0), "File already exists");

        fileMap[_cid] = File({
            owner: msg.sender,
            cid: _cid,
            fileName: _fileName,
            fileType: _fileType,
            hosts: _hosts,
            fileSize: _fileSize,
            timestamp: block.timestamp
        });

        emit FileRegistered(_cid, _fileName, msg.sender);
    }

    // Helper to get file details
    function getFile(string memory _cid)
        external
        view
        returns (
            address owner,
            string memory cid,
            string memory fileName,
            string memory fileType,
            uint256 fileSize,
            address[] memory hosts
        )
    {
        File memory f = fileMap[_cid];
        require(f.owner != address(0), "File not found");
        return (f.owner, f.cid, f.fileName, f.fileType, f.fileSize, f.hosts);
    }
}