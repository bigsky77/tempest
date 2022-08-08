### ==================================
###          TEMPEST ROUTER
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.ITempest import ITempest
from src.interfaces.IFactory import IFactory
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256 
from starkware.cairo.common.cairo_builtins import HashBuiltin

### ======= storage-variables ========

@storage_var
func factory_address() -> (value : felt):
end

### ========== constructor ===========

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
}(factory : felt)
    factory_address.write(factory)
    return()
end

 ### ====== external functions ========

 @external 
 func add_liquidity{
         syscall_ptr : felt*,
         pedersen_ptr : HashBuiltin*,
         range_check_ptr,
}(
    token_address_a : felt, 
    token_address_b : felt, 
    amount_a_desired : felt, 
    amount_b_desired : felt, 
    amount_a_min : felt, 
    amount_b_min : felt, 
    to : felt, 
    deadline : felt, ) -> (amount_a : felt, amount_b : felt, liquidity : felt):
    alloc_locals

    let (factory) = factory_address.read()
    let (pair) = IFactory.get_pair_address(factory, token_address_a, token_address_b)

    let (amountA, amountB) = _compute_liquidity()

    return(amount_a, amount_b, liquidity)
end

### ====== internal functions ========

func _compute_liquidity_{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(
    token_address_a : felt, 
    token_address_b : felt, 
    amount_a_desired : felt, 
    amount_b_desired : felt, 
    amount_a_min : felt, 
    amount_b_min : felt, ) -> (amount_a, amount_b):


