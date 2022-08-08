### ==================================
###          TEMPEST ROUTER
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.ITempest import ITempest
from src.interfaces.IFactory import IFactory
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_mul, uint256_unsigned_div_rem
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

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
    amount_a_desired : Uint256, 
    amount_b_desired : Uint256, 
    amount_a_min : Uint256, 
    amount_b_min : Uint256, 
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
    amount_a_desired : Uint256, 
    amount_b_desired : Uint256, 
    amount_a_min : Uint256, 
    amount_b_min : Uint256, ) -> (amount_a : Uint256, amount_b : Uint256):

    let amount_a : felt
    let amount_b : felt

    let (pair) = IFactory.get_pair_address(factory, token_address_a, token_address_b)
    let (factory) = factory_address.read()

    if pair == 0: 
        IFactory.create_pair(factory, token_address_a, token_address_b)
        return()
    
    let (reserve_a) = ITempest.get_pool_balance(pair, token_address_a)
    let (reserve_b) = ITempest.get_pool_balance(pair, token_address_b)

    jmp body if reserve_a != 0:
        jmp body if reserve_b != 0:

    assert amount_a = amount_a_desired
    assert amount_b = amount_b_desired
    
    body:
        
    let (local amount_b) = quote(amount_a_desired, reserve_a, reserve_b)
        
        # assert less than or equal

     

    return()
end

### ============= utils ==============

func quote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
}(amount0 : Uint256, reserve0 : Uint256, reserve1 : Uint256) -> (amount1 : Uint256):
    alloc_locals
    
    # amount0 * reserve1 / reserve0
    let (local x) = uint256_mul(x=amount0, y=reserve1)
    let (local y) = uint256_unsigned_div_rem(a=x, div=reserve0)
    return(amount1=y)
end






