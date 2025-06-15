// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CampusID
 * @dev NFT-based campus identity card
 * Features:
 * - Contains student & professor metadata.
 * - Non-transferable (soulbound).
 */
contract CampusID is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl {
    uint256 private _nextTokenId;
    address public admin;

    // Role Definitions
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");
    bytes32 public constant PROFESSOR_ROLE = keccak256("PROFESSOR_ROLE");

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
        string id;
        string name;
        uint256 joinDate;
        Roles role;
    }

    // Mappings.
    mapping(uint256 => VibeCampusActor) public actor;
    mapping(string => uint256) public idToTokenId;
    mapping(address => uint256) public addressToTokenId;

    mapping(address => VibeCampusActor) pendingProfessor;
    mapping(address => string) pendingProfessorURI;
    mapping(address => ProfessorApprovals) public professorApprovals;

    // 0
    // request => 1,2 reject
    // request => it's 0, make it 1
    // approve => make it 2

    // Events.
    event ProfessorRoleRequested();
    event ProfessorRoleApproved();
    event ActorIdIssued(
        uint256 indexed tokenId,
        string id,
        address actor,
        uint256 joinDate
    );

    constructor() ERC721("Vibe Campus Identity Card", "VIBCID") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        admin = msg.sender;
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

        _grantRole(STUDENT_ROLE, _to);
        emit ActorIdIssued(tokenId, _id, _to, joinDate);
    }

    /**
     * @dev Request new professor ID.
     * Use case: New professor request.
     */
    function requestProfessorID(
        address _to,
        string memory _id,
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
            id: _id,
            name: _name,
            joinDate: block.timestamp,
            role: Roles.Professor
        });
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
            idToTokenId[pendingProfessor[_to].id] == 0,
            "Professor ID already registered."
        );
        require(
            addressToTokenId[_to] == 0,
            "Professor address already have Token ID."
        );

        // New Token ID generation.
        uint256 tokenId = _nextTokenId++;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, pendingProfessorURI[_to]);
        idToTokenId[pendingProfessor[_to].id] = tokenId;

        _grantRole(PROFESSOR_ROLE, _to);
        emit ActorIdIssued(
            tokenId,
            pendingProfessor[_to].id,
            _to,
            pendingProfessor[_to].joinDate
        );
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
            VibeCampusActor memory data,
            string memory uri
        )
    {
        return (
            _ownerOf(idToTokenId[_id]),
            idToTokenId[_id],
            actor[idToTokenId[_id]],
            tokenURI(tokenId)
        );
    }
}
