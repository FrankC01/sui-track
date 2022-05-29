
/// Base module for hashblock
module SuiTrack::Base {
    // use Sui::Coin::{Self, Coin};
    use Std::Vector;
    use Sui::ID::VersionedID;
    use Sui::Transfer;
    use Sui::TxContext::{Self, TxContext};

    // Error codes
    /// Invalid admin
    const ServiceNotOwner: u64 = 0;
    /// Invalid tracker owner
    const TrackerNotOwner: u64 = 1;
    /// Does not contain value
    const DoesNotExist: u64 = 2;
    /// Wrong value removed
    const ValueDropMismatch: u64 = 3;

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
    struct ServiceTracker has key {
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
    struct Tracker has key  {
        id: VersionedID,
        initialized: bool,
        owner: address,
        accumulator: vector<u8>,
    }

    /// Validate that the address provided is the
    /// owner of the tracker
    fun is_owned_by(self: &Tracker, owner:address): bool {
        self.owner == owner
    }

    /// Get the accumulator length
    public fun stored_count(self: &Tracker) : u64 {
        Vector::length<u8>(&self.accumulator)
    }

    /// Add an element to the accumulator
    public fun add_to_store(self: &mut Tracker, value: u8) : u64 {
        Vector::push_back<u8>(&mut self.accumulator, value);
        stored_count(self)
    }

    /// Add a series of vaues to the accumulator
    public fun add_from(self: &mut Tracker, other:vector<u8>) {
        Vector::append<u8>(&mut self.accumulator, other);
    }

    /// Check accumulator contains value
    public fun has_value(self: &Tracker, value: u8) : bool {
        Vector::contains<u8>(&self.accumulator, &value)
    }

    /// Removes a value from the accumulator
    public fun drop_from_store(self: &mut Tracker, value: u8) : u8 {
        let (contained, idx) = Vector::index_of<u8>(&self.accumulator, &value);
        assert!(contained, DoesNotExist);
        Vector::remove<u8>(&mut self.accumulator, idx)
    }

    // Transaction Entry Points
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
                accumulator: vector[],
            },
            recipient
        );
    }

    /// Add single value to accumulator
    public(script) fun add_value(tracker: &mut Tracker, value: u8, ctx: &mut TxContext) {
        // Verify ownership
        let admin = TxContext::sender(ctx);
        assert!(is_owned_by(tracker, admin), TrackerNotOwner);
        add_to_store(tracker,value);
    }

    /// Add single value to accumulator
    public(script) fun remove_value(tracker: &mut Tracker, value: u8, ctx: &mut TxContext) {
        // Verify ownership
        let admin = TxContext::sender(ctx);
        assert!(is_owned_by(tracker, admin), TrackerNotOwner);
        assert!(drop_from_store(tracker, value) == value,ValueDropMismatch);

    }
    /// Add multiple values to accumulator
    public(script) fun add_values(tracker: &mut Tracker, values: vector<u8>, ctx: &mut TxContext) {
        let admin = TxContext::sender(ctx);
        assert!(is_owned_by(tracker, admin), TrackerNotOwner);
        add_from(tracker, values);
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }

}