#[test_only]
module suitrack::basetest {
    //use Std::ASCII;
    use sui::test_scenario::{Self};
    use std::debug;
    use suitrack::base::{Self as Track, Service, ServiceTracker, Tracker, accounts_created};
    //use Sui::ID::{VersionedID};

    // create test address representing tracking admin
    const ADMIN_ADDRESS:address = @0xABBA;
    const USER_ADDRESS:address = @0xBAAB;

    #[test]
    public entry fun test_basic_pass() {
        // first transaction to emulate module initialization
        let scenario = &mut test_scenario::begin(&ADMIN_ADDRESS);
        {
            Track::test_init(test_scenario::ctx(scenario));

        };
        // second transaction to check if the meta tracker has been created
        // and has initial value of zero trackers created
        test_scenario::next_tx(scenario, &ADMIN_ADDRESS);
        {
            let strack = test_scenario::take_owned<ServiceTracker>(scenario);
            assert!(accounts_created(&strack)==0,1);
            test_scenario::return_owned(scenario, strack);
        };

        // third transaction to create a new tracker account
        test_scenario::next_tx(scenario, &ADMIN_ADDRESS);
        {
            let service = test_scenario::take_immutable<Service>(scenario);
            let strack = test_scenario::take_owned<ServiceTracker>(scenario);

            Track::create_account(
                test_scenario::borrow(&service),
                &mut strack,
                USER_ADDRESS,
                test_scenario::ctx(scenario));
            assert!(accounts_created(&strack)==1,1);

            test_scenario::return_owned(scenario, strack);
            test_scenario::return_immutable(scenario, service);
        };

        // Fourth transaction to manipulate the accumulator
        test_scenario::next_tx(scenario,&USER_ADDRESS);
        {
            let accum = test_scenario::take_owned<Tracker>(scenario);
            debug::print(&accum);
            Track::add_value(&mut accum, 1u8, test_scenario::ctx(scenario));
            debug::print(&accum);
            Track::add_values(&mut accum, vector[2u8,3u8,4u8], test_scenario::ctx(scenario));
            debug::print(&accum);
            Track::remove_value(&mut accum, 3u8, test_scenario::ctx(scenario));
            debug::print(&accum);
            test_scenario::return_owned(scenario, accum)
        }
    }

}