### ==================================
###           FACTORY TESTS
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.ITempest import ITempest
from src.interfaces.IFactory import IFactory
from starkware.cairo.common.cairo_builtins import HashBuiltin

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
func __setup__{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals

    tempvar tempest_class_hash 
    tempvar factory
    tempvar token_a
    tempvar token_b
    %{
        ids.tempest_class_hash = declare("./src/tempest.cairo").class_hash
        context.tempest_class_hash = ids.tempest_class_hash

        ids.factory = deploy_contract(
            "./src/factory.cairo",
            [ids.tempest_class_hash] 
            ).contract_address 
        context.factory = ids.factory

        ids.token_a = deploy_contract(
            "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo", 
            [ids.TOKEN_NAME_A, ids.SYMBOL, ids.DECIMALS, ids.SUPPLY_LO, ids.SUPPLY_HI, ids.USER]).contract_address
        context.token_a = ids.token_a

        ids.token_b = deploy_contract(
            "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo", 
            [ids.TOKEN_NAME_B, ids.SYMBOL, ids.DECIMALS, ids.SUPPLY_LO, ids.SUPPLY_HI, ids.USER]).contract_address
        context.token_b = ids.token_b
    %}
 
    %{ stop_pranks = [start_prank(ids.USER, contract) for contract in [ids.factory, ids.token_a, ids.token_b] ] %}
    # Setup contracts with admin account
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return()
end

### ============= tests ==============

@external
func test_create_pair{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
}():
    alloc_locals

    let (factory) = factory_instance.deployed()
    let (token_a) = token_a_instance.deployed()
    let (token_b) = token_b_instance.deployed()

    IFactory.create_pair(factory, token_a,  token_b)

    return()
end

### ======= contract-instances ======= */

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


