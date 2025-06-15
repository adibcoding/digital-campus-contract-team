// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CampusID
 * @dev NFT-based campus identity card
 * Features:
 * - Contains student & professor metadata.
 * - Non-transferable (soulbound).
 */
contract CampusID is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    enum Roles {
        Student,
        Professor
    }

    uint256 private _nextTokenId;

    /**
     * @dev Campus actors metadata.
     */
    struct VibeCampusActor {
        string id;
        string name;
        uint256 joinDate;
        Roles role;
    }

    // Mappings.
    mapping(uint256 => VibeCampusActor) public actor;
    mapping(string => uint256) public idToTokenId;
    mapping(address => uint256) public addressToTokenId;

    // Events.
    event ActorIdIssued(
        uint256 indexed tokenId,
        string id,
        address actor,
        uint256 joinDate
    );

    constructor()
        ERC721("Vibe Campus Identity Card", "VIBCID")
        Ownable(msg.sender)
    {}

    /**
     * @dev Override _update function to make non-transferable.
     * Use case: Make soulbound (non-transferable).
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);
        require(
            from == address(0) || to == address(0),
            "VIBSID is non-transferable"
        );
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Override: tokenURI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Override: supportsInterface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Issue new student ID.
     * Use case: New student sign up.
     */
    function issueStudentID(
        address _to,
        string memory _id,
        string memory _name,
        string memory _uri
    ) external {
        require(idToTokenId[_id] == 0, "Student ID already registered.");
        require(
            addressToTokenId[_to] == 0,
            "Student address already have Token ID."
        );

        // New Token ID generation & expiry date calculation.
        uint256 tokenId = _nextTokenId++;
        uint256 joinDate = block.timestamp;

        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);

        actor[tokenId] = VibeCampusActor({
            id: _id,
            name: _name,
            joinDate: joinDate,
            role: Roles.Student
        });

        idToTokenId[_id] = tokenId;
        emit ActorIdIssued(tokenId, _id, _to, joinDate);
    }

    /**
     * @dev Issue new professor ID.
     * Use case: New professor sign up.
     */
    function issueProfessorID(
        address _to,
        string memory _id,
        string memory _name,
        string memory _uri
    ) external {
        require(idToTokenId[_id] == 0, "Professor ID already registered.");
        require(
            addressToTokenId[_to] == 0,
            "Professor address already have Token ID."
        );

        // New Token ID generation & expiry date calculation.
        uint256 tokenId = _nextTokenId++;
        uint256 joinDate = block.timestamp;

        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);

        actor[tokenId] = VibeCampusActor({
            id: _id,
            name: _name,
            joinDate: joinDate,
            role: Roles.Professor
        });

        idToTokenId[_id] = tokenId;
        emit ActorIdIssued(tokenId, _id, _to, joinDate);
    }

    /**
     * @dev Get student/professor info by id.
     */
    function getActorById(string memory _id)
        external
        view
        returns (
            address owner,
            uint256 tokenId,
            VibeCampusActor memory data
        )
    {
        return (
            _ownerOf(idToTokenId[_id]),
            idToTokenId[_id],
            actor[idToTokenId[_id]]
        );
    }
}
