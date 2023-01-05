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
        // First transaction for initializing test
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            Track::test_init(test_scenario::ctx(&mut scenario_val))
        };
        // second transaction to verify service and servicetracker created from init
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            let service = test_scenario::take_immutable<Service>(&mut scenario_val);
            Debug::print(&service);
            test_scenario::return_immutable(service);
            let strack = test_scenario::take_from_sender<ServiceTracker>(&mut scenario_val);
            assert!(accounts_created(&strack)==0,1);
            Debug::print(&strack);
            test_scenario::return_to_sender(&mut scenario_val,strack)

        };
        // third transaction to create a new tracker account
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            let service = test_scenario::take_immutable<Service>(&mut scenario_val);
            let strack = test_scenario::take_from_address<ServiceTracker>(&mut scenario_val, admin);
            Track::create_account(
                &service,
                &mut strack,
                user,
                test_scenario::ctx(&mut scenario_val));
            assert!(accounts_created(&strack)==1,1);
            Debug::print(&strack);
            test_scenario::return_to_address(admin, strack);
            test_scenario::return_immutable(service);
        };
        // Third step 2 Add both dynamic and dynamic object fields
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            let strack = test_scenario::take_from_address<ServiceTracker>(&mut scenario_val, admin);
            Track::set_dynamic_field(&mut strack, test_scenario::ctx(&mut scenario_val));
            Debug::print(&strack);
            test_scenario::return_to_address(admin, strack);
        };
        // Third step 3 Add both dynamic and dynamic object fields
        test_scenario::next_tx(&mut scenario_val, admin);
        {
            let strack = test_scenario::take_from_address<ServiceTracker>(&mut scenario_val, admin);
            Debug::print(&strack);
            Track::set_dynamic_object_field(&mut strack, test_scenario::ctx(&mut scenario_val));
            Debug::print(&strack);
            test_scenario::return_to_address(admin, strack);
        };
        // Fourth transaction to manipulate the accumulator
        test_scenario::next_tx(&mut scenario_val,user);
        {
            let accum = test_scenario::take_from_sender<Tracker>(&mut scenario_val);
            // Should be emptry
            // Debug::print(&accum);
            Track::add_value(&mut accum, 1u8, test_scenario::ctx(&mut scenario_val));
            // Should have 1
            // Debug::print(&accum);
            Track::add_values(&mut accum, vector[2u8,3u8,4u8], test_scenario::ctx(&mut scenario_val));
            // Should have 4
            // Debug::print(&accum);
            Track::remove_value(&mut accum, 3u8, test_scenario::ctx(&mut scenario_val));
            // Should have 3 items with 3u8 entity missing
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
            // Debug::print(&object);
            test_scenario::return_to_sender(&mut scenario_val, object)
        };
    test_scenario::end(scenario_val);
    }

}