### ==================================
###           TEMPEST TESTS
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_signed_nn_le, uint256_add, uint256_pow2, uint256_sub, uint256_unsigned_div_rem, uint256_mul, uint256_sqrt, uint256_eq
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from cairomate.contracts.interfaces.IERC20 import IERC20

### =========== constants ============   

const TOKEN_A = 1
const ADDRESS_A = 0xA71775cf1e309d254c882fC7B6bc61338a5656DA

const TOKEN_B = 2
const ADDRESS_B = 0x0A1fb0ec3B837aAdDdFDC1e989C77649a4856a41

const USER = 1

### ============= interface =============

@contract_interface
namespace ITempest:
    func get_account_balance(
        account_id : felt, 
        token_type : felt) -> (balance : Uint256):
    end

    func get_pool_balance(
        token_type : felt) -> (balance : Uint256):
    end

    func swap(
        account_id : felt, 
        token_type : felt, 
        amount_from : Uint256) -> (amount_to : Uint256):
    end

    func _mint(
        account_id : felt) -> (liquidity : Uint256):
    end
end



### ============= set-up =============

@external
func __setup__{syscall_ptr : felt*}():
    alloc_locals
 
    %{ context.contract_address_tempest = deploy_contract(
        "./src/tempest.cairo", 
        [0, 1]).contract_address
    %}

    %{ context.contract_address_tokenA = deploy_contract(
        "./lib/cairomate/contracts/mocks/MockERC20.cairo", 
        [1, 1, 18, 1000, 1, 1]).contract_address
    %}      

    %{ context.contract_address_tokenB = deploy_contract(
        "./lib/cairomate/contracts/mocks/MockERC20.cairo",   
        [2, 2, 18, 1000, 1, 1]).contract_address
    %}

    return()
end

@external
func test_mint{
        syscall_ptr : felt*,
        range_check_ptr,
}():
    alloc_locals

    local contract_address : felt
    %{ ids.contract_address = context.contract_address_tempest %} 
    local token_address_a : felt
    %{ ids.token_address_a = context.contract_address_tokenA %}
    
    local token_address_b : felt
    %{ ids.token_address_b = context.contract_address_tokenB %}

    %{ stop_prank_callable = start_prank(1) %}
    
    let (caller_address) = get_caller_address() 
    let amount = Uint256(low=1000,high=0) 

    IERC20.transfer_from(
        contract_address=token_address_a,
        sender=caller_address, 
        recipient=contract_address,
        amount=amount,
    )
    
    IERC20.transfer_from(
        contract_address=token_address_b,
        sender=caller_address, 
        recipient=contract_address,
        amount=amount,
    )
    
    ITempest._mint(contract_address=contract_address,account_id=USER)
    %{stop_prank_callable() %}

    return()
end

@external
func test_swap{
        syscall_ptr : felt*,
        range_check_ptr,
}():
    alloc_locals

    local contract_address : felt
    %{ ids.contract_address = context.contract_address_tempest %}

    local token_address_a : felt
    %{ ids.token_address_a = context.contract_address_tokenA %}
    
    local token_address_b : felt
    %{ ids.token_address_b = context.contract_address_tokenB %}

    return()
end














