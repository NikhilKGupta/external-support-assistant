// Inspect the SAML SSO config and Experience Site SSO linkage
SamlSsoConfig cfg = [
    SELECT Id, DeveloperName, AttributeFormat, AttributeName,
           Issuer, LoginUrl, OptionsUserProvisioning
    FROM SamlSsoConfig
    WHERE Id = '0LEHu000000DLWpOAO'
    LIMIT 1
];
System.debug('### DeveloperName: '     + cfg.DeveloperName);
System.debug('### AttributeFormat: '   + cfg.AttributeFormat);
System.debug('### AttributeName: '     + cfg.AttributeName);
System.debug('### Issuer: '            + cfg.Issuer);
System.debug('### LoginUrl: '          + cfg.LoginUrl);
System.debug('### UserProvisioning: '  + cfg.OptionsUserProvisioning);

// Check Carlos's user record
User carlos = [
    SELECT Id, Username, FederationIdentifier, IsActive, ProfileId, Profile.Name
    FROM User
    WHERE Username = 'nikhilgupta+carlosalcaraznike@salesforce.com'
    LIMIT 1
];
System.debug('### Carlos Profile: '    + carlos.Profile.Name);
System.debug('### Carlos FedId: '      + carlos.FederationIdentifier);

// Check which profiles are members of the Workday Resource Center (0DBHu0000005DoYOAU)
List<NetworkMemberGroup> groups = [
    SELECT Id, NetworkId
    FROM NetworkMemberGroup
    WHERE NetworkId = '0DBHu0000005DoYOAU'
];
System.debug('### Workday site NetworkMemberGroup count: ' + groups.size());
