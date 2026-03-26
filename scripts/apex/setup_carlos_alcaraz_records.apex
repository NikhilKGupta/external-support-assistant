// Step 1 of 2: Create Account (Nike) + Contact (Carlos Alcaraz)
// Run: sf apex run --file scripts/apex/setup_carlos_alcaraz_records.apex -o dhurandhar
// Copy the Contact ID from debug output, then set it in setup_carlos_alcaraz_user.apex

Account acct = new Account(Name = 'Nike');
insert acct;
System.debug('### Account: ' + acct.Id);

Contact c = new Contact(
    FirstName   = 'Carlos',
    LastName    = 'Alcaraz',
    Email       = 'nikhilgupta+carlosalcaraznike@salesforce.com',
    AccountId   = acct.Id,
    Department  = 'HCM Administration',
    Title       = 'Workday Administrator'
);
insert c;
System.debug('### Contact: ' + c.Id);
System.debug('### Done — paste Contact ID into setup_carlos_alcaraz_user.apex');
