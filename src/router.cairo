### ==================================
###          TEMPEST ROUTER
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.ITempest import ITempest
from src.interfaces.IFactory import IFactory
from openzeppelin.token.erc20.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_mul, uint256_unsigned_div_rem, uint256_signed_nn_le, uint256_lt, uint256_add, uint256_le
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

### ======= storage-variables ========

@storage_var
func factory_address() -> (value : felt):
end

### ============= events =============

@event
func Liquidity_Added(amount_a : Uint256, amount_b : Uint256, liquidity : Uint256):
end


### ========== constructor ===========

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
}(factory : felt):
    factory_address.write(factory)
    return()
end

### ====== external functions ========

# TODO add deadline
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
    deadline : felt, ) -> (amount_a : Uint256, amount_b : Uint256, liquidity : Uint256):
    alloc_locals

    let (factory) = factory_address.read()

    let (amount_a, amount_b) = compute_liquidity(token_address_a, token_address_b, amount_a_desired, amount_b_desired, amount_a_min, amount_b_min)
    let (pair) = IFactory.get_pair_address(factory, token_address_a, token_address_b)
    let (local caller_address) = get_caller_address()

    # ensure high enough balance 
    let (local user_balance_a) = IERC20.balanceOf(token_address_a, caller_address)
    let (local user_balance_b)= IERC20.balanceOf(token_address_b, caller_address)

    with_attr error_message("Not Enough A Tokens"):
        let (local x) = uint256_le(amount_a, user_balance_a)
        assert_not_zero(x)
    end

    with_attr error_message("Not Enough B Tokens"):
        let (local y) = uint256_le(amount_b, user_balance_b)
        assert_not_zero(y)
    end

    # needs to be account id or change to address
    IERC20.transferFrom(
        token_address_a,
        caller_address,
        pair,
        amount_a,
    )

    IERC20.transferFrom(
        token_address_b,
        caller_address,
        pair,
        amount_b,
    )

    let (local liquidity) = ITempest.mint(pair)
    
    Liquidity_Added.emit(amount_a, amount_b, liquidity)

    return(amount_a, amount_b, liquidity)
end

### ====== internal functions ========

func compute_liquidity{
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
    alloc_locals

    local amount_a : Uint256
    local amount_b : Uint256

    let (factory) = factory_address.read()
    let (pair) = IFactory.get_pair_address(factory, token_address_a, token_address_b)

    if pair == 0: 
        IFactory.create_pair(factory, token_address_a, token_address_b)   
        assert amount_a = amount_a_desired
        assert amount_b = amount_b_desired
        return(amount_a, amount_b)
    end 

    let (local reserve_a) = ITempest.get_pool_balance(pair, token_address_a)
    let (local reserve_b) = ITempest.get_pool_balance(pair, token_address_b)
    let (local quote_a) = quote(amount0=amount_a_desired, reserve0=reserve_a, reserve1=reserve_b) 
    let (local quote_b) = quote(amount0=amount_b_desired, reserve0=reserve_b, reserve1=reserve_a)

    let (local amount_b_eq) = uint256_signed_nn_le(quote_b, amount_b_desired)
    let (local amount_a_eq) = uint256_signed_nn_le(quote_a, amount_a_desired)
    let (local reserve_sum, _) = uint256_add(reserve_a, reserve_b)
  
    # if amount_b <= amount_b_desired
    
    if amount_b_eq != 0:
        let (local x) = uint256_lt(quote_b, amount_b_min)
        assert_not_zero(x)
        assert amount_a = amount_a_desired
        assert amount_b = quote_b
        return(amount_a, amount_b)
    end


    if amount_a_eq != 0:    
        let (local y) = uint256_lt(quote_a, amount_a_min)
        assert_not_zero(y) 
        assert amount_b = amount_b_desired
        assert amount_a = quote_a
        return(amount_a, amount_b)
    end
    
    return(amount_a, amount_b)
end


### ============= utils ==============

func quote{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(
    amount0 : Uint256, 
    reserve0 : Uint256, 
    reserve1 : Uint256,) -> (amount : Uint256):
    alloc_locals
    # amount0 * reserve1 / reserve0
    let (local x, _) = uint256_mul(a=amount0, b=reserve1)
    let (local y, _) = uint256_unsigned_div_rem(a=x, div=reserve0)
    return(amount=y)  
end
