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
contract CourseVoucher is ERC1155, AccessControl, Pausable {
    // Role definitions
    bytes32 public constant PROFESSOR_ROLE = keccak256("PROFESSOR_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256[] public voucherIds;

    // Token ID ranges untuk organization
    uint256 public constant VOUCHER_BASE = 100;
    uint256 public constant COURSE_BASE = 10000;
    uint256 public constant CERTIFICATION_BASE = 5000;
    
    // Token metadata structure
    struct Course {
        uint256 courseId; 
        string title;
        string professor; 
        string uri; 
        uint256 courseCost; 
        uint256 enrolledStudents;
        bool isActive;
        uint256 minGradeForScholarship;
    }

    struct Certificate {
        uint256 certificateId;
        string title;
        string nameProfessor;
        string nameStudent;
        uint256 issueDate;
        string uri;
        bool isTopPerfomance;
    }

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
    mapping(address => uint256[]) public trackVoucherStudent;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => Certificate) public certificateInfo;
    mapping(address => uint256[]) public trackCertificateStudent;

    mapping(uint256 => Course) private courseInfo;    

    event CourseCreated(uint256 indexed id, string title, address professor);
    event VoucherCreated(uint256 indexed id, uint256 discount, uint256 toUse);
    event CertificateCreated(uint256 indexed id, string titleCertificate, string indexed professor, string indexed student, uint256 issueDate);
    
    
    // Counter untuk generate unique IDs
    uint256 private _voucherCounter;
    uint256 private _courseCounter;
    uint256 private _certificateCounter;

    constructor(address professor, address studentAdd) ERC1155("") {
        // TODO: Setup roles
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(PROFESSOR_ROLE, professor);
        _grantRole(STUDENT_ROLE, studentAdd);
    }

    function createCourse(
        string memory title,
        string memory newuri,
        uint256 creditCost,
        uint256 minGradeForScholarship
    ) external onlyRole(PROFESSOR_ROLE) {
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(newuri).length > 0, "URI dibutuhkan");
        require(creditCost > 0, "Credit cost must be greater than 0");

        uint256 courseId = COURSE_BASE + _courseCounter++;

        // string memory professorName = /* Ambil dari Struct Professor */

        // courseInfo[courseId] = Course({
        //     courseId: courseId,
        //     title: title,
        //     professor: /* professorName */,
        //     uri: newuri,
        //     courseCost: creditCost,
        //     enrolledStudents: 0,
        //     isActive: true,
        //     minGradeForScholarship: minGradeForScholarship
        // });
       
        _mint(msg.sender, courseId, 1, abi.encodePacked(courseId, title, newuri, creditCost, msg.sender));
        setTokenURI(courseId, newuri);

        emit CourseCreated(courseId, title, msg.sender);
    }

function completeCourse(
    address studentAdd,
    uint256 courseId, 
    string memory grade,
    string memory newuri, 
    string calldata title,
    bool isTopPerformance
) external onlyRole(PROFESSOR_ROLE) {
    require(studentAdd != address(0), "Invalid student address");
    require(bytes(newuri).length > 0, "URI cannot be empty");
    require(bytes(title).length > 0, "Title cannot be empty");
    require(hasRole(STUDENT_ROLE, studentAdd), "Address is not a student");
    require(courseInfo[courseId].isActive, "Course is not active");
    require(bytes(courseInfo[courseId].professor).length > 0, "Nama Professor Harus Ada");
    
    uint256 certificateId = CERTIFICATION_BASE + _certificateCounter++;
    
    string memory studentName = student[studentAdd].name;
    string memory professorName = courseInfo[courseId].professor; 

    // Create certificate
    certificateInfo[certificateId] = Certificate({
        certificateId: certificateId,
        title: title,
        nameProfessor: professorName ,
        nameStudent: studentName,
        issueDate: block.timestamp,
        uri: newuri,
        isTopPerfomance: isTopPerformance
    });
    
    trackCertificateStudent[studentAdd].push(certificateId);
    
    student[studentAdd].completeCourse.push(courseId);
    student[studentAdd].grade.push(grade);
    
    // Mint the certificate to the student
    _mint(studentAdd, certificateId, 1, abi.encodePacked(certificateId, title, newuri, studentName /* professorName */ ));
    setTokenURI(certificateId, newuri);
    
    // Emit the event
    emit CertificateCreated(certificateId, title, professorName, studentName, block.timestamp);
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
            student[studentAdd].haveVoucher = true;
            _mint(studentAdd, voucherId, toUse, abi.encodePacked(studentAdd, toUse, voucherId));
            setTokenURI(voucherId, newuri);
        }

        emit VoucherCreated(voucherId, VOUCHER_BASE, toUse);

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
        // TODO: Store custom URI per token
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