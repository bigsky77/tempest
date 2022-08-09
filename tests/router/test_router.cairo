### ==================================
###           ROUTER TESTS
### ==================================

%lang starknet

### ========== dependencies ==========

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
func __setup__{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals

    tempvar factory
    tempvar router
    tempvar class_hash
    %{
        ids.tempest_class_hash = declare("./src/tempest.cairo").class_hash
        context.tempest_class_hash = ids.tempest_class_hash

        ids.factory = contract_deploy("./src/factory.cairo", [ids.class_hash]).contract_address
        context.factory = ids.factory

        ids.router = contract_deploy("./src/router.cairo", [ids.factory]).contract_address
        context.router = ids.router

        ids.token_a = deploy_contract(
            "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo", 
            [ids.TOKEN_NAME_A, ids.SYMBOL, ids.DECIMALS, ids.SUPPLY_LO, ids.SUPPLY_HI, ids.USER]).contract_address
        context.token_a = ids.token_a

        ids.token_b = deploy_contract(
            "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo", 
            [ids.TOKEN_NAME_B, ids.SYMBOL, ids.DECIMALS, ids.SUPPLY_LO, ids.SUPPLY_HI, ids.USER]).contract_address
        context.token_b = ids.token_b
    %}

    %{ stop_pranks = [start_prank(ids.USER, contract) for contract in [ids.router, ids.factory, ids.token_a, ids.token_b] ] %}
    # Setup contracts with admin account
    %{ [stop_prank() for stop_prank in stop_pranks] %}



   return() 
end


