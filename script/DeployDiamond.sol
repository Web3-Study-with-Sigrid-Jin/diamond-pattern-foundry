pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/Diamond.sol";
import "../src/upgradeInitializers/DiamondInit.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";

contract DeployDiamond is Script {
    address private constant DIAMOND_OWNER = address(0x2535);
    address[] deployedContracts;
    bytes4[] private loupeFacetSelectors = [
        DiamondLoupeFacet.facets.selector,
        DiamondLoupeFacet.facetFunctionSelectors.selector,
        DiamondLoupeFacet.facetAddresses.selector,
        DiamondLoupeFacet.facetAddress.selector,
        DiamondLoupeFacet.supportsInterface.selector
    ];
    bytes4[] private ownershipFacetSelectors = [
        OwnershipFacet.transferOwnership.selector,
        OwnershipFacet.owner.selector
    ];

    DiamondCutFacet diamondCutFacet;
    Diamond diamond;
    DiamondInit diamondInit;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    IDiamondCut.FacetCut[] facetCuts;

    function run() external returns (address[] memory) {
        // All vm.startBroadcast does is create transactions
        // that can later be signed and sent onchain.
        vm.startBroadcast(DIAMOND_OWNER);
        // 1 : deploy diamondcut facet
        diamondCutFacet = new DiamondCutFacet();
        // 2 : deploy diamond; passing as arguments
        // - the owner of the diamond
        // - the diamondcut facet address
        diamond = new Diamond(DIAMOND_OWNER, address(diamondCutFacet));
        // 3 : diamondinit contract is deployed
        // - init() : which is called on the first diamond upgrade
        // ... to initialize state of some state variables.
        diamondInit = new DiamondInit();
        // facets are deployed.
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();

        deployedContracts.push(address(diamondCutFacet));
        deployedContracts.push(address(diamond));
        deployedContracts.push(address(diamondInit));
        deployedContracts.push(address(diamondLoupeFacet));
        deployedContracts.push(address(ownershipFacet));

        /// Cut Facets.
        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeFacetSelectors
        }));

        facetCuts.push(IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipFacetSelectors
        }));

        /// upgrading Diamond with facet cuts
        /// then call to DiamondInit.init()
        /// it is possible to pass params to the init() function call
        /// in order to initialize the Diamond Storage ...
        /// with some script data by encoding them along the init function loupeFacetSelectors
        (bool success, ) = address(diamond).call(
            abi.encodeWithSelector(
                IDiamondCut.diamondCut.selector,
                facetCuts,
                address(diamondInit),
                abi.encode(DiamondInit.init.selector)
            )
        );

        require(success, "DEPLOY :: DIAMOND_UPGRADE_ERROR");

        vm.stopBroadcast();

        return deployedContracts;
    }
}
