// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DocumentVerification {
    struct Certificate {
        string name;
        uint academicYear;
        uint date;
        string issuer;
        string gpa;
        string behavior;
        string certificateType;
        string certificateId;
        string fileHash;
    }

    struct University {
        string name;
        address uniqueUniversityAddress;
        address[] authorizedAddresses;
        mapping(address => bool) authorizedAddressesMap;
        bool isActive;
    }

    struct UniversityPublic {
        string name;
        address uniqueUniversityAddress;
        address[] authorizedAddresses;
        bool isActive;
    }

    mapping(address => bool) public contractAdmins;
    mapping(address => University) public universities;
    mapping(string => Certificate) public certificates;

    address[] public adminAddresses;
    address[] public universityAddress;

    address public contractOwner;

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(contractAdmins[msg.sender], "Caller is not an admin");
        _;
    }

    modifier onlyAuthorized(address uniqueUniversityAddress) {
        University storage university = universities[uniqueUniversityAddress];
        require(university.isActive, "University is not active");
        require(
            university.authorizedAddressesMap[msg.sender] ||
                university.uniqueUniversityAddress == msg.sender,
            "Caller is not authorized for this university"
        );
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function addAdmin(address admin) public onlyOwner {
        require(!contractAdmins[admin], "Address is already an admin");
        contractAdmins[admin] = true;
        adminAddresses.push(admin);
    }

    function removeAdmin(address admin) public onlyOwner {
        require(contractAdmins[admin], "Address is not an admin");
        contractAdmins[admin] = false;

        // Find the index of the admin to be removed in the adminAddresses array
        uint index = 0;
        for (uint i = 0; i < adminAddresses.length; i++) {
            if (adminAddresses[i] == admin) {
                index = i;
                break;
            }
        }

        // If the admin is not the last one in the array, move the last one to here
        if (index < adminAddresses.length - 1) {
            adminAddresses[index] = adminAddresses[adminAddresses.length - 1];
        }

        // Remove the last element in the array
        adminAddresses.pop();
    }

    function getAdmins() public view returns (address[] memory) {
        return adminAddresses;
    }

    function addUniversity(
        address uniqueUniversityAddress,
        string memory name
    ) public onlyAdmin {
        require(
            !universities[uniqueUniversityAddress].isActive,
            "University already exists"
        );

        // Note: We don't have to initialize the mapping here. It's created in storage when a new university is added.

        University storage newUniversity = universities[
            uniqueUniversityAddress
        ];

        newUniversity.name = name;
        newUniversity.uniqueUniversityAddress = uniqueUniversityAddress;
        newUniversity.isActive = true;

        universityAddress.push(uniqueUniversityAddress);
    }

    function replaceUniversityAddress(
        address oldUniversityAddress,
        address newUniversityAddress
    ) public onlyAdmin {
        require(
            universities[oldUniversityAddress].isActive,
            "Old university address does not exist or is not active"
        );
        require(
            universities[newUniversityAddress].authorizedAddresses.length == 0,
            "New university address already exists"
        );

        University storage oldUniversity = universities[oldUniversityAddress];
        University storage newUniversity = universities[newUniversityAddress];

        newUniversity.name = oldUniversity.name;
        newUniversity.uniqueUniversityAddress = newUniversityAddress;
        newUniversity.isActive = oldUniversity.isActive;

        // Copying authorized addresses and their mapping entries
        for (uint i = 0; i < oldUniversity.authorizedAddresses.length; i++) {
            address authorizedAddress = oldUniversity.authorizedAddresses[i];
            newUniversity.authorizedAddresses.push(authorizedAddress);
            newUniversity.authorizedAddressesMap[
                authorizedAddress
            ] = oldUniversity.authorizedAddressesMap[authorizedAddress];
        }

        delete universities[oldUniversityAddress];

        for (uint i = 0; i < universityAddress.length; i++) {
            if (universityAddress[i] == oldUniversityAddress) {
                universityAddress[i] = newUniversityAddress;
                break;
            }
        }
    }

    function deactivateUniversity(
        address uniqueUniversityAddress
    ) public onlyAdmin {
        require(
            universities[uniqueUniversityAddress].authorizedAddresses.length !=
                0,
            "University does not exist"
        );

        universities[uniqueUniversityAddress].isActive = false;
    }

    function activateUniversity(
        address uniqueUniversityAddress
    ) public onlyAdmin {
        require(
            universities[uniqueUniversityAddress].authorizedAddresses.length !=
                0,
            "University does not exist"
        );

        universities[uniqueUniversityAddress].isActive = true;
    }

    function authorizeAddress(
        address uniqueUniversityAddress,
        address toAuthorize
    ) public onlyAuthorized(uniqueUniversityAddress) {
        require(
            !universities[uniqueUniversityAddress].authorizedAddressesMap[
                toAuthorize
            ],
            "Address is already authorized"
        );

        University storage university = universities[uniqueUniversityAddress];
        university.authorizedAddresses.push(toAuthorize);
        university.authorizedAddressesMap[toAuthorize] = true;
    }

    function removeAuthorizedAddress(
        address uniqueUniversityAddress,
        address toRemove
    ) public onlyAuthorized(uniqueUniversityAddress) {
        require(
            universities[uniqueUniversityAddress].authorizedAddressesMap[
                toRemove
            ],
            "Address is not authorized"
        );

        University storage university = universities[uniqueUniversityAddress];

        // Directly mark the address as unauthorized
        university.authorizedAddressesMap[toRemove] = false;
    }

    function getAllUniversities()
        public
        view
        returns (UniversityPublic[] memory)
    {
        UniversityPublic[] memory universityList = new UniversityPublic[](
            universityAddress.length
        );
        // Iterate over the universityAddresses array
        for (uint i = 0; i < universityAddress.length; i++) {
            University storage university = universities[universityAddress[i]];
            universityList[i] = UniversityPublic({
                name: university.name,
                uniqueUniversityAddress: university.uniqueUniversityAddress,
                authorizedAddresses: university.authorizedAddresses,
                isActive: university.isActive
            });
        }
        return universityList;
    }

    function getUniversityByAddress(
        address uniqueUniversityAddress
    ) public view returns (string memory, address, address[] memory, bool) {
        University storage university = universities[uniqueUniversityAddress];
        return (
            university.name,
            university.uniqueUniversityAddress,
            university.authorizedAddresses,
            university.isActive
        );
    }

    function addCertificate(
        address uniqueUniversityAddress,
        string memory name,
        uint academicYear,
        uint date,
        string memory issuer,
        string memory gpa,
        string memory behavior,
        string memory certificateType,
        string memory certificateId,
        string memory fileHash
    ) public onlyAuthorized(uniqueUniversityAddress) {
        Certificate memory newCertificate = Certificate({
            name: name,
            academicYear: academicYear,
            date: date,
            issuer: issuer,
            gpa: gpa,
            behavior: behavior,
            certificateType: certificateType,
            certificateId: certificateId,
            fileHash: fileHash
        });
        certificates[fileHash] = newCertificate;
    }

    function validateCertificate(
        string memory fileHash
    ) public view returns (bool) {
        bytes memory tempEmptyStringTest = bytes(certificates[fileHash].name);
        if (tempEmptyStringTest.length == 0) {
            return false;
        } else {
            return true;
        }
    }

    function getCertificate(
        string memory fileHash
    )
        public
        view
        returns (
            string memory,
            uint,
            uint,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        Certificate memory certificate = certificates[fileHash];

        // Check if the certificate exists
        bytes memory tempEmptyStringTest = bytes(certificate.name);
        require(tempEmptyStringTest.length != 0, "Certificate does not exist.");

        // Return the certificate details
        return (
            certificate.name,
            certificate.academicYear,
            certificate.date,
            certificate.issuer,
            certificate.gpa,
            certificate.behavior,
            certificate.certificateType,
            certificate.certificateId
        );
    }
}
