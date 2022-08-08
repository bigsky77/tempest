### ==================================
###          TEMPEST INTERFACE
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.uint256 import Uint256


### ============= interface =============

@contract_interface
namespace IFactory: 
    func create_pair(
        token_address_a : felt, token_address_b : felt) -> (pool_address : felt):
    end
end
