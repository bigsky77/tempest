### ==================================
###          TEMPEST INTERFACE
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.uint256 import Uint256


### ============= interface =============

@contract_interface
namespace ITempest:

    func get_pool_balance(
        token_type : felt) -> (balance : Uint256):
    end

    func swap( 
        token_type : felt, 
        amount_from : Uint256) -> (amount_to : Uint256):
    end

    func mint() -> (liquidity : Uint256):
    end

    func execute_swap(
        account_id : felt, 
        token_to : felt, 
        token_from : felt, 
        amount_from : Uint256) -> (amount_to : Uint256):
    end 
end


