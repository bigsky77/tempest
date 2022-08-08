### ==================================
###           FACTORY TESTS
### ==================================

%lang starknet

### ========== dependencies ==========

from src.interfaces.ITempest import ITempest

### =========== constants ============   

const CONTRACT_CLASS_HASH = 0x755522f06ee7520e34136cf8681bc44e0da8cd80a01c45c24d816217bef565

### ============= set-up =============

@external
func __setup__{syscall_ptr : felt*}():
    alloc_locals

    tempvar tempest_amm
    tempvar factory
    %{
        ids.factory = deploy_contract(
            "./src/factory.cairo",
            [ids.CONTRACT_CLASS_HASH] 
            ).contract_address 

        context.factory = ids.factory
    %}

    return()
end

### ============= tests ==============

@external
func basic_santiy{
        syscall_ptr : felt*,
        range_check_ptr,
}():
    alloc_locals

    tempvar x = 1
    tempvar y = 2
    assert 3 = x + y

    return()
end
