/// The `Genesis` module defines the Move initialization entry point of the Diem framework
/// when executing from a fresh state.
///
/// > TODO: Currently there are a few additional functions called from Rust during genesis.
/// > Document which these are and in which order they are called.
module DiemFramework::Genesis {
    use DiemFramework::AccountFreezing;
    use DiemFramework::ChainId;
    // use DiemFramework::XUS; //////// 0L ////////
    use DiemFramework::DualAttestation;
    // use DiemFramework::XDX; //////// 0L ////////
    use DiemFramework::Diem;
    use DiemFramework::DiemAccount;
    use DiemFramework::DiemBlock;
    use DiemFramework::DiemConfig;
    use DiemFramework::DiemConsensusConfig;
    use DiemFramework::DiemSystem;
    use DiemFramework::DiemTimestamp;
    use DiemFramework::DiemTransactionPublishingOption;
    use DiemFramework::DiemVersion;
    use DiemFramework::TransactionFee;
    use DiemFramework::DiemVMConfig;
    use DiemFramework::ParallelExecutionConfig;
    use DiemFramework::ValidatorConfig;
    use DiemFramework::ValidatorOperatorConfig;
    use Std::Signer;
    use Std::Vector;
    use DiemFramework::Stats;
    use DiemFramework::ValidatorUniverse;
    use DiemFramework::GAS;
    use DiemFramework::AutoPay;
    use DiemFramework::Oracle;
    use Std::Hash;
    // use DiemFramework::FullnodeSubsidy;
    use DiemFramework::Epoch;
    use DiemFramework::TowerState;
    use DiemFramework::Wallet;
    use DiemFramework::Migrations;  
    // use DiemFramework::Testnet; 

    /// Initializes the Diem framework.
    fun initialize(
        dr_account: signer,
        // tc_account: signer, //////// 0L ////////
        dr_auth_key: vector<u8>,
        // tc_auth_key: vector<u8>, //////// 0L ////////
        initial_script_allow_list: vector<vector<u8>>,
        is_open_module: bool,
        instruction_schedule: vector<u8>,
        native_schedule: vector<u8>,
        chain_id: u8,
        initial_diem_version: u64,
        consensus_config: vector<u8>,
    ) {
        initialize_internal(
            &dr_account,
            // &tc_account, /////// 0L /////////
            dr_auth_key,
            // tc_auth_key, /////// 0L /////////
            initial_script_allow_list,
            is_open_module,
            instruction_schedule,
            native_schedule,
            chain_id,
            initial_diem_version,
            consensus_config,
        )
    }

    /// Initializes the Diem Framework. Internal so it can be used by both genesis code, and for testing purposes
    fun initialize_internal(
        dr_account: &signer,
        // tc_account: &signer, /////// 0L /////////
        dr_auth_key: vector<u8>,
        // tc_auth_key: vector<u8>, /////// 0L /////////
        initial_script_allow_list: vector<vector<u8>>,
        is_open_module: bool,
        instruction_schedule: vector<u8>,
        native_schedule: vector<u8>,
        chain_id: u8,
        initial_diem_version: u64,
        consensus_config: vector<u8>,
    ) {
        DiemAccount::initialize(dr_account, x"00000000000000000000000000000000");

        ChainId::initialize(dr_account, chain_id);

        // On-chain config setup
        DiemConfig::initialize(dr_account);

        // Consensus config setup
        DiemConsensusConfig::initialize(dr_account);

        // Parallel execution config setup
        ParallelExecutionConfig::initialize_parallel_execution(dr_account);

        // Currency setup
        Diem::initialize(dr_account);

        /////// 0L /////////
        // // Currency setup
        // XUS::initialize(dr_account, tc_account);
        // XDX::initialize(dr_account, tc_account);
        GAS::initialize(dr_account);

        AccountFreezing::initialize(dr_account);
        TransactionFee::initialize(dr_account); /////// 0L /////////

        DiemSystem::initialize_validator_set(dr_account);
        DiemVersion::initialize(dr_account, initial_diem_version);
        DualAttestation::initialize(dr_account);
        DiemBlock::initialize_block_metadata(dr_account);

        /////// 0L /////////
        // DiemAccount::create_burn_account(dr_account, x"00000000000000000000000000000000");
        // Outside of testing, brick the diemroot account.
        if (chain_id == 1 || chain_id == 7) {
            dr_auth_key = Hash::sha3_256(b"Protests rage across the nation");
        };

        // Rotate auth keys for DiemRoot and TreasuryCompliance accounts to the given
        // values
        let dr_rotate_key_cap = DiemAccount::extract_key_rotation_capability(dr_account);
        DiemAccount::rotate_authentication_key(&dr_rotate_key_cap, dr_auth_key);
        DiemAccount::restore_key_rotation_capability(dr_rotate_key_cap);

        /////// 0L /////////
        // let tc_rotate_key_cap = DiemAccount::extract_key_rotation_capability(tc_account);
        // DiemAccount::rotate_authentication_key(&tc_rotate_key_cap, tc_auth_key);
        // DiemAccount::restore_key_rotation_capability(tc_rotate_key_cap);

        DiemTransactionPublishingOption::initialize(
            dr_account,
            initial_script_allow_list,
            is_open_module,
        );

        DiemVMConfig::initialize(
            dr_account,
            instruction_schedule,
            native_schedule,
            chain_id /////// 0L /////////
        );

        DiemConsensusConfig::set(dr_account, consensus_config);

        /////// 0L /////////
        // let tc_rotate_key_cap = DiemAccount::extract_key_rotation_capability(tc_account);
        // DiemAccount::rotate_authentication_key(&tc_rotate_key_cap, tc_auth_key);
        // DiemAccount::restore_key_rotation_capability(tc_rotate_key_cap);
        Stats::initialize(dr_account);
        ValidatorUniverse::initialize(dr_account);
        AutoPay::initialize(dr_account);
        // FullnodeSubsidy::init_fullnode_sub(dr_account);
        Oracle::initialize(dr_account);
        TowerState::init_miner_list_and_stats(dr_account);
        TowerState::init_difficulty(dr_account);
        Wallet::init(dr_account);
        DiemAccount::vm_init_slow(dr_account);
        Migrations::init(dr_account);

        // After we have called this function, all invariants which are guarded by
        // `DiemTimestamp::is_operating() ==> ...` will become active and a verification condition.
        // See also discussion at function specification.
        DiemTimestamp::set_time_has_started(dr_account);
        Epoch::initialize(dr_account); /////// 0L /////////

        
        // if this is tesnet, fund the root account so the smoketests can run. They use PaymentScripts functions to test many things.
        // TODO(0L): make this only tun in testsnet. Though we need to make smoketest always initialize in test mode.
        // if (Testnet::is_testnet()) {
          let val = 10000000;
          DiemAccount::add_currency<GAS::GAS>(dr_account);
          let coin = Diem::mint<GAS::GAS>(dr_account, val);
          DiemAccount::vm_deposit_with_metadata(
            dr_account,
            @DiemRoot,
            coin,
            x"",
            x"",
          )

        // }
    }

    /// Sets up the initial validator set for the Diem network.
    /// The validator "owner" accounts, their UTF-8 names, and their authentication
    /// keys are encoded in the `owners`, `owner_names`, and `owner_auth_key` vectors.
    /// Each validator signs consensus messages with the private key corresponding to the Ed25519
    /// public key in `consensus_pubkeys`.
    /// Each validator owner has its operation delegated to an "operator" (which may be
    /// the owner). The operators, their names, and their authentication keys are encoded
    /// in the `operators`, `operator_names`, and `operator_auth_keys` vectors.
    /// Finally, each validator must specify the network address
    /// (see diem/types/src/network_address/mod.rs) for itself and its full nodes.
    fun create_initialize_owners_operators(
        dr_account: signer,
        owners: vector<signer>,
        owner_names: vector<vector<u8>>,
        owner_auth_keys: vector<vector<u8>>,
        consensus_pubkeys: vector<vector<u8>>,
        operators: vector<signer>,
        operator_names: vector<vector<u8>>,
        operator_auth_keys: vector<vector<u8>>,
        validator_network_addresses: vector<vector<u8>>,
        full_node_network_addresses: vector<vector<u8>>,
    ) {
        let num_owners = Vector::length(&owners);
        let num_owner_names = Vector::length(&owner_names);
        assert!(num_owners == num_owner_names, 0);
        let num_owner_keys = Vector::length(&owner_auth_keys);
        assert!(num_owner_names == num_owner_keys, 0);
        let num_operators = Vector::length(&operators);
        assert!(num_owner_keys == num_operators, 0);
        let num_operator_names = Vector::length(&operator_names);
        assert!(num_operators == num_operator_names, 0);
        let num_operator_keys = Vector::length(&operator_auth_keys);
        assert!(num_operator_names == num_operator_keys, 0);
        let num_validator_network_addresses = Vector::length(&validator_network_addresses);
        assert!(num_operator_keys == num_validator_network_addresses, 0);
        let num_full_node_network_addresses = Vector::length(&full_node_network_addresses);
        assert!(num_validator_network_addresses == num_full_node_network_addresses, 0);

        let i = 0;
        let dummy_auth_key_prefix = x"00000000000000000000000000000000";
        while (i < num_owners) {
            let owner = Vector::borrow(&owners, i);
            let owner_address = Signer::address_of(owner);
            let owner_name = *Vector::borrow(&owner_names, i);
            // create each validator account and rotate its auth key to the correct value
            DiemAccount::create_validator_account(
                &dr_account, owner_address, copy dummy_auth_key_prefix, owner_name
            );

            let owner_auth_key = *Vector::borrow(&owner_auth_keys, i);
            let rotation_cap = DiemAccount::extract_key_rotation_capability(owner);
            DiemAccount::rotate_authentication_key(&rotation_cap, owner_auth_key);
            DiemAccount::restore_key_rotation_capability(rotation_cap);

            let operator = Vector::borrow(&operators, i);
            let operator_address = Signer::address_of(operator);
            let operator_name = *Vector::borrow(&operator_names, i);
            // create the operator account + rotate its auth key if it does not already exist
            if (!DiemAccount::exists_at(operator_address)) {
                DiemAccount::create_validator_operator_account(
                    &dr_account, operator_address, copy dummy_auth_key_prefix, copy operator_name
                );
                let operator_auth_key = *Vector::borrow(&operator_auth_keys, i);
                let rotation_cap = DiemAccount::extract_key_rotation_capability(operator);
                DiemAccount::rotate_authentication_key(&rotation_cap, operator_auth_key);
                DiemAccount::restore_key_rotation_capability(rotation_cap);
            };
            // assign the operator to its validator
            assert!(ValidatorOperatorConfig::get_human_name(operator_address) == operator_name, 0);
            ValidatorConfig::set_operator(owner, operator_address);

            // use the operator account set up the validator config
            let validator_network_address = *Vector::borrow(&validator_network_addresses, i);
            let full_node_network_address = *Vector::borrow(&full_node_network_addresses, i);
            let consensus_pubkey = *Vector::borrow(&consensus_pubkeys, i);
            ValidatorConfig::set_config(
                operator,
                owner_address,
                consensus_pubkey,
                validator_network_address,
                full_node_network_address
            );

            // finally, add this validator to the validator set
            DiemSystem::add_validator(&dr_account, owner_address);

            i = i + 1;
        }
    }

    /// For verification of genesis, the goal is to prove that all the invariants which
    /// become active after the end of this function hold. This cannot be achieved with
    /// modular verification as we do in regular continuous testing. Rather, this module must
    /// be verified **together** with the module(s) which provides the invariant.
    ///
    /// > TODO: currently verifying this module together with modules providing invariants
    /// > (see above) times out. This can likely be solved by making more of the initialize
    /// > functions called by this function opaque, and prove the according invariants locally to
    /// > each module.
    spec initialize {
        /// Assume that this is called in genesis state (no timestamp).
        requires DiemTimestamp::is_genesis();
    }

    #[test_only]
    public fun setup(dr_account: &signer, tc_account: &signer) {
        initialize_internal(
            dr_account,
            tc_account,
            x"0000000000000000000000000000000000000000000000000000000000000000",
            x"0000000000000000000000000000000000000000000000000000000000000000",
            Vector::empty(), // not needed for unit tests
            false, // not needed for unit tests
            x"", // instruction_schedule not needed for unit tests
            x"", // native schedule not needed for unit tests
            4u8, // TESTING chain ID
            0,
            Vector::empty(),
        )
    }
}
