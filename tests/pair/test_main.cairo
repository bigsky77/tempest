### ==================================
###           TEMPEST TESTS
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_signed_nn_le, uint256_add, uint256_pow2, uint256_sub, uint256_unsigned_div_rem, uint256_mul, uint256_sqrt, uint256_eq
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.library import ERC20
from src.interfaces.ITempest import ITempest

### =========== constants ============   

const TOKEN_A = 1

const TOKEN_B = 2

const USER = 'user'
const ADMIN = 'admin'
const TOKEN_NAME_A = 'A'
const TOKEN_NAME_B = 'B'
const SYMBOL = 'XXX'
const DECIMALS = 18
const SUPPLY_LO = 100000
const SUPPLY_HI = 0

### ============= set-up =============

@external
func __setup__{syscall_ptr : felt*}():
    alloc_locals
    
    tempvar token_a
    tempvar token_b
    tempvar tempest_amm
    %{  
        ids.token_a = deploy_contract(
            "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo", 
            [ids.TOKEN_NAME_A, ids.SYMBOL, ids.DECIMALS, ids.SUPPLY_LO, ids.SUPPLY_HI, ids.USER]).contract_address
        context.token_a = ids.token_a

        ids.token_b = deploy_contract(
            "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo", 
            [ids.TOKEN_NAME_B, ids.SYMBOL, ids.DECIMALS, ids.SUPPLY_LO, ids.SUPPLY_HI, ids.USER]).contract_address
        context.token_b = ids.token_b

        ids.tempest_amm = deploy_contract(
            "./src/tempest.cairo", 
            [ids.token_a, ids.token_b]).contract_address
        context.tempest_amm = ids.tempest_amm
    %}

    %{ stop_pranks = [start_prank(ids.USER, contract) for contract in [ids.tempest_amm, ids.token_a, ids.token_b] ] %}
    # Setup contracts with admin account
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return()
end

@external
func test_mint{
        syscall_ptr : felt*,
        range_check_ptr,
}():
    alloc_locals
    
    tempvar tempest_amm
    %{ ids.tempest_amm = context.tempest_amm %}
    
    tempvar token_a
    %{ ids.token_a = context.token_a %} 
    
    tempvar token_b
    %{ ids.token_b = context.token_b %}

    %{ stop_prank_callable = start_prank(ids.USER, ids.token_a) %}

    let (caller_address) = get_caller_address()  
    let amount = Uint256(100, 0) 
    
    IERC20.transfer(
        contract_address=token_a,
        recipient=tempest_amm,
        amount=amount,
    )
        
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.USER, ids.token_b) %}

    IERC20.transfer(
        contract_address=token_b, 
        recipient=tempest_amm,
        amount=amount,
    )
   
    %{ stop_prank_callable() %}

    %{ stop_prank_callable = start_prank(ids.USER, ids.tempest_amm) %}

    ITempest.mint(tempest_amm, 1)

    IERC20.approve(
        contract_address=token_a,
        spender=tempest_amm,
        amount=amount,
    )

    IERC20.approve(
        contract_address=token_b,
        spender=tempest_amm,
        amount=amount,
    )

    ITempest.swap(tempest_amm, 1, 2, amount)

    %{ stop_prank_callable() %}
    
    return()
end

### ====== external-contracts ========

namespace tempest_amm:
    
    func deployed() -> (tempest_amm : felt):
        tempvar tempest_amm
        %{ ids.tempest_amm = context.tempest_amm %}
        return (tempest_amm)
    end

    func mint{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(account_id : felt) -> (liquidity : Uint256):
    %{ stop_prank = start_prank(ids.USER, ids.tempest_amm) %}

    const amount = Uint256(1000, 0)

    let (liquidity) = ITempest.mint(tempest_amm, amount)

    return(liquidity)
    end

end

### ======== token-contracts =========

namespace token_a_instance:

    func deployed() -> (token_contract : felt):
        tempvar token_contract
        %{ ids.token_a = context.token_a %}
        return (token_contract)
    end
end

namespace token_b_instance:
    
    func deployed() -> (token_contract : felt):
        tempvar token_contract
        %{ ids.token_a = context.token_a %}
        return (token_contract)
    end
end