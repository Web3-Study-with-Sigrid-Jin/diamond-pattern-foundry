pragma solidity ^0.8.0;

import "./TestHelper.sol";

contract TestDiamond is TestHelper {
    function setUp() public {
        deployDiamondScript = new DeployDiamond();
        deployedContracts = deployDiamondScript.run();
        cutFacetAddress = deployedContracts[0];
        diamondAddress = deployedContracts[1];
        initContractAddress = deployedContracts[2];
        loupeFacetAddress = deployedContracts[3];
        ownershipFacetAddress = deployedContracts[4];

        if (facetCuts.length != 0) {
            delete facetCuts;
        }
    }

    function testDiamondHasValidStandardFacetCount() public {
        (bool success, bytes memory data) = diamondAddress.call(abi.encode(IDiamondLoupe.facetAddresses.selector));
        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");
        address[] memory facetAddresses = abi.decode(data, (address[]));
        assertEq(STANDARD_FACET_COUNT, facetAddresses.length);
    }

    function testDiamondHasValidDiamondCutFacetFunctionSelectors() public {
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(cutFacetAddress))),
            keccak256(abi.encode(cutFacetSelectors))
        );
    }

    function testDiamondHasValidLoupeFacetFunctionSelectors() public {
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(loupeFacetAddress))),
            keccak256(abi.encode(loupeFacetSelectors))
        );
    }

    function testDiamondHasValidOwnershipFacetFunctionSelectors() public {
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(ownershipFacetAddress))),
            keccak256(abi.encode(ownershipFacetSelectors))
        );
    }

    function testSelectorsAreCorrectlyAssociatedToDiamondCutFacet() public {
        assertEq(
            _getFacetByFunctionSelector(DiamondCutFacet.diamondCut.selector),
            cutFacetAddress
        );
    }

    function testSelectorsAreCorrectlyAssociatedToLoupeFacet() public {
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facets.selector),
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facetFunctionSelectors.selector),
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facetAddresses.selector),
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.facetAddress.selector),
            loupeFacetAddress
        );
        assertEq(
            _getFacetByFunctionSelector(DiamondLoupeFacet.supportsInterface.selector),
            loupeFacetAddress
        );
    }
    // more... https://github.com/NaviNavu/diamond-1-foundry/blob/de39b4c026/test/TestDiamond.t.sol
    // https://github.com/DvideN/diamond-1-hardhat
}
