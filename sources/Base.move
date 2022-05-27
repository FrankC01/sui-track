
/// Base module for hashblock
module SuiTrack::Base {
    // use Sui::Coin::{Self, Coin};

    use Sui::ID::VersionedID;
    use Sui::Transfer;
    use Sui::TxContext::{Self, TxContext};

    // Error codes
    /// Invalid admin
    const ServiceNotOwner: u64 = 0;

    /// Master service setup at deploytime
    struct Service has key {
        id: VersionedID,
        admin: address,
    }

    /// Validate that the address provided is the
    /// owner of the program
    fun is_owner(self: &Service, owner:address): bool {
        self.admin == owner
    }

    /// Master service tracker
    struct ServiceTracker has key, store {
        id: VersionedID,
        initialized: bool,
        count_accounts: u64,
    }


    /// Bump number of accounts created
    fun increase_account(self: &mut ServiceTracker) {
        self.count_accounts = self.count_accounts + 1;
    }

    /// Return the number of accounts created
    public fun accounts_created(self: &ServiceTracker) : u64 {
        self.count_accounts
    }

    /// Individual account trackers
    struct Tracker has key {
        id: VersionedID,
        initialized: bool,
        owner: address,
    }

    /// Initialize new deployment
    fun init(ctx: &mut TxContext) {
        let sender = TxContext::sender(ctx);
        let id = TxContext::new_id(ctx);
        // Establish authority and make it immutable
        Transfer::freeze_object(Service {
            id,
            admin: sender,
        });
        // Authority tracker
        Transfer::transfer(
            ServiceTracker {
                id: TxContext::new_id(ctx),
                initialized: true,
                count_accounts: 0,
            },
            TxContext::sender(ctx)
        )
    }

    // Entrypoint: Initialize user account
    public(script) fun create_account(
        //use Std::Debug;
        service: &Service,
        strack: &mut ServiceTracker,
        recipient: address,
        ctx: &mut TxContext
        ) {
        // Verify ownership
        let admin = TxContext::sender(ctx);
        assert!(is_owner(service, admin), ServiceNotOwner);

        // Increase the account count
        increase_account(strack);

        // Create unique account tracker for reeipient
        Transfer::transfer(
            Tracker {
                id: TxContext::new_id(ctx),
                initialized: true,
                owner: recipient,
            },
            recipient
        );
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }

}