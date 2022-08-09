### ==================================
###          ROUTER INTERFACE
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.uint256 import Uint256


### ============= interface =============

@contract_interface
namespace IRouter:
    func add_liquidity(
        token_address_a : felt, 
        token_address_b : felt, 
        amount_a_desired : Uint256, 
        amount_b_desired : Uint256, 
        amount_a_min : Uint256, 
        amount_b_min : Uint256, 
        to : felt, 
        deadline : felt, ) -> (amount_a : Uint256, amount_b : Uint256, liquidity : Uint256):
    end
end
