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

    function testAddAllFacet1FunctionSelectorsAndCall() public {
        bool success;
        bytes memory data;

        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: TEST1_FACET_ADDR,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: test1FacetSelectors
        }));

        vm.prank(DIAMOND_OWNER);

        // Diamond Cut
        (success, ) = diamondAddress.call(
            abi.encodeWithSelector(
                IDiamondCut.diamondCut.selector,
                facetCuts,
                address(0),
                bytes('')
            )
        );

        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        // Test Facet add and facet function selectors matching
        (success, data) = diamondAddress.call(abi.encode(IDiamondLoupe.facetAddresses.selector));

        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        address[] memory facetAddresses = abi.decode(data, (address[]));

        assertEq(STANDARD_FACET_COUNT + 1, facetAddresses.length);
        assertEq(_getFacetSelectors(TEST1_FACET_ADDR).length, test1FacetSelectors.length);
        assertEq(
            keccak256(abi.encode(_getFacetSelectors(TEST1_FACET_ADDR))),
            keccak256(abi.encode(test1FacetSelectors))
        );

        // Test call to a Test1Facet function
        (success, data) = diamondAddress.call(abi.encode(Test1Facet.Func2Test1.selector));
        assertTrue(success, "TEST_DIAMOND::CALL_FAILED");

        uint256 retVal = abi.decode(data, (uint256));
        assertEq(retVal, 2535);

    }
    // more... https://github.com/NaviNavu/diamond-1-foundry/blob/de39b4c026/test/TestDiamond.t.sol
    // https://github.com/DvideN/diamond-1-hardhat
}
