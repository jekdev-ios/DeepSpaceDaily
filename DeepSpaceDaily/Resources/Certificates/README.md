# SSL Pinning in DeepSpaceDaily

This directory contains the SSL certificate used for certificate pinning in the DeepSpaceDaily app.

## Certificate Details

- **File**: `spaceflightnewsapi.net.pem`
- **Domain**: spaceflightnewsapi.net
- **Public Key Hash**: `0QaROX1BpIov5Vvv71S5HQ/DKRT6wvQ1ez/kwSsj/sA=`
- **Expiration Date**: May 1, 2025

## Implementation

SSL pinning is implemented in the `APIService` class using the URLSession delegate method. The app validates the server's certificate against our pinned certificate to ensure secure communication with the Space Flight News API.

## Certificate Renewal

The current certificate expires on May 1, 2025. Before this date, you should:

1. Obtain a new certificate from the server:
   ```
   openssl s_client -showcerts -servername api.spaceflightnewsapi.net -connect api.spaceflightnewsapi.net:443 < /dev/null | openssl x509 -outform PEM > spaceflight_api_cert.pem
   ```

2. Extract the new public key hash:
   ```
   openssl x509 -in spaceflight_api_cert.pem -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
   ```

3. Update the certificate file in the app bundle
4. Update the `pinnedPublicKeyHash` value in the `APIService` class

## Security Considerations

- The app uses both certificate pinning and public key pinning methods
- If the certificate validation fails, the app will refuse to connect to the server
- This protects against man-in-the-middle (MITM) attacks

## Testing SSL Pinning

To test that SSL pinning is working correctly:

1. Run the app in debug mode
2. Check for log messages related to SSL pinning
3. Use a proxy tool like Charles Proxy to attempt to intercept the connection - it should fail if pinning is working correctly 