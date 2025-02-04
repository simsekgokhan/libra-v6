//# init --validators Alice Bob Carol

//# run --admin-script --signers DiemRoot Alice
script {    
    use DiemFramework::TowerState;

    fun main(_dr: signer, sender: signer) {
        // Alice is the only one that can update her mining stats. 
        // Hence this first transaction.

        TowerState::test_helper_mock_mining(&sender, 5);
        // assert!(TowerState::get_count_in_epoch(@Alice) == 5, 7357300101011000);
    }
}
//check: EXECUTED

//# run --admin-script --signers DiemRoot DiemRoot
script {
    use DiemFramework::Stats;
    use Std::Vector;
    use DiemFramework::Cases;

    fun main(_dr: signer, sender: signer) {
        let sender = &sender;
        let voters = Vector::singleton<address>(@Alice);
        let i = 1;
        while (i < 16) {
            // Mock the validator doing work for 15 blocks, and stats being updated.
            Stats::process_set_votes(sender, &voters);
            i = i + 1;
        };

        assert!(Cases::get_case(sender, @Alice, 0 , 15) == 1, 7357300103011000);
    }
}
//check: EXECUTED
