
@import MercadoPagoSDK;
#import "MercadoPagoPlugin.h"

@interface UIColor (fromHex)
+ (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha;
@end
@implementation UIColor (fromHex)

#define MERCADO_PAGO_BASE_COLOR @"#30AFE2"

+ (UIColor *)colorwithHexString:(NSString *)hexStr alpha:(CGFloat)alpha;
{
    unsigned int hexint = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    [scanner setCharactersToBeSkipped:[NSCharacterSet
                                       characterSetWithCharactersInString:@"#"]];
    [scanner scanHexInt:&hexint];
    
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    
    return color;
}

@end
@implementation MercadoPagoPlugin

@synthesize cho;

- (void)startFlavorTwo:(CDVInvokedUrlCommand*)command
{
    [self showCardWithoutInstallments:command];

  
}

- (void) startSavedCards:(CDVInvokedUrlCommand*)command {
    
    //Get Customer
    NSData *customerData = [[[command arguments] objectAtIndex:0] dataUsingEncoding:NSUTF8StringEncoding];
    id customerJson = [NSJSONSerialization JSONObjectWithData:customerData options:0 error:nil];
    Customer *customer = [Customer fromJSON:customerJson];
    
    //Get Decoration Preference Color
    UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:1] alpha:1];
    
    //Get Black Font Bool Value
    BOOL blackFont = [[[command arguments] objectAtIndex:2]boolValue];
    
    //Get Title
    NSString *title = [[command arguments] objectAtIndex:3];
    
    //Get Footer Text
    NSString *footerText = [[command arguments] objectAtIndex:4];
    
    //Get Confirm Prompt Text
    NSString *confirmPromptText = [[command arguments] objectAtIndex:5];
    
    //Get Mode
//    NSString *mode = [[command arguments] objectAtIndex:6];
    
    //Get Payment Preference
    NSData *data = [[[command arguments] objectAtIndex:7] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    PaymentPreference *paymentPref = [PaymentPreference fromJSON:json];
    
    DecorationPreference* dp = [[DecorationPreference alloc] initWithBaseColor:color fontName:nil fontLightName:nil];
    if (blackFont){
        [dp enableDarkFont];
    }else {
        [dp enableLightFont];
    }
    
    [MercadoPagoCheckout setDecorationPreference:dp];
    
    CardsAdminViewModel* vm = [[CardsAdminViewModel alloc] initWithCards:customer.cards extraOptionTitle:footerText confirmPromptText: confirmPromptText];
    [vm setTitleWithTitle:title];
    
    CardsAdminViewController* vc = [[CardsAdminViewController alloc] initWithViewModel:vm callback:^(Card * card) {
        
        NSString* callbackId = [command callbackId];
        
        NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
        
        if (card != nil) {
            NSString *jsonCard = [card toJSONString];
            [mpResponse setObject:jsonCard forKey:@"card"];
        }
        
//        if (card.paymentMethod != nil ){
//            NSString *jsonPaymentMethod = [card.paymentMethod toJSONString];
//            [mpResponse setObject:jsonPaymentMethod forKey:@"payment_method"];
//        }
//        
//        if (card.issuer != nil ){
//            NSString *jsonIssuer = [card.issuer toJSONString];
//            [mpResponse setObject:jsonIssuer forKey:@"issuer"];
//        }
        
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
        NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: myString];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
    
    [self showInNavigationController:vc];
}

- (void) getCustomer:(CDVInvokedUrlCommand*)command {

    //Get Merchant Base Url
    NSString *merchantBaseUrl = [[command arguments] objectAtIndex:0];
    
    //Get Merchant Get Customer Uri
    NSString *merchantGetCustomerUri = [[command arguments] objectAtIndex:1];
    
    //Get Merchant Access Token
    NSString *merchantAccessToken = [[command arguments] objectAtIndex:2];
    
    ServicePreference* servicePref = [[ServicePreference alloc] init];
    NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
    [params setValue:merchantAccessToken forKey:@"merchant_access_token"];
    [MercadoPagoContext setMerchantAccessTokenWithMerchantAT:merchantAccessToken];
    [servicePref setGetCustomerWithBaseURL:merchantBaseUrl URI:merchantGetCustomerUri additionalInfo:params];
    [MercadoPagoCheckout setServicePreference:servicePref];
    
    //Get CallbackID
    NSString* callbackId = [command callbackId];

    //Get Customer
    [MerchantServer getCustomer:^(Customer * cust) {
        CDVPluginResult* result = [CDVPluginResult
        resultWithStatus:CDVCommandStatus_OK
        messageAsString:[cust toJSONString]];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    } failure:^(NSError * error) {
        [self.commandDelegate sendPluginResult:nil callbackId:callbackId];
    }];
}

- (void)startCardSelection:(CDVInvokedUrlCommand*)command {
    
    //Get Public Key
    NSString *pk = [[command arguments] objectAtIndex:0];

    //Get Site ID
    NSString *siteID = [[command arguments] objectAtIndex:1];
    
    //Get Amount
    double amount = [[[command arguments] objectAtIndex:2]doubleValue];
    
    //Get Merchant Base Url
    NSString *merchantBaseUrl = [[command arguments] objectAtIndex:3];
    
    //Get Merchant Get Customer Uri
    NSString *merchantGetCustomerUri = [[command arguments] objectAtIndex:4];
    
    //Get Merchant Access Token
    NSString *merchantAccessToken = [[command arguments] objectAtIndex:5];
    
    //Get Decoration Preference Color
    UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:6] alpha:1];
    
    //Get Black Font Bool Value
    BOOL blackFont = [[[command arguments] objectAtIndex:7]boolValue];
    
    //Get Installments Enabled Bool Value
    BOOL installmentsEnabled = [[[command arguments] objectAtIndex:8]boolValue];

    
    //Get Payment Preference
    NSData *data = [[[command arguments] objectAtIndex:9] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    PaymentPreference *paymentPref = [PaymentPreference fromJSON:json];
    paymentPref.excludedPaymentTypeIds = [NSSet setWithObjects:@"atm", @"ticket", @"bank_transfer", @"debit_card", @"prepaid_card", @"digital_currency", @"account_money", nil];

    if (!installmentsEnabled) {
        [paymentPref setDefaultInstallments:1];
    }
    
    
    
    //Create Checkout Preference
    Payer *payer = [[Payer alloc] initWith_id:@"payer_id" email:@"payer_email" type:nil identification:nil entityType:nil];
    Item *item = [[Item alloc] initWith_id:@"item_id" title:@"item_title" quantity:1 unitPrice:amount description:nil currencyId:@"ARS"];
    NSArray *items = [NSArray arrayWithObjects:item, nil];
    
    CheckoutPreference* pref = [[CheckoutPreference alloc] initWithItems:items payer:payer paymentMethods:paymentPref];
    //--Create Checkout Preference
    
    //Checkout Customization Preferences
    FlowPreference* fp = [[FlowPreference alloc]init];
    [fp disableReviewAndConfirmScreen];
    
    DecorationPreference* dp = [[DecorationPreference alloc]initWithBaseColor:color fontName:nil fontLightName:nil];
    if (blackFont){
        [dp enableDarkFont];
    }else {
        [dp enableLightFont];
    }
    
    ServicePreference* sp = [[ServicePreference alloc]init];
    NSDictionary *extraParams = @{@"merchant_access_token" : merchantAccessToken};
    [sp setGetCustomerWithBaseURL:merchantBaseUrl URI:merchantGetCustomerUri additionalInfo:extraParams];
    //--Checkout Customization Preferences
    
    UINavigationController* new  = [[UINavigationController alloc]init];
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    //Create and Start Checkout
    self.cho = [[MercadoPagoCheckout alloc] initWithPublicKey: pk accessToken: nil checkoutPreference:pref paymentData:nil discount:nil navigationController:new paymentResult:nil];
    [MercadoPagoCheckout setSiteWithSiteID:siteID];
    [MercadoPagoCheckout setFlowPreference:fp];
    [MercadoPagoCheckout setDecorationPreference:dp];
    [cho start];
    
    [rootViewController presentViewController:new animated:YES completion:^{}];
    //--Create and Start Checkout
    
    //Callback
    NSString* callbackId = [command callbackId];
    
    [MercadoPagoCheckout setPaymentDataCallbackWithPaymentDataCallback:^(PaymentData * pd) {

        [new dismissViewControllerAnimated:true completion:nil];
        
        NSString *jsonPaymentMethod = [pd.paymentMethod toJSONString];
        NSString *jsonToken = [pd.token toJSONString];
        NSString *jsonPayerCost = [pd.payerCost toJSONString];
        
        NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
        [mpResponse setObject:jsonPaymentMethod forKey:@"payment_method"];
        [mpResponse setObject:jsonToken forKey:@"token"];
        [mpResponse setObject:jsonPayerCost forKey:@"payer_cost"];
        
        if (pd.issuer != nil ){
            NSString *jsonIssuer = [pd.issuer toJSONString];
            [mpResponse setObject:jsonIssuer forKey:@"issuer"];
        }
        
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
        NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: myString];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    }];
    //--Callback
}

- (void)showCardWithoutInstallments:(CDVInvokedUrlCommand*)command {
    
    //Get Public Key
    NSString *pk = [[command arguments] objectAtIndex:0];
    
    //Get Decoration Preference Color
    UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:1] alpha:1];
    
    //Get Black Font Bool Value
    BOOL blackFont = [[[command arguments] objectAtIndex:2]boolValue];
    
    //Get Payment Preference
    NSData *data = [[[command arguments] objectAtIndex:4] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    PaymentPreference *paymentPref = [PaymentPreference fromJSON:json];
    paymentPref.excludedPaymentTypeIds = [NSSet setWithObjects:@"atm", @"ticket", @"bank_transfer", @"debit_card", @"prepaid_card", @"digital_currency", nil];
    paymentPref.maxAcceptedInstallments = 1;

    
    
    //Create Checkout Preference
    Payer *payer = [[Payer alloc] initWith_id:@"payer_id" email:@"payer_email" type:nil identification:nil entityType:nil];
    Item *item = [[Item alloc] initWith_id:@"item_id" title:@"item_title" quantity:1 unitPrice:100 description:nil currencyId:@"ARS"];
    NSArray *items = [NSArray arrayWithObjects:item, nil];
    
    CheckoutPreference* pref = [[CheckoutPreference alloc] initWithItems:items payer:payer paymentMethods:paymentPref];
    //--Create Checkout Preference
    
    //Checkout Customization Preferences
    FlowPreference* fp = [[FlowPreference alloc]init];
    [fp disableReviewAndConfirmScreen];
    
    DecorationPreference* dp = [[DecorationPreference alloc]initWithBaseColor:color fontName:nil fontLightName:nil];
    if (blackFont){
        [dp enableDarkFont];
    }else {
        [dp enableLightFont];
    }
    //--Checkout Customization Preferences
    
    UINavigationController* new  = [[UINavigationController alloc]init];
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    //Create and Start Checkout
    self.cho = [[MercadoPagoCheckout alloc] initWithPublicKey: pk accessToken: nil checkoutPreference:pref paymentData:nil discount:nil navigationController:new paymentResult:nil];
    [MercadoPagoCheckout setFlowPreference:fp];
    [MercadoPagoCheckout setDecorationPreference:dp];
    [cho start];
    
    [rootViewController presentViewController:new animated:YES completion:^{}];
    //--Create and Start Checkout
    
    //Callback
    NSString* callbackId = [command callbackId];
    
    [MercadoPagoCheckout setPaymentDataCallbackWithPaymentDataCallback:^(PaymentData * pd) {
        
        [new dismissViewControllerAnimated:true completion:nil];
        
        NSString *jsonPaymentMethod = [pd.paymentMethod toJSONString];
        NSString *jsonToken = [pd.token toJSONString];
        NSString *jsonPayerCost = [pd.payerCost toJSONString];
        
        NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
        [mpResponse setObject:jsonPaymentMethod forKey:@"payment_method"];
        [mpResponse setObject:jsonToken forKey:@"token"];
        [mpResponse setObject:jsonPayerCost forKey:@"payer_cost"];
        
        if (pd.issuer != nil ){
            NSString *jsonIssuer = [pd.issuer toJSONString];
            [mpResponse setObject:jsonIssuer forKey:@"issuer"];
        }
        
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
        NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString: myString];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        
    }];
    //--Callback
}

- (void)showPaymentResult:(CDVInvokedUrlCommand*)command
{
    //Get Public Key
    NSString *pk = [[command arguments] objectAtIndex:0];
    
    //Get Payment
    NSData *data = [[[command arguments] objectAtIndex:1] dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    Payment *payment = [Payment fromJSON:json];
    
    //Get Payment Method
    data = [[[command arguments] objectAtIndex:2] dataUsingEncoding:NSUTF8StringEncoding];
    json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    PaymentMethod *paymentMethod = [PaymentMethod fromJSON:json];
    

    
    // Create PaymentData
    PaymentData *paymentData = [PaymentData alloc];
    
    paymentData.paymentMethod = paymentMethod;
    
    Issuer *issuer = [[Issuer alloc] init];
    NSNumber *issuerID = [NSNumber numberWithInteger:payment.issuerId];
    issuer._id = issuerID;
    paymentData.issuer = issuer;
    
    NSArray *labels = [[NSArray alloc] initWithObjects:@"labels", nil];
    PayerCost *payerCost = [[PayerCost alloc] initWithInstallments:payment.installments installmentRate:123.321 labels:labels minAllowedAmount:12312312.12312 maxAllowedAmount:12312.3123 recommendedMessage:nil installmentAmount:payment.installments totalAmount:payment.transactionAmount];
    paymentData.payerCost = payerCost;
    
    Token *token = [[Token alloc] initWith_id:payment.tokenId publicKey:pk cardId:nil luhnValidation:nil status:nil usedDate:nil cardNumberLength:18 creationDate:nil lastFourDigits:nil firstSixDigit:nil securityCodeLength:4 expirationMonth:01 expirationYear:99 lastModifiedDate:nil dueDate:nil cardHolder:nil];
    paymentData.token = nil;
    
    paymentData.payer = payment.payer;
    
    paymentData.transactionDetails = payment.transactionDetails;

    DiscountCoupon *discount = [[DiscountCoupon alloc] init];
    NSNumber *discountAmount = [NSNumber numberWithDouble:payment.couponAmount];
    [discountAmount stringValue];
    discount.coupon_amount = [discountAmount stringValue];
    paymentData.discount = discount;
    //--Create PaymentData
    
    PaymentResult *paymentResult = [[PaymentResult alloc] initWithPayment:payment paymentData:paymentData];
    
    UINavigationController* new1  = [[UINavigationController alloc]init];
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    
    Item *item = [[Item alloc] initWith_id:@"item_ID" title:@"item" quantity:1 unitPrice:payment.transactionAmount description:@"item_description" currencyId:payment.currencyId];
    NSArray *items = [[NSArray alloc] initWithObjects:item, nil];
    CheckoutPreference *pref = [[CheckoutPreference alloc] initWithItems:items payer:paymentData.payer paymentMethods:nil];
    
    FlowPreference* fp = [[FlowPreference alloc]init];
    [fp disableReviewAndConfirmScreen];
    
    self.cho = [[MercadoPagoCheckout alloc] initWithPublicKey: pk accessToken: @"" checkoutPreference:pref paymentData:paymentData discount:paymentData.discount navigationController:new1 paymentResult:paymentResult];
    [MercadoPagoCheckout setFlowPreference:fp];
    [cho start];
    

    [rootViewController presentViewController:new1 animated:YES completion:^{}];
    
    
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     
//     
//     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
//     
//     NSData *data = [[[command arguments] objectAtIndex:1] dataUsingEncoding:NSUTF8StringEncoding];
//     id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//     
//     Payment *payment = [Payment fromJSON:json];
//     data = [[[command arguments] objectAtIndex:2] dataUsingEncoding:NSUTF8StringEncoding];
//     json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//     PaymentMethod *paymentMethod = [PaymentMethod fromJSON:json];
//     
//     UINavigationController *navPaymentResult = [MPStepBuilder startPaymentResultStep:payment paymentMethod:paymentMethod callback:^(Payment * _Nonnull payment, enum CongratsState status) {
//     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
//     }];
//     
//     [rootViewController presentViewController:navPaymentResult animated:YES completion:^{}];
    
}


- (void)setPaymentPreference:(CDVInvokedUrlCommand*)command
{
    
    NSString* callbackId = [command callbackId];
    
    PaymentPreference *pp = [[PaymentPreference alloc]init];
    
    NSArray *exPaymentMethods = [[command arguments] objectAtIndex:2];
    pp.excludedPaymentMethodIds = exPaymentMethods;
    NSArray *exPaymentTypes = [[command arguments] objectAtIndex:3];
    pp.excludedPaymentTypeIds = exPaymentTypes;
    pp.maxAcceptedInstallments = [[[command arguments] objectAtIndex:0]integerValue];
    pp.defaultInstallments =[[[command arguments] objectAtIndex:1]integerValue];
    
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:[pp toJSONString]];
    
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    
}

- (void)startCheckout:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     NSString* callbackId = [command callbackId];
//     NSString* publicKey = [[command arguments] objectAtIndex:0];
//     NSString* prefId = [[command arguments] objectAtIndex:1];
//     
//     [MercadoPagoContext setPublicKey:publicKey];
//     
//     if ([[command arguments] objectAtIndex:2]!= (id)[NSNull null]){
//     UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:2] alpha:1];
//     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
//     } else {
//     UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:1];
//     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
//     }
//     if ([[[command arguments] objectAtIndex:3]boolValue]){
//     [MercadoPagoContext setDarkTextColor];
//     }else {
//     [MercadoPagoContext setLightTextColor];
//     }
//     
//     UINavigationController *choFlow =[MPFlowBuilder startCheckoutViewController:prefId callback:^(Payment *payment) {
//     NSString *mppayment = [payment toJSONString];
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString:mppayment];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     }callbackCancel:nil];
//     
//     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
//     
//     [rootViewController presentViewController:choFlow animated:YES completion:^{}];
    
}
- (void)getPaymentMethods:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     
//     [MPServicesBuilder getPaymentMethods:^(NSArray<PaymentMethod *> *paymentMethods) {
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: [self toString:paymentMethods]];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     } failure:^(NSError *error) {
//     
//     }];
    
    
}
- (void)getIssuers:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     
//     PaymentMethod *pm = [[PaymentMethod alloc]init];
//     pm._id = @"visa";
//     [MPServicesBuilder getIssuers:pm bin:nil success:^(NSArray<Issuer *> *issuers) {
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: [self toString:issuers]];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     } failure:^(NSError *error) {
//     
//     }];
    
}
- (void)getInstallments:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//    [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     
//     Issuer *is = [[ Issuer alloc]init];
//     
//     is._id = [[NSNumber alloc] initWithInt:[[command arguments] objectAtIndex:3]];
//     
//     [MPServicesBuilder getInstallments:[[command arguments] objectAtIndex:2] amount:[[[command arguments] objectAtIndex:4] doubleValue ]issuer:is paymentMethodId:[[command arguments] objectAtIndex:1] success:^(NSArray<Installment *> *installments) {
//     
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: [self toString:installments]];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     } failure:^(NSError * error) {
//     
//     }];
    
}
- (void)getIdentificationTypes:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     
//     
//     [MPServicesBuilder getIdentificationTypes:^(NSArray<IdentificationType *> * identificationTypes) {
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: [self toString:identificationTypes]];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     } failure:^(NSError * error) {
//     
//     }];
    
}
- (void)createToken:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     NSInteger expy = [[[command arguments] objectAtIndex:3] integerValue];
//     NSInteger expm = [[[command arguments] objectAtIndex:2] integerValue];
//     
//     CardToken *cardToken =[[CardToken alloc]initWithCardNumber:[[command arguments] objectAtIndex:1] expirationMonth:expm expirationYear:expy securityCode:[[command arguments] objectAtIndex:4] cardholderName:[[command arguments] objectAtIndex:5] docType:[[command arguments] objectAtIndex:6] docNumber:[[command arguments] objectAtIndex:7]];
//     
//     [MPServicesBuilder createNewCardToken:cardToken success:^(Token * token) {
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: [token toJSONString]];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     } failure:^(NSError * error) {
//     
//     NSLog(@"error: %@ \n",[error localizedDescription]);
//     }];
    
}
- (void)getBankDeals:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     
//     [MPServicesBuilder getPromos:^(NSArray<Promo *> * promo) {
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: [self toString:promo]];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     } failure:^(NSError * error) {
//     NSLog(@"error: %@ \n",[error localizedDescription]);
//     }];
    
}
- (void)getPaymentResult:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     
//     int payment = [[[command arguments] objectAtIndex:1] intValue];
//     
//     [MPServicesBuilder getInstructions:payment paymentTypeId:@"ticket" success:^(InstructionsInfo * instruction) {
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: [instruction toJSONString]];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     } failure:^(NSError * error) {
//     NSLog(@"error: %@ \n",[error localizedDescription]);
//     }];
    
}
- (void)createPayment:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     NSString* callbackId = [command callbackId];
//     int quantity = [[[command arguments] objectAtIndex:2]intValue];
//     double price = [[[command arguments] objectAtIndex:3]doubleValue];
//     
//     Item *item = [[Item alloc]initWith_id:[[command arguments] objectAtIndex:1] title:nil quantity:quantity unitPrice: price description:nil];
//     
//     Issuer *is =[[ Issuer alloc]init];
//     is._id = [[NSNumber alloc] initWithInt:[[command arguments] objectAtIndex:10]];
//     
//     PaymentMethod *pm = [[PaymentMethod alloc]init];
//     pm._id = [[command arguments] objectAtIndex:8];
//     
//     [MercadoPagoContext setMerchantAccessToken:[[command arguments] objectAtIndex:5]];
//     
//     MerchantPayment *mp=[[MerchantPayment alloc]initWithItems:item installments:[[command arguments] objectAtIndex:9] cardIssuer:is tokenId:[[command arguments] objectAtIndex:11] paymentMethod:pm campaignId:[[command arguments] objectAtIndex:4]];
//     
//     [MPServicesBuilder createPayment:[[command arguments] objectAtIndex:6] merchantPaymentUri:[[command arguments] objectAtIndex:7] payment:mp success:^(Payment * payment) {
//     NSString *mppayment = [payment toJSONString];
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: mppayment];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     
//     } failure:^(NSError * error) {
//     NSLog(@"error: %@ \n",[error localizedDescription]);
//     }];

}

- (void)showPaymentVault:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    
//     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
//     
//     NSString* callbackId = [command callbackId];
//     
//     [MercadoPagoContext setSiteID:[self getSiteID:[[command arguments] objectAtIndex:1]]];
//     
//     if ([[command arguments] objectAtIndex:3]!= (id)[NSNull null]){
//     UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:3] alpha:1];
//     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
//     } else {
//     UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:1];
//     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
//     }
//     if ([[[command arguments] objectAtIndex:4]boolValue]){
//     [MercadoPagoContext setDarkTextColor];
//     }else {
//     [MercadoPagoContext setLightTextColor];
//     }
//     PaymentPreference *paymentPreference = [[PaymentPreference alloc]init];
//     
//     if([[command arguments] objectAtIndex:5]!= (id)[NSNull null]){
//     NSData *data = [[[command arguments] objectAtIndex:5] dataUsingEncoding:NSUTF8StringEncoding];
//     id paymentPrefJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//     paymentPreference = [PaymentPreference fromJSON:paymentPrefJson];
//     }
//     
//     UINavigationController *paymentFlow = [MPFlowBuilder startPaymentVaultViewController:[[[command arguments] objectAtIndex:2]doubleValue] paymentPreference:paymentPreference callback:^(PaymentMethod * paymentMethod, Token * token, Issuer * issuer, PayerCost * payerCost) {
//     
//     NSString *jsonPaymentMethod = [paymentMethod toJSONString];
//     
//     
//     NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
//     [mpResponse setObject:jsonPaymentMethod forKey:@"payment_method"];
//     
//     
//     if (payerCost != nil && issuer != nil && token != nil){
//     NSString *jsonIssuer = [issuer toJSONString];
//     NSString *jsonPayerCost = [payerCost toJSONString];
//     NSString *jsonToken = [token toJSONString];
//     [mpResponse setObject:jsonToken forKey:@"token"];
//     [mpResponse setObject:jsonIssuer forKey:@"issuer"];
//     [mpResponse setObject:jsonPayerCost forKey:@"payer_cost"];
//     }
//     
//     NSError * err;
//     NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
//     NSString * mpJsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//     
//     CDVPluginResult* result = [CDVPluginResult
//     resultWithStatus:CDVCommandStatus_OK
//     messageAsString: mpJsonString];
//     
//     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//     }callbackCancel:nil];
//     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
//     
//     [rootViewController presentViewController:paymentFlow animated:YES completion:^{}];
    
}

- (void)showCardWithInstallments:(CDVInvokedUrlCommand*)command
{

    [self startFlavorTwo:command];
    /*
     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
     NSString* callbackId = [command callbackId];
     
     [MercadoPagoContext setSiteID:[self getSiteID:[[command arguments] objectAtIndex:1]]];
     
     if ([[command arguments] objectAtIndex:3]!= (id)[NSNull null]){
     UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:3] alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     } else {
     UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     }
     if ([[[command arguments] objectAtIndex:4]boolValue]){
     [MercadoPagoContext setDarkTextColor];
     }else {
     [MercadoPagoContext setLightTextColor];
     }
     PaymentPreference *paymentPreference = [[PaymentPreference alloc]init];
     
     if([[command arguments] objectAtIndex:5]!= (id)[NSNull null]){
     NSData *data = [[[command arguments] objectAtIndex:5] dataUsingEncoding:NSUTF8StringEncoding];
     id paymentPrefJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
     paymentPreference = [PaymentPreference fromJSON:paymentPrefJson];
     }
     
     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
     
     
     
     UINavigationController *choFlow = [MPFlowBuilder startCardFlow:paymentPreference amount:[[[command arguments] objectAtIndex:2]doubleValue] cardInformation:nil paymentMethods:nil token:nil timer:nil callback:^(PaymentMethod * paymentMethod, Token * token, Issuer * issuer, PayerCost * payerCost) {
     
     NSString *jsonPaymentMethod = [paymentMethod toJSONString];
     NSString *jsonToken = [token toJSONString];
     
     NSMutableDictionary *mpResponse = [[NSMutableDictionary alloc] init];
     [mpResponse setObject:jsonPaymentMethod forKey:@"payment_method"];
     [mpResponse setObject:jsonToken forKey:@"token"];
     
     if (payerCost != nil && issuer != nil ){
     NSString *jsonIssuer = [issuer toJSONString];
     NSString *jsonPayerCost = [payerCost toJSONString];
     [mpResponse setObject:jsonIssuer forKey:@"issuer"];
     [mpResponse setObject:jsonPayerCost forKey:@"payer_cost"];
     }
     
     NSError * err;
     NSData * jsonData = [NSJSONSerialization dataWithJSONObject:mpResponse options:0 error:&err];
     NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
     CDVPluginResult* result = [CDVPluginResult
     resultWithStatus:CDVCommandStatus_OK
     messageAsString: myString];
     
     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
     
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     
     } callbackCancel:^{
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     }];
     
     
     [rootViewController presentViewController:choFlow animated:YES completion:^{}];
     */
}

- (void)showPaymentMethods:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    /*
     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
     NSString* callbackId = [command callbackId];
     
     if ([[command arguments] objectAtIndex:1]!= (id)[NSNull null]){
     UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:1] alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     } else {
     UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     }
     if ([[[command arguments] objectAtIndex:2]boolValue]){
     [MercadoPagoContext setDarkTextColor];
     }else {
     [MercadoPagoContext setLightTextColor];
     }
     
     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
     if ([[command arguments] objectAtIndex:3] != (id)[NSNull null]){
     PaymentPreference *paymentPreference = [[PaymentPreference alloc]init];
     
     if([[command arguments] objectAtIndex:3]!= (id)[NSNull null]){
     NSData *data = [[[command arguments] objectAtIndex:3] dataUsingEncoding:NSUTF8StringEncoding];
     id paymentPrefJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
     paymentPreference = [PaymentPreference fromJSON:paymentPrefJson];
     }
     
     MercadoPagoUIViewController *viewPaymentMethods = [MPStepBuilder startPaymentMethodsStepWithPreference:paymentPreference callback:^(PaymentMethod *paymentMethod) {
     CDVPluginResult* result = [CDVPluginResult
     resultWithStatus:CDVCommandStatus_OK
     messageAsString: [paymentMethod toJSONString]];
     
     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     
     
     }];
     [viewPaymentMethods setCallbackCancel:^{
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     }];
     [self showInNavigationController:viewPaymentMethods];
     
     } else {
     PaymentMethodsViewController *viewPaymentMethods = [MPStepBuilder startPaymentMethodsStepWithPreference:nil callback:^(PaymentMethod *paymentMethod) {
     CDVPluginResult* result = [CDVPluginResult
     resultWithStatus:CDVCommandStatus_OK
     messageAsString: [paymentMethod toJSONString]];
     
     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     
     
     }];
     [viewPaymentMethods setCallbackCancel:^{
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     }];
     [self showInNavigationController:viewPaymentMethods];
     }
     */
}

- (void)showIssuers:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    /*
     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
     NSString* callbackId = [command callbackId];
     
     if ([[command arguments] objectAtIndex:2]!= (id)[NSNull null]){
     UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:2] alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     } else {
     UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     }
     if ([[[command arguments] objectAtIndex:3]boolValue]){
     [MercadoPagoContext setDarkTextColor];
     
     } else {
     [MercadoPagoContext setLightTextColor];
     }
     
     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
     
     PaymentMethod *pm = [[PaymentMethod alloc]init];
     pm._id = [[command arguments] objectAtIndex:1];
     
     
     MercadoPagoUIViewController *viewIssuers = [MPStepBuilder startIssuersStep:pm callback:^(Issuer * issuer){
     CDVPluginResult* result = [CDVPluginResult
     resultWithStatus:CDVCommandStatus_OK
     messageAsString: [issuer toJSONString]];
     
     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     
     }];
     [viewIssuers setCallbackCancel:^{
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     }];
     
     [self showInNavigationController:viewIssuers];
     */
}

- (void)showInstallments:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    /*
     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
     NSString* callbackId = [command callbackId];
     
     [MercadoPagoContext setSiteID:[self getSiteID:[[command arguments] objectAtIndex:1]]];
     
     if ([[command arguments] objectAtIndex:5]!= (id)[NSNull null]){
     UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:5] alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     } else {
     UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     }
     if ([[[command arguments] objectAtIndex:6]boolValue]){
     [MercadoPagoContext setDarkTextColor];
     }else {
     [MercadoPagoContext setLightTextColor];
     }
     
     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
     
     Issuer *issuer =[[Issuer alloc]init];
     issuer._id=[[NSNumber alloc] initWithInt:[[command arguments] objectAtIndex:4]];
     
     PaymentPreference *paymentPreference = [[PaymentPreference alloc]init];
     
     if([[command arguments] objectAtIndex:7]!= (id)[NSNull null]){
     NSData *data = [[[command arguments] objectAtIndex:7] dataUsingEncoding:NSUTF8StringEncoding];
     id paymentPrefJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
     paymentPreference = [PaymentPreference fromJSON:paymentPrefJson];
     }
     
     MercadoPagoUIViewController *navInstallments = [MPStepBuilder startInstallmentsStep:nil paymentPreference:paymentPreference amount:[[[command arguments] objectAtIndex:2]doubleValue] issuer:issuer paymentMethodId:[[command arguments] objectAtIndex:3] callback:^(PayerCost * payerCost) {
     
     CDVPluginResult* result = [CDVPluginResult
     resultWithStatus:CDVCommandStatus_OK
     messageAsString: [payerCost toJSONString]];
     
     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     }];
     [navInstallments setCallbackCancel:^{
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     }];
     
     
     [self showInNavigationController:navInstallments];
     */
}

- (void)showBankDeals:(CDVInvokedUrlCommand*)command
{
    [self startFlavorTwo:command];
    /*
     [MercadoPagoContext setPublicKey:[[command arguments] objectAtIndex:0]];
     NSString* callbackId = [command callbackId];
     
     if ([[command arguments] objectAtIndex:1]!= (id)[NSNull null]){
     UIColor *color = [UIColor colorwithHexString:[[command arguments] objectAtIndex:1] alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     } else {
     UIColor *color = [UIColor colorwithHexString:MERCADO_PAGO_BASE_COLOR alpha:1];
     [MercadoPagoContext setupPrimaryColor:color complementaryColor:nil];
     }
     if ([[[command arguments] objectAtIndex:2]boolValue]){
     [MercadoPagoContext setDarkTextColor];
     }else {
     [MercadoPagoContext setLightTextColor];
     }
     
     UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
     
     UIViewController *promo = [MPStepBuilder startPromosStep:^{
     [rootViewController dismissViewControllerAnimated:YES completion:^{}];
     }];
     
     [self showInNavigationController:promo];
     */
}

-(void) showInNavigationController:(UIViewController *)viewControllerBase{
    
    UINavigationController *navCon = [[UINavigationController alloc]initWithRootViewController:viewControllerBase];
    UIViewController *rootViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [rootViewController presentViewController:navCon animated:YES completion:^{}];
    
}

-(NSString *)toString:(NSArray*)array{
    NSString* json= @"[";
    
    for (int i=0; i < [array count]; i++) {
        json =[json stringByAppendingString:[array[i] toJSONString]];
        json = [json stringByAppendingString:@","];
    }
    json = [json substringToIndex:[json length] - 1];
    json = [json stringByAppendingString: @"]"];
    return json;
}

-(NSString *)getSiteID:(NSString*)site{
    if ([[site uppercaseString] isEqual: @"ARGENTINA"]){
        return @"MLA";
    } else if ([[site uppercaseString] isEqual: @"BRASIL"]){
        return @"MLC";
    }  else if ([[site uppercaseString] isEqual: @"CHILE"]){
        return @"MCO";
    } else if ([[site uppercaseString] isEqual: @"COLOMBIA"]){
        return @"MLM";
    } else if ([[site uppercaseString] isEqual: @"MEXICO"]){
        return @"MLB";
    } else if ([[site uppercaseString] isEqual: @"USA"]){
        return @"USA";
    } else if ([[site uppercaseString] isEqual: @"VENEZUELA"]){
        return @"MLV";
    }
}

@end
