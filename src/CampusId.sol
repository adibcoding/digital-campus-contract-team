// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./CampusToken.sol";

/**
 * @title CampusID
 * @dev NFT-based campus identity card
 * Features:
 * - Contains student & professor metadata.
 * - Non-transferable (soulbound).
 */
contract CampusID is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl {
    CampusToken public campusToken;

    address public admin;
    uint256 private _nextTokenId;

    // Role Definitions
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");
    bytes32 public constant PROFESSOR_ROLE = keccak256("PROFESSOR_ROLE");

    // Airdrop constant
    uint256 public constant AIRDROP_AMOUNT = 10000;

    enum Roles {
        Student,
        Professor
    }

    enum ProfessorApprovals {
        Idle,
        Requested,
        Approved
    }

    /**
     * @dev Campus actors metadata.
     */
    struct VibeCampusActor {
        string name;
        uint256 joinDate;
        Roles role;
    }

    // Mappings.
    mapping(uint256 => VibeCampusActor) public actor;
    mapping(address => uint256) public addressToTokenId;

    mapping(address => VibeCampusActor) pendingProfessor;
    mapping(address => string) pendingProfessorURI;
    mapping(address => ProfessorApprovals) public professorApprovals;

    // Events.
    event ProfessorRoleRequested(address actor);
    event ProfessorRoleApproved(address actor);
    event ActorIdIssued(
        uint256 indexed tokenId,
        address actor,
        uint256 joinDate
    );

    constructor(address campusTokenAdd) ERC721("Vibe Campus Identity Card", "VIBCID") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        admin = msg.sender;
        campusToken = CampusToken(campusTokenAdd);
    }

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
        override(ERC721, ERC721URIStorage, AccessControl)
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
        string memory _name,
        string memory _uri
    ) external {
        require(
            addressToTokenId[_to] == 0,
            "Student address already have Token ID."
        );

        // New Token ID generation & join date calculation.
        uint256 tokenId = _nextTokenId++;
        uint256 joinDate = block.timestamp;

        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        campusToken.mintVibeToken(_to, AIRDROP_AMOUNT);

        actor[tokenId] = VibeCampusActor({
            name: _name,
            joinDate: joinDate,
            role: Roles.Student
        });

        addressToTokenId[_to] = tokenId;
        _grantRole(STUDENT_ROLE, _to);

        emit ActorIdIssued(tokenId, _to, joinDate);
    }

    /**
     * @dev Request new professor ID.
     * Use case: New professor request.
     */
    function requestProfessorID(
        address _to,
        string memory _name,
        string memory _uri
    ) external {
        require(
            professorApprovals[_to] == ProfessorApprovals.Idle,
            "Request waiting for approval or has been approved."
        );

        professorApprovals[_to] = ProfessorApprovals.Requested;
        pendingProfessorURI[_to] = _uri;
        pendingProfessor[_to] = VibeCampusActor({
            name: _name,
            joinDate: block.timestamp,
            role: Roles.Professor
        });

        emit ProfessorRoleRequested(_to);
    }

    /**
     * @dev Approve new requested professor ID.
     * Use case: New professor sign up.
     */
    function approveProfessorID(address _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            addressToTokenId[_to] == 0,
            "Professor address already have Token ID."
        );

        // New Token ID generation.
        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, pendingProfessorURI[_to]);
        campusToken.mintVibeToken(_to, AIRDROP_AMOUNT);

        addressToTokenId[_to] = tokenId;
        _grantRole(PROFESSOR_ROLE, _to);

        emit ProfessorRoleApproved(_to);
        emit ActorIdIssued(tokenId, _to, pendingProfessor[_to].joinDate);
    }

    /**
     * @dev Get student/professor info by address.
     */
    function getActorByAddress(address _address)
        external
        view
        returns (
            address owner,
            uint256 tokenId,
            VibeCampusActor memory data,
            string memory uri
        )
    {
        return (
            _ownerOf(addressToTokenId[_address]),
            addressToTokenId[_address],
            actor[addressToTokenId[_address]],
            tokenURI(tokenId)
        );
    }
}
