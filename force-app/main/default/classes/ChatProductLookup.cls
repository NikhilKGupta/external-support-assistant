public class ChatProductLookup {
    public class Request {
        @InvocableVariable(
            label='Query'
            description='Product search query from the customer'
            required=true
        )
        public String query;
    }
    public class Result {
        @InvocableVariable(
            label='Product Name'
            description='Name of the product'
        )
        public String productName;
        @InvocableVariable(
            label='Product Details'
            description='Product description and details'
        )
        public String productDetails;
        @InvocableVariable(
            label='Availability'
            description='Product availability status'
        )
        public String availability;
        @InvocableVariable(
            label='Product URL'
            description='URL link to the product page'
        )
        public String productUrl;
    }
    @InvocableMethod(
        label='Chat Product Lookup'
        description='Look up product information optimized for chat channel with clickable links'
    )
    public static List<Result> lookup(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result r = new Result();
            r.productName = 'Enterprise Suite Pro';
            r.productDetails = 'An all-in-one enterprise solution with CRM, analytics, and automation. Includes 24/7 support and quarterly feature updates.';
            r.availability = 'In Stock - Available for immediate provisioning';
            r.productUrl = 'https://example.com/products/enterprise-suite-pro';
            results.add(r);
        }
        return results;
    }
}
