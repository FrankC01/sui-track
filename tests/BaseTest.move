#[test_only]
module SuiTrack::BaseTest {
    //use Std::ASCII;
    use Sui::TestScenario;
    use Std::Debug;
    use SuiTrack::Base::{Self as Track, Service, ServiceTracker, Tracker};
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
        // second transaction to check if the forge has been created
        // and has initial value of zero swords created
        TestScenario::next_tx(scenario, &ADMIN_ADDRESS);
        {
            let service = TestScenario::take_immutable<Service>(scenario);
            let strack = TestScenario::take_owned<ServiceTracker>(scenario);

            TestScenario::return_owned(scenario, strack);
            TestScenario::return_immutable(scenario, service)
        };

        TestScenario::next_tx(scenario, &ADMIN_ADDRESS);
        {
            let service = TestScenario::take_immutable<Service>(scenario);
            let strack = TestScenario::take_owned<ServiceTracker>(scenario);

            assert!(accounts_created(&strack)==0,1);
            Track::create_account(
                TestScenario::borrow(&service),
                &mut strack,
                USER_ADDRESS,
                TestScenario::ctx(scenario));
            assert!(accounts_created(&strack)==1,1);

            TestScenario::return_owned(scenario, strack);
            TestScenario::return_immutable(scenario, service);
        };

        TestScenario::next_tx(scenario,&USER_ADDRESS);
        {
            let accum = TestScenario::take_owned<Tracker>(scenario);
            Debug::print(&accum);
            TestScenario::return_owned(scenario, accum)
        }
    }

}