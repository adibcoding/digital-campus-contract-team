// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title CourseBadge
 * @dev Multi-token untuk berbagai badges dan certificates
 * Token types:
 * - Course completion certificates (non-fungible)
 * - Event attendance badges (fungible)
 * - Achievement medals (limited supply)
 * - Workshop participation tokens
 */
contract VoucherIncentive is ERC1155, AccessControl, Pausable {
    // Role definitions
    bytes32 public constant PROFESSOR_ROLE = keccak256("PROFESSOR_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");


    // Token ID ranges untuk organization
    uint256 public constant VOUCHER_BASE = 100;
    
    // Token metadata structure
    struct Voucher {
        uint256 id;
        uint256 discount;
        bool isValid;
        uint256 use;
    }

    struct Student {
        string name;
        uint256[] completeCourse;
        string[] grade;
        bool haveVoucher;
    }
    
    // TODO: Add mappings
    mapping(address => Voucher) public voucherInfo;
    mapping(address => Student) private student;
    mapping(address => uint256) private completeCourseTimestamp;
    mapping(address => uint256[]) public trackVoucherStudent;
    mapping(uint256 => string) private _tokenURIs;
    uint256[] public voucherIds;
    
    // Track student achievements
    mapping(address => uint256[]) public studentBadges;
    mapping(uint256 => mapping(address => uint256)) public earnedAt; // Timestamp
    
    // Counter untuk generate unique IDs
    uint256 private _voucherCounter;

    constructor(address professor, address studentAdd) ERC1155("") {
        // TODO: Setup roles
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(PROFESSOR_ROLE, professor);
        _grantRole(STUDENT_ROLE, studentAdd);
    }

    function giveIncentive(address studentAdd, uint256 toUse, string memory newuri) public onlyRole(PROFESSOR_ROLE) returns(bytes32) {
        require(student[studentAdd].completeCourse.length >= 5, "STUDENT MASIH BELUM BANYAK SELESAIN COURSE");
            uint256 voucherId = VOUCHER_BASE + _voucherCounter++;
            voucherIds.push(voucherId);
        for(uint i = 0; i < student[studentAdd].grade.length; i++) {
            require(bytes(student[studentAdd].grade[i]).length == bytes("A").length, "NILAI STUDENT BELUM MENCUKUPI");
            voucherInfo[studentAdd] = Voucher({
                id: voucherId,
                discount: VOUCHER_BASE,
                isValid: true,
                use: toUse
            });
            trackVoucherStudent[studentAdd].push(voucherId);
            _mint(studentAdd, voucherId, toUse, abi.encodePacked(studentAdd, toUse, voucherId));
            setTokenURI(voucherId, newuri);
        }

        return keccak256(abi.encodePacked(studentAdd, toUse, voucherId));
    }

    function applyVoucher(address studentAdd, uint256 voucherId) public onlyRole(STUDENT_ROLE) {
        require(voucherInfo[studentAdd].isValid == true && voucherInfo[studentAdd].use > 0, "VOUCHER SUDAH TERPAKAI ATAU TIDAK VALID");
        voucherInfo[studentAdd].use--;
        if(voucherInfo[studentAdd].use == 0) {
            voucherInfo[studentAdd].isValid = false;
            _burn(studentAdd, voucherIds[voucherId], 1);
        }
    }

    function setTokenURI(uint256 voucherId, string memory newuri) 
        public onlyRole(PROFESSOR_ROLE) 
    {
        _tokenURIs[voucherId] = newuri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}