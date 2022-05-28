#[test_only]
module SuiTrack::BaseTest {
    //use Std::ASCII;
    use Sui::TestScenario;
    use Std::Debug;
    use SuiTrack::Base::{Self as Track, Service, ServiceTracker, Tracker, accounts_created};
    //use Sui::ID::{VersionedID};

    // create test address representing tracking admin
    const ADMIN_ADDRESS:address = @0xABBA;
    const USER_ADDRESS:address = @0xBAAB;

    #[test]
    public(script) fun test_basic_pass() {
        // first transaction to emulate module initialization
        let scenario = &mut TestScenario::begin(&ADMIN_ADDRESS);
        {
            Track::test_init(TestScenario::ctx(scenario));

        };
        // second transaction to check if the meta tracker has been created
        // and has initial value of zero trackers created
        TestScenario::next_tx(scenario, &ADMIN_ADDRESS);
        {
            let strack = TestScenario::take_owned<ServiceTracker>(scenario);
            assert!(accounts_created(&strack)==0,1);
            TestScenario::return_owned(scenario, strack);
        };

        // third transaction to create a new tracker account
        TestScenario::next_tx(scenario, &ADMIN_ADDRESS);
        {
            let service = TestScenario::take_immutable<Service>(scenario);
            let strack = TestScenario::take_owned<ServiceTracker>(scenario);

            Track::create_account(
                TestScenario::borrow(&service),
                &mut strack,
                USER_ADDRESS,
                TestScenario::ctx(scenario));
            assert!(accounts_created(&strack)==1,1);

            TestScenario::return_owned(scenario, strack);
            TestScenario::return_immutable(scenario, service);
        };

        // Fourth transaction to add to the accumulator
        TestScenario::next_tx(scenario,&USER_ADDRESS);
        {
            let accum = TestScenario::take_owned<Tracker>(scenario);
            Debug::print(&accum);
            Track::add_value(&mut accum, 1u8, TestScenario::ctx(scenario));
            Debug::print(&accum);
            Track::add_values(&mut accum, vector[2u8,3u8,4u8], TestScenario::ctx(scenario));
            Debug::print(&accum);
            TestScenario::return_owned(scenario, accum)
        }
    }

}