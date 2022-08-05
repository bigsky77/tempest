### ==================================
###              TEMPEST
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.cairo_builtins import (HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.math import (assert_nn_le, unsigned_div_rem, assert_le)
from starkware.cairo.common.hash import hash2
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.library import ERC20
from openzeppelin.access.ownable.library import Ownable 
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address) 
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_signed_nn_le, uint256_add, uint256_pow2, uint256_sub, uint256_unsigned_div_rem, uint256_mul, uint256_sqrt, uint256_eq

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

@storage_var 
func account_balance(account_id : felt, token_type : felt) -> (balance : Uint256):
end

## change to reserve1 and reserve0
@storage_var
func pool_balance(token_type : felt) -> (balance : Uint256):
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
    let zero = Uint256(low=0,high=0)
    initialize(
        name=NAME, 
        symbol=SYMBOL, 
        decimals=DECIMALS, 
        initial_supply=zero,
        recipient=address_this,
        owner=address_this,
    )

    return()
end

### ============= views ==============

@view
func get_account_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_type : felt) -> (balance : Uint256):
    let (balance) = account_balance.read(account_id=account_id, token_type=token_type)
    return(balance=balance)
end

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
func initialize{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(
    name : felt, 
    symbol : felt, 
    decimals : felt, 
    initial_supply : Uint256, 
    recipient : felt, 
    owner : felt
) -> ():
    ERC20.initializer(name, symbol, decimals)
    ERC20._mint(recipient, initial_supply)
    Ownable.initializer(owner)
    return()
end

@external
func update_balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_type : felt, amount : Uint256) -> (new_balance : Uint256):
    alloc_locals

    let (current_balance) = account_balance.read(account_id=account_id, token_type=token_type)
    let (local new_balance, _) = uint256_add(a=current_balance, b=amount)
    let (local upper_bound) = get_upperbound()

    uint256_signed_nn_le(new_balance, upper_bound)

    account_balance.write(
        account_id=account_id,
        token_type=token_type,
        value=new_balance,
    )

    return(new_balance=new_balance)
end

@external
func swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr, 
}(account_id : felt, token_type : felt, amount_from : Uint256) -> (amount_to : Uint256):
    alloc_locals 

    assert (token_type - TOKEN_A) * (token_type - TOKEN_B) = 0
    
    let (local upper_bound) = get_upperbound()
    uint256_signed_nn_le(amount_from, upper_bound)

    let (local account_from_balance) = account_balance.read(
            account_id=account_id, 
            token_type=token_type
    )

    uint256_le(amount_from, account_from_balance)

    let (local to_token) = get_opposite_token(token_type)
   
    let (local amount_to) = execute_swap(
            account_id=account_id, 
            token_to=to_token,
            token_from=token_type, 
            amount_from=amount_from,
    )
    
    # update to balances
    
    update_balance(
        account_id=account_id, 
        token_type=to_token, 
        amount=amount_to
    )

    update_pool_balance(token_type=token_type, amount=amount_to)

    # update from balances

    update_balance(
        account_id=account_id,
        token_type=token_type,
        amount=amount_from,
    )

    update_pool_balance(token_type=token_type, amount=amount_from)
    
    return(amount_to=amount_to)
end

@external
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

### ============ interal =============

func execute_swap{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt, token_to : felt, token_from : felt, amount_from : Uint256) -> (amount_to : Uint256):
    alloc_locals

    let (local account_from_balance) = account_balance.read(
            account_id=account_id, 
            token_type=token_to
    )
    
    uint256_le(account_from_balance, amount_from)

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

### ==================================
###        MINT BURN FUNCTIONS
### ==================================

@external
func mint{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(account_id : felt) -> (liquidity : Uint256):
    alloc_locals
   
    let (local to) = get_caller_address()
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
    let (local total_supply, _) = ERC20.balanceOf(contract_address)
    
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
        
        let (local to) = get_caller_address()

        ERC20._mint(recipient=to, amount=liquidity)
        
        update_pool_balance(token_type=TOKEN_A, amount=balance0)
        update_pool_balance(token_type=TOKEN_B, amount=balance1)
    
        return(liquidity)
end

# todo: remove account_id and just use calling addresses 
func burn{
        syscall_ptr : felt,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}(account_id : felt) -> (token_a_amount : felt, token_b_amount : felt):
    alloc_locals

    let (local caller_address) = get_caller_address()
    let (local contract_address) = get_contract_address()

    let (local token_a_balance) = IERC20.balanceOf(address_a, contract_address)
    let (local token_b_balance) = IERC20.balanceOf(address_b, contract_address)
    let (local liquidity) = ERC20.balanceOf(contract_address)

    let (local reserve_a) = pool_balance.read(token_type=TOKEN_A)
    let (local reserve_b) = pool_balance.read(token_type=TOKEN_B)

    # liquidity * balance_a / reserve_a
    tempvar x = uint256_mul(a=liquidity, b=token_a_balance)
    let (local amount_a) = uint256_unsigned_div_rem(a=x, div=reserve_a)

    # liquidity * balance_a / reserve_a
    tempvar y = uint256_mul(a=liquidity, b=token_b_balance)
    let (local amount_b) = uint256_unsigned_div_rem(a=y, div=reserve_b)
    
    
    jmp body if amount_a != 0; ap++
        jmp body if amount_b != 0; ap++
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

    tempvar balance_a_new = uint256_sub(a=reserve_a, b=amount_a)
    tempvar balance_b_new = uint256_sub(a=reserve_b, b=amount_b)

    update_pool_balance(token_type=TOKEN_A, amount=balance_a_new)
    update_pool_balance(token_type=TOKEN_B, amount=balance_b_new)
    
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

    let  y  = Uint256(low=0, high=62)
    let  x  = Uint256(low=0, high=1)

    let (local upper_bound) = uint256_pow2(exp=y)
    let (local upper_bound_sub_one) = uint256_sub(upper_bound, x)

    return (upper_bound=upper_bound_sub_one)
end


