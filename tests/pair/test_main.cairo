### ==================================
###           TEMPEST TESTS
### ==================================

%lang starknet

### ========== dependencies ==========

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_signed_nn_le, uint256_add, uint256_pow2, uint256_sub, uint256_unsigned_div_rem, uint256_mul, uint256_sqrt, uint256_eq, uint256_lt
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.library import ERC20
from src.interfaces.ITempest import ITempest
from src.interfaces.IRouter import IRouter

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

### ============= tests ==============

@external
func test_swap{
        syscall_ptr : felt*,
        range_check_ptr,
}():
    alloc_locals

    let (local tempest) = tempest_instance.deployed()
    let (local router) = router_instance.deployed()
    let (local factory) = factory_instance.deployed()

    let (local token_a) = token_a_instance.deployed()
    let (local token_b) = token_b_instance.deployed()

    
    
    return()
end

### ======== token-contracts =========
namespace tempest_instance:
    func deployed() -> (tempest_instance : felt):
        tempvar tempest_amm
        %{ 
            ids.tempest_amm = context.tempest_amm
        %}
        return(tempest_instance=tempest_amm)
    end
end

namespace router_instance:
    func deployed() -> (router_instance : felt):
        tempvar router
        %{
            ids.router = context.router
        %}
        return(router_instance=router)
    end
end

namespace factory_instance:
    func deployed() -> (factory_instance : felt):
        tempvar factory
        %{
            ids.factory = context.factory
        %}
        return(factory_instance=factory)
    end
end

namespace token_a_instance:
    func deployed() -> (token_contract : felt):
        tempvar token_a
        %{ ids.token_a = context.token_a %}
        return (token_contract=token_a)
    end
end

namespace token_b_instance:
    func deployed() -> (token_contract : felt):
        tempvar token_b
        %{ ids.token_b = context.token_b %}
        return (token_contract=token_b)
    end
end


