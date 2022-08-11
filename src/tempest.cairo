### ==================================
###              TEMPEST
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn_le, unsigned_div_rem, assert_le, assert_not_zero)
from starkware.cairo.common.hash import hash2
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.library import ERC20
from openzeppelin.access.ownable.library import Ownable 
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_le, 
    uint256_signed_nn_le, 
    uint256_add, 
    uint256_pow2, 
    uint256_sub, 
    uint256_unsigned_div_rem, 
    uint256_mul, 
    uint256_sqrt, 
    uint256_eq, 
    uint256_check,
    )
from cairo_math_64x61.contracts.cairo_math_64x61.math64x61 import Math64x61   

### =========== constants ============

const NAME = 'Tempest'
const SYMBOL = 'SEA'
const DECIMALS = 18

const TOKEN_A = 1
const TOKEN_B = 2

## the token_id for the pool token
const LP_TOKEN = 3

## hack / placeholder.  What is 1e3 in Cario?
## needs to be uint
const MIN_LIQUIDITY = 1000 

### ============ storage =============

@storage_var
func token_address(token_id : felt) -> (token_address : felt):
end

## change to reserve1 and reserve0
@storage_var
func pool_balance(token_type : felt) -> (balance : Uint256):
end

@storage_var
func block_timestamp_last() -> (last_block_timestamp : felt):
end

@storage_var 
func price_cumulative_last(token_id) -> (price_cumulative_last : Uint256):
end

### ============= events =============

@event
func Swap(adddress_user : felt, amount_in : Uint256, amount_out : Uint256):
end

@event
func Mint(adddress_user : felt, amount_minted : Uint256):
end

@event
func Burn(adddress_user : felt, amount_a : Uint256, amount_b : Uint256):
end

### ========== constructor ===========

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(
    token_a : felt, 
    token_b : felt,
):
    alloc_locals

    token_address.write(token_id=TOKEN_A, value=token_a)
    token_address.write(token_id=TOKEN_B, value=token_b)
    
    let (local address_this) = get_contract_address()
    ERC20.initializer(NAME, SYMBOL, DECIMALS)
    Ownable.initializer(owner=address_this)

    return()
end

### ============= views ==============

@view 
func get_pool_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_type : felt) -> (balance : Uint256):
    alloc_locals
    let (local balance) = pool_balance.read(token_type=token_type)
    return(balance=balance)
end

### ============ external ============

@external
func swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
}(token_from : felt, amount_from : Uint256) -> (amount_to : Uint256):
    alloc_locals 

    assert (token_from - TOKEN_A) * (token_from - TOKEN_B) = 0

    let (local token_from_address) = token_address.read(token_from)
    let (local user_address) = get_caller_address()
    let (local upper_bound) = get_upperbound()
    
    with_attr error_message("out of bounds"):
        let(local y) = uint256_le(amount_from, upper_bound)
        assert_not_zero(y)
    end

    let (local account_from_balance) = IERC20.balanceOf(token_from_address, user_address)

    with_attr error_message("not enough tokens"):
        let(local x) = uint256_le(amount_from, account_from_balance)
        assert_not_zero(x)
    end

    let (local token_to) = get_opposite_token(token_from)
   
    let (local amount_to) = execute_swap(
            account_address=user_address, 
            token_to=token_to,
            token_from=token_from, 
            amount_from=amount_from,
    )
    
    update_pool_balance(token_type=token_to, amount=amount_to)
    update_pool_balance(token_type=token_from, amount=amount_from)
    
    Swap.emit(user_address, amount_to, amount_from)
    return(amount_to=amount_to)
end

### ============ interal =============

func execute_swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_address : felt, token_to : felt, token_from : felt, amount_from : Uint256) -> (amount_to : Uint256):
    alloc_locals

    let (local amm_from_balance) = pool_balance.read(token_type=token_from)
    let (local amm_to_balance) = pool_balance.read(token_type=token_to)
       
    let (local a, _) = uint256_mul(a=amount_from, b=amm_to_balance)
    let (local div, _) = uint256_add(a=amount_from, b=amm_from_balance)

    let (local amount_to, _) = uint256_unsigned_div_rem(a, div) 
   
    ## retrieve token addresses
    let (local token_to_address) = token_address.read(token_id=token_to)
    let (local token_from_address) = token_address.read(token_id=token_from)

    let (local pool_address) = get_contract_address()
    let (local caller_address) = get_caller_address()

    ## transfer user token to pool
        
    IERC20.transfer(
        contract_address=token_from_address,
     #  sender=caller_address,
        recipient=pool_address,
        amount=amount_from,
    )
    
    ## transfer token to user 
    
    IERC20.transfer(
        contract_address=token_to_address,
     #  sender=pool_address, 
        recipient=caller_address, 
        amount=amount_to,
    )

    return(amount_to=amount_to)
end

func _update{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(balance_a : Uint256, balance_b : Uint256, reserve_a : Uint256, reserve_b : Uint256):
    alloc_locals

    uint256_check(a=balance_a)
    uint256_check(a=balance_b)

    let (local last_block_timestamp) = block_timestamp_last.read()
    let (local block_time_stamp) = get_block_timestamp()
    
    tempvar time_elapsed = block_time_stamp - last_block_timestamp
         
    jmp body if time_elapsed != 0; ap++
        jmp body if reserve_a.low != 0; ap++
            jmp body if reserve_b.low != 0; ap++
        return()

    body:
    let (local int_res_a) = Math64x61.fromUint256(reserve_a)
    let (local int_res_b) = Math64x61.fromUint256(reserve_b)
    let (local time_elapsed_fixed) = Math64x61.fromFelt(time_elapsed) 

    let (local price_a) = Math64x61.div(int_res_b, int_res_a) 
    let (local price_b) = Math64x61.div(int_res_a, int_res_b) 
    let (local price_a_mul_time) = Math64x61.mul(price_a, time_elapsed_fixed)
    let (local price_b_mul_time) = Math64x61.mul(price_b, time_elapsed_fixed)

    let (local price_a_last) = Math64x61.toUint256(price_a_mul_time)
    let (local price_b_last) = Math64x61.toUint256(price_b_mul_time)

    price_cumulative_last.write(TOKEN_A, price_a_last)
    price_cumulative_last.write(TOKEN_B, price_b_last)

    pool_balance.write(TOKEN_A, balance_a)
    pool_balance.write(TOKEN_B, balance_b)

    block_timestamp_last.write(block_time_stamp)
    return()
    
end

func update_pool_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(token_type : felt, amount : Uint256) -> (new_balance : Uint256):
    alloc_locals

    let (local current_balance) = pool_balance.read(token_type=token_type)
    let (local new_balance, _) = uint256_add(a=current_balance, b=amount)

    pool_balance.write(token_type=token_type, value=new_balance)

    return(new_balance=new_balance)
end  

### ==================================
###        MINT BURN FUNCTIONS
### ==================================

@external
func mint{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (liquidity : Uint256):
    alloc_locals
   
    let (local user_address) = get_caller_address()
    let (local contract_address) = get_contract_address()

    let (local address_a) = token_address.read(token_id=TOKEN_A)
    let (local address_b) = token_address.read(token_id=TOKEN_B)

    let (local balance0) = IERC20.balanceOf(address_a, contract_address)
    let (local balance1) = IERC20.balanceOf(address_b, contract_address)

    let (local reserve0) = pool_balance.read(token_type=TOKEN_A)
    let (local reserve1) = pool_balance.read(token_type=TOKEN_B)

    let (local amount0) = uint256_sub(a=balance0, b=reserve0)
    let (local amount1) = uint256_sub(a=balance1, b=reserve1)
    
    ## wrong needs to be LP token total supply
    let (local total_supply) = ERC20.total_supply()
    
    let zero = Uint256(low=0,high=0)
    let (local x) = uint256_eq(total_supply, zero)

    jmp body if x != 0; ap++
        let (local mul, _) = uint256_mul(a=amount0, b=amount1)
        let (local z) = uint256_sqrt(n=mul)
        let y = Uint256(low=MIN_LIQUIDITY, high=0) 
        let (local liquidity) = uint256_sub(z, y)

        ERC20._mint(recipient=1, amount=y)

        return(liquidity)
    body: 
        let (local a, _) = uint256_mul(a=amount0, b=total_supply)
        let (local b, _) = uint256_mul(a=amount1, b=total_supply)
        let (local liquidity) = math_min(a, b)
        
        ERC20._mint(recipient=user_address, amount=liquidity)
        
        update_pool_balance(token_type=TOKEN_A, amount=balance0)
        update_pool_balance(token_type=TOKEN_B, amount=balance1)
    
        Mint.emit(user_address, liquidity)
        return(liquidity)
end

# todo: remove account_id and just use calling addresses 
func burn{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}() -> (token_a_amount : Uint256, token_b_amount : Uint256):
    alloc_locals

    let (local caller_address) = get_caller_address()
    let (local contract_address) = get_contract_address()
     
    let (local address_a) = token_address.read(token_id=TOKEN_A)
    let (local address_b) = token_address.read(token_id=TOKEN_B)

    let (local token_a_balance) = IERC20.balanceOf(address_a, contract_address)
    let (local token_b_balance) = IERC20.balanceOf(address_b, contract_address)
    let (local liquidity) = ERC20.balance_of(contract_address)

    let (local reserve_a) = pool_balance.read(token_type=TOKEN_A)
    let (local reserve_b) = pool_balance.read(token_type=TOKEN_B)

    # liquidity * balance_a / reserve_a
    let (local x, _) = uint256_mul(a=liquidity, b=token_a_balance)
    let (local amount_a, _) = uint256_unsigned_div_rem(a=x, div=reserve_a)

    # liquidity * balance_a / reserve_a
    let (local y, _) = uint256_mul(a=liquidity, b=token_b_balance)
    let (local amount_b, _) = uint256_unsigned_div_rem(a=y, div=reserve_b)
    
    
    jmp body if amount_a.low != 0; ap++
        jmp body if amount_b.low != 0; ap++
        with_attr error_message("not enough liquidity!"):
    end

    body:
    ERC20._burn(contract_address, liquidity)

    IERC20.transfer(
        address_a,
        caller_address,
        amount_a,
    )

    IERC20.transfer(
        address_b,
        caller_address,
        amount_b
    )

    let (local balance_a_new) = uint256_sub(a=reserve_a, b=amount_a)
    let (local balance_b_new) = uint256_sub(a=reserve_b, b=amount_b)

    update_pool_balance(token_type=TOKEN_A, amount=balance_a_new)
    update_pool_balance(token_type=TOKEN_B, amount=balance_b_new)
    
   Burn.emit(caller_address, amount_a, amount_b) 
   return(amount_a, amount_b) 
end


### ============= utils ==============

# Find and return the lower of two Uints
func math_min{
        range_check_ptr,
}(a : Uint256, b : Uint256) -> (res : Uint256):
    alloc_locals

    let (local x) = uint256_le(a,b)
    if x == 0:
        return(res=a)
    else:
        return(res=b)
    end
end

func get_opposite_token(token_type : felt) -> (token_type : felt):
    if token_type == TOKEN_A:
        return(TOKEN_B)
    else:
        return(TOKEN_A) 
    end
end

func get_upperbound{range_check_ptr}() -> (upper_bound : Uint256):
    alloc_locals

    let  y  = Uint256(low=62, high=0)
    let  x  = Uint256(low=1, high=0)

    let (local upper_bound) = uint256_pow2(exp=y)
    let (local upper_bound_sub_one) = uint256_sub(upper_bound, x)

    return (upper_bound=upper_bound_sub_one)
end


