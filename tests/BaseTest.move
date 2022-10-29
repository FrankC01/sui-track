#[test_only]
module suitrack::basetest {
    use sui::transfer;
    use sui::test_scenario::{Self};
    use std::debug::{Self as Debug};
    use suitrack::base::{Self as Track,
    Service,
    ServiceTracker,
    Tracker,
    accounts_created
    };


    #[test]
    public entry fun test_basic_pass() {
    // create test address representing tracking admin
        let admin:address = @0xABBA;
        let user:address = @0xBAAB;
        let scenario_val = test_scenario::begin(admin);
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            Debug::print(&admin);
            Track::test_init(test_scenario::ctx(&mut scenario_val));
        };
        // second transaction to check if the meta tracker has been created
        // and has initial value of zero trackers created
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            let strack = test_scenario::take_from_sender<ServiceTracker>(&mut scenario_val);
            assert!(accounts_created(&strack)==0,1);
            Debug::print(&strack);
            test_scenario::return_to_sender(&mut scenario_val,strack);
        };

        // third transaction to create a new tracker account
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            let service = test_scenario::take_immutable<Service>(&mut scenario_val);
            let strack = test_scenario::take_from_address<ServiceTracker>(&mut scenario_val, admin);
            Debug::print(&service);
            Debug::print(&strack);
            Track::create_account(
                &service,
                &mut strack,
                user,
                test_scenario::ctx(&mut scenario_val));
            assert!(accounts_created(&strack)==1,1);
            test_scenario::return_to_address(admin, strack);
            test_scenario::return_immutable(service);
        };

        // Fourth transaction to manipulate the accumulator
        test_scenario::next_tx(&mut scenario_val,user);
        {
            let accum = test_scenario::take_from_sender<Tracker>(&mut scenario_val);
            Debug::print(&accum);
            Track::add_value(&mut accum, 1u8, test_scenario::ctx(&mut scenario_val));
            Debug::print(&accum);
            Track::add_values(&mut accum, vector[2u8,3u8,4u8], test_scenario::ctx(&mut scenario_val));
            Debug::print(&accum);
            Track::remove_value(&mut accum, 3u8, test_scenario::ctx(&mut scenario_val));
            Debug::print(&accum);
            test_scenario::return_to_sender(&mut scenario_val, accum)
        };
        test_scenario::next_tx(&mut scenario_val, user);
        {
            let object = test_scenario::take_from_sender<Tracker>(&mut scenario_val);
            transfer::transfer(object, admin);
        };
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            let object = test_scenario::take_from_sender<Tracker>(&mut scenario_val);
            Debug::print(&object);
            test_scenario::return_to_sender(&mut scenario_val, object)
        };
    test_scenario::end(scenario_val);
    }

}