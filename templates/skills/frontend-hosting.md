# Skill: Frontend Hosting Infrastructure

## PURPOSE
Create production-ready static frontend hosting infrastructure using S3 for static file storage and CloudFront for global CDN delivery with optimal caching strategies.

## WHEN TO USE
- Deploying React/Vue/Svelte/Angular SPAs or static sites
- Setting up new CloudFront distributions with S3 origins
- Configuring caching behaviors for static assets
- Creating infrastructure for micro-frontends
- Reusing existing CloudFront distributions or OAC for new S3 buckets
- Adding WAF protection to frontend distributions
- Configuring Route53 DNS for custom domains

## INPUTS
- domain_name (required) - Domain name for the application
- certificate_arn (required) - ACM certificate ARN for HTTPS (must be in us-east-1)
- hosted_zone_id (required) - Route53 Hosted Zone ID for DNS records
- create_cloudfront (optional) - Create new CloudFront: `true` or `false`, default: true
- existing_distribution_id (optional) - Existing CloudFront distribution ID to reuse
- existing_oac_id (optional) - Existing Origin Access Control ID to reuse
- enable_waf (optional) - Enable AWS WAF: `true` or `false`, default: false
- waf_acl_arn (optional) - Existing WAF WebACL ARN to associate
- price_class (optional) - CloudFront price class: `PriceClass_100`, `PriceClass_200`, `PriceClass_All`, default: PriceClass_100
- index_document (optional) - Index document name, default: index.html
- error_document (optional) - Error document name, default: index.html
- enable_security_headers (optional) - Enable CloudFront security headers function: `true` or `false`, default: true

---

## S3 BUCKET CONFIGURATION

### Static Website Bucket
```yaml
FrontendBucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketName: !Sub "${StackName}-${DomainName}-frontend"
    PublicAccessBlockConfiguration:
      BlockPublicAcls: true
      BlockPublicPolicy: true
      IgnorePublicAcls: true
      RestrictPublicBuckets: true
    BucketEncryption:
      ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            SSEAlgorithm: AES256
    LifecycleConfiguration:
      Rules:
        - Id: DeleteOldVersions
          Status: Enabled
          NoncurrentVersionExpirationInDays: 30
```

### Bucket Policy for OAC Access
```yaml
FrontendBucketPolicy:
  Type: AWS::S3::BucketPolicy
  Properties:
    Bucket: !Ref FrontendBucket
    PolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Sid: AllowCloudFrontOAC
          Effect: Allow
          Principal:
            Service: cloudfront.amazonaws.com
          Action: 
            - s3:GetObject
            - s3:GetObjectVersion
          Resource: !Sub "${FrontendBucket.Arn}/*"
          Condition:
            StringEquals:
              AWS:SourceArn: !Sub "arn:aws:cloudfront::${AWS::AccountId}:distribution/${CloudFrontDistribution}"
```

---

## CLOUDFRONT CONFIGURATION

### Origin Access Control (OAC)
Create OAC only if existing_oac_id is not provided. OAC replaces deprecated OAI with better security:
```yaml
CloudFrontOAC:
  Type: AWS::CloudFront::OriginAccessControl
  Condition: CreateOAC
  Properties:
    OriginAccessControlConfig:
      Name: !Sub "${StackName}-OAC"
      Description: OAC for S3 origin
      OriginAccessControlOriginType: s3
      SigningBehavior: always
      SigningProtocol: sigv4
```

### Distribution with Caching Behaviors
```yaml
CloudFrontDistribution:
  Type: AWS::CloudFront::Distribution
  Properties:
    DistributionConfig:
      Enabled: true
      Comment: !Sub "${StackName} frontend distribution"
      DefaultRootObject: !Ref IndexDocument
      PriceClass: !Ref PriceClass
      
      # Custom domain configuration
      Aliases:
        - !Ref DomainName
        - !Sub "www.${DomainName}"
      ViewerCertificate:
        AcmCertificateArn: !Ref CertificateArn
        SslSupportMethod: sni-only
        MinimumProtocolVersion: TLSv1.2_2021
      
      # S3 Origin with OAC
      Origins:
        - Id: S3Origin
          DomainName: !GetAtt FrontendBucket.RegionalDomainName
          S3OriginConfig:
            OriginAccessIdentity: ""
          OriginAccessControlId: !If [CreateOAC, !Ref CloudFrontOAC, !Ref ExistingOACId]
      
      # Default cache behavior for HTML files
      DefaultCacheBehavior:
        TargetOriginId: S3Origin
        ViewerProtocolPolicy: redirect-to-https
        Compress: true
        AllowedMethods:
          - GET
          - HEAD
          - OPTIONS
        CachedMethods:
          - GET
          - HEAD
        
        # Forward only necessary headers/cookies/query strings
        ForwardedValues:
          QueryString: false
          Cookies:
            Forward: none
          Headers: []
        
        # No caching for HTML (spa navigation)
        MinTTL: 0
        DefaultTTL: 0
        MaxTTL: 0
        
        # Security headers function association
        FunctionAssociations:
          - EventType: viewer-response
            FunctionARN: !If [EnableSecurityHeaders, !GetAtt SecurityHeadersFunction.FunctionARN, !Ref "AWS::NoValue"]
      
      # Additional cache behaviors for static assets
      CacheBehaviors:
        # JavaScript files - long cache with content hash
        - PathPattern: "*.js"
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          Compress: true
          AllowedMethods:
            - GET
            - HEAD
          CachedMethods:
            - GET
            - HEAD
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
          MinTTL: 31536000
          DefaultTTL: 31536000
          MaxTTL: 31536000
        
        # CSS files - long cache with content hash
        - PathPattern: "*.css"
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          Compress: true
          AllowedMethods:
            - GET
            - HEAD
          CachedMethods:
            - GET
            - HEAD
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
          MinTTL: 31536000
          DefaultTTL: 31536000
          MaxTTL: 31536000
        
        # Images - medium cache
        - PathPattern: "*.{png,jpg,jpeg,gif,webp,svg,ico}"
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          Compress: true
          AllowedMethods:
            - GET
            - HEAD
          CachedMethods:
            - GET
            - HEAD
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
          MinTTL: 86400
          DefaultTTL: 604800
          MaxTTL: 31536000
        
        # Fonts - long cache
        - PathPattern: "*.{woff,woff2,ttf,otf,eot}"
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          Compress: true
          AllowedMethods:
            - GET
            - HEAD
          CachedMethods:
            - GET
            - HEAD
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
          MinTTL: 31536000
          DefaultTTL: 31536000
          MaxTTL: 31536000
        
        # Static assets folder (if using /assets/ pattern)
        - PathPattern: "/assets/*"
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          Compress: true
          AllowedMethods:
            - GET
            - HEAD
          CachedMethods:
            - GET
            - HEAD
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
          MinTTL: 31536000
          DefaultTTL: 31536000
          MaxTTL: 31536000
      
      # Custom error responses for SPA routing
      CustomErrorResponses:
        - ErrorCode: 403
          ResponseCode: 200
          ResponsePagePath: !Sub "/${IndexDocument}"
          ErrorCachingMinTTL: 0
        - ErrorCode: 404
          ResponseCode: 200
          ResponsePagePath: !Sub "/${IndexDocument}"
          ErrorCachingMinTTL: 0
      
      # WAF WebACL (optional)
      WebACLId: !If [EnableWAF, !Ref WAFWebACL, !Ref "AWS::NoValue"]
```

### Security Headers Function
```yaml
SecurityHeadersFunction:
  Type: AWS::CloudFront::Function
  Condition: EnableSecurityHeaders
  Properties:
    Name: !Sub "${StackName}-security-headers"
    Description: Add security headers to all responses
    AutoPublish: true
    FunctionCode: |
      function handler(event) {
        var response = event.response;
        var headers = response.headers;
        
        // Prevent MIME type sniffing
        headers['x-content-type-options'] = { value: 'nosniff' };
        
        // Prevent clickjacking
        headers['x-frame-options'] = { value: 'DENY' };
        
        // Enforce HTTPS
        headers['strict-transport-security'] = { value: 'max-age=63072000; includeSubDomains; preload' };
        
        // Control referrer information
        headers['referrer-policy'] = { value: 'strict-origin-when-cross-origin' };
        
        // XSS protection
        headers['x-xss-protection'] = { value: '1; mode=block' };
        
        return response;
      }
    Runtime: cloudfront-js-1.0
```

### WAF WebACL (Optional)
```yaml
WAFWebACL:
  Type: AWS::WAFv2::WebACL
  Condition: CreateWAF
  Properties:
    Name: !Sub "${StackName}-frontend-waf"
    Description: WAF rules for frontend distribution
    Scope: CLOUDFRONT
    DefaultAction:
      Allow: {}
    VisibilityConfig:
      SampledRequestsEnabled: true
      CloudWatchMetricsEnabled: true
      MetricName: !Sub "${StackName}-frontend-waf"
    Rules:
      # AWS Managed Rules - Common Rule Set
      - Name: AWSManagedRulesCommonRuleSet
        Priority: 1
        Statement:
          ManagedRuleGroupStatement:
            VendorName: AWS
            Name: AWSManagedRulesCommonRuleSet
        OverrideAction:
          None: {}
        VisibilityConfig:
          SampledRequestsEnabled: true
          CloudWatchMetricsEnabled: true
          MetricName: AWSManagedRulesCommonRuleSet
      
      # Rate limiting - 2000 requests per 5 minutes per IP
      - Name: RateLimitRule
        Priority: 2
        Statement:
          RateBasedStatement:
            Limit: 2000
            AggregateKeyType: IP
        Action:
          Block: {}
        VisibilityConfig:
          SampledRequestsEnabled: true
          CloudWatchMetricsEnabled: true
          MetricName: RateLimitRule
```

### Route53 DNS Configuration
```yaml
DNSRecord:
  Type: AWS::Route53::RecordSet
  Properties:
    HostedZoneId: !Ref HostedZoneId
    Name: !Ref DomainName
    Type: A
    AliasTarget:
      HostedZoneId: Z2FDTNDATAQYW2  # CloudFront hosted zone ID (constant)
      DNSName: !If [CreateCloudFront, !GetAtt CloudFrontDistribution.DomainName, !Ref "AWS::NoValue"]
      EvaluateTargetHealth: false

DNSRecordWWW:
  Type: AWS::Route53::RecordSet
  Properties:
    HostedZoneId: !Ref HostedZoneId
    Name: !Sub "www.${DomainName}"
    Type: A
    AliasTarget:
      HostedZoneId: Z2FDTNDATAQYW2
      DNSName: !If [CreateCloudFront, !GetAtt CloudFrontDistribution.DomainName, !Ref "AWS::NoValue"]
      EvaluateTargetHealth: false
```

---

## CACHING STRATEGY

### Cache Behavior Patterns

| Path Pattern | Min TTL | Default TTL | Max TTL | Purpose |
|--------------|---------|-------------|---------|---------|
| Default (HTML) | 0 | 0 | 0 | No cache - ensures fresh app on deploy |
| `*.js` | 1 year | 1 year | 1 year | Immutable with content hash |
| `*.css` | 1 year | 1 year | 1 year | Immutable with content hash |
| Images | 1 day | 1 week | 1 year | Balanced performance/flexibility |
| Fonts | 1 year | 1 year | 1 year | Rarely change, safe to cache long |
| `/assets/*` | 1 year | 1 year | 1 year | Bundled assets with content hash |

### SPA Routing Configuration
For single-page applications, configure:
- 403/404 errors return index.html with 200 status
- HTML files never cached (TTL = 0)
- Assets cached indefinitely with content hash in filename

---

## STACK INPUTS

```yaml
Parameters:
  StackName:
    Type: String
    Description: Name of the stack
    Default: my-app

  DomainName:
    Type: String
    Description: Domain name for the frontend
    AllowedPattern: ^[a-z0-9][a-z0-9\-\.]{1,61}[a-z0-9]$

  CertificateArn:
    Type: String
    Description: ACM certificate ARN for HTTPS (must be in us-east-1)
    AllowedPattern: ^arn:aws:acm:us-east-1:[0-9]+:certificate/[a-zA-Z0-9\-]+$

  HostedZoneId:
    Type: String
    Description: Route53 Hosted Zone ID for DNS records

  CreateCloudFront:
    Type: String
    Description: Create new CloudFront distribution
    Default: 'true'
    AllowedValues:
      - 'true'
      - 'false'

  ExistingDistributionId:
    Type: String
    Description: Existing CloudFront distribution ID (if not creating new)
    Default: ''

  ExistingOACId:
    Type: String
    Description: Existing Origin Access Control ID (if not creating new)
    Default: ''

  EnableWAF:
    Type: String
    Description: Enable AWS WAF WebACL
    Default: 'false'
    AllowedValues:
      - 'true'
      - 'false'

  WAFACLArn:
    Type: String
    Description: Existing WAF WebACL ARN (if not creating new)
    Default: ''

  EnableSecurityHeaders:
    Type: String
    Description: Enable CloudFront security headers function
    Default: 'true'
    AllowedValues:
      - 'true'
      - 'false'

  PriceClass:
    Type: String
    Description: CloudFront price class
    Default: PriceClass_100
    AllowedValues:
      - PriceClass_100
      - PriceClass_200
      - PriceClass_All

  IndexDocument:
    Type: String
    Description: Index document for the site
    Default: index.html

  ErrorDocument:
    Type: String
    Description: Error document for the site
    Default: index.html
```

### Conditions for Conditional Resource Creation
```yaml
Conditions:
  CreateCloudFront: !Equals [!Ref CreateCloudFront, 'true']
  CreateOAC: !Equals [!Ref ExistingOACId, '']
  CreateWAF: !And
    - !Equals [!Ref EnableWAF, 'true']
    - !Equals [!Ref WAFACLArn, '']
  EnableWAF: !Equals [!Ref EnableWAF, 'true']
  UseExistingDistribution: !Not [!Equals [!Ref ExistingDistributionId, '']]
  UseExistingOAC: !Not [!Equals [!Ref ExistingOACId, '']]
  EnableSecurityHeaders: !Equals [!Ref EnableSecurityHeaders, 'true']
```

---

## STACK OUTPUTS

```yaml
Outputs:
  BucketName:
    Description: S3 bucket for frontend assets
    Value: !Ref FrontendBucket
    Export:
      Name: !Sub "${StackName}-FrontendBucket"

  BucketArn:
    Description: ARN of the S3 bucket
    Value: !GetAtt FrontendBucket.Arn
    Export:
      Name: !Sub "${StackName}-FrontendBucketArn"

  DistributionId:
    Description: CloudFront distribution ID
    Value: !If [CreateCloudFront, !Ref CloudFrontDistribution, !Ref ExistingDistributionId]
    Export:
      Name: !Sub "${StackName}-DistributionId"

  DistributionDomain:
    Description: CloudFront distribution domain name
    Value: !If [CreateCloudFront, !GetAtt CloudFrontDistribution.DomainName, !Ref 'AWS::NoValue']
    Export:
      Name: !Sub "${StackName}-DistributionDomain"

  OACId:
    Description: Origin Access Control ID
    Value: !If [CreateOAC, !Ref CloudFrontOAC, !Ref ExistingOACId]
    Export:
      Name: !Sub "${StackName}-OACId"

  WAFACLArn:
    Description: WAF WebACL ARN
    Condition: EnableWAF
    Value: !If [CreateWAF, !GetAtt WAFWebACL.Arn, !Ref WAFACLArn]
    Export:
      Name: !Sub "${StackName}-WAFACLArn"

  Domain:
    Description: Custom domain for the frontend
    Value: !Ref DomainName
    Export:
      Name: !Sub "${StackName}-FrontendDomain"
```

---

## DEPLOYMENT BEST PRACTICES

### 1. Asset Naming
- Use content hashes in filenames: `main.a3f7b2c.js`
- Enable source maps for debugging: `main.a3f7b2c.js.map`
- This allows long cache times with safe invalidation

### 2. Build Pipeline Integration
```bash
# Build with content hashes
npm run build

# Sync to S3 with cache headers
aws s3 sync dist/ s3://$BUCKET_NAME/ \
  --delete \
  --cache-control "max-age=31536000, immutable" \
  --exclude "*.html"

# Sync HTML files with no-cache
aws s3 sync dist/ s3://$BUCKET_NAME/ \
  --cache-control "no-cache" \
  --include "*.html"

# Invalidate CloudFront cache for HTML only
aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"
```

### 3. Security Headers
Add security headers via Lambda@Edge or CloudFront Functions:
- Content-Security-Policy
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Strict-Transport-Security

### 4. Cost Optimization
- Use PriceClass_100 for North America/Europe only
- Enable compression for text assets
- Configure lifecycle rules for old versions
- Monitor cache hit ratios in CloudFront

---

## COMMON PATTERNS

### Pattern: Reuse Existing CloudFront for New Micro-Frontend
```yaml
Parameters:
  CreateCloudFront: 'false'
  ExistingDistributionId: E1234567890ABC
  ExistingOACId: EABCDEF1234567

# Only S3 bucket and policy are created
# CloudFront behavior is added separately or via separate stack
```

### Pattern: Multiple Environments (dev/staging/prod)
```yaml
Mappings:
  EnvironmentConfig:
    dev:
      PriceClass: PriceClass_100
    staging:
      PriceClass: PriceClass_100
    prod:
      PriceClass: PriceClass_All

# Use Fn::FindInMap for environment-specific settings
PriceClass: !FindInMap [EnvironmentConfig, !Ref Environment, PriceClass]
```

### Pattern: Separate Asset Origins
```yaml
Origins:
  - Id: S3Origin
    DomainName: !GetAtt FrontendBucket.RegionalDomainName
    S3OriginConfig:
      OriginAccessIdentity: !Sub "origin-access-identity/cloudfront/${CloudFrontOAI}"
  
  - Id: MediaOrigin
    DomainName: media.example.com
    CustomOriginConfig:
      OriginProtocolPolicy: https-only

# Route /media/* to separate origin
CacheBehaviors:
  - PathPattern: "/media/*"
    TargetOriginId: MediaOrigin
    # ... config
```
