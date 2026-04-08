# aws-spot-feed

Creates an S3 bucket and AWS Spot Datafeed Subscription for accurate spot instance pricing in OpenCost. One per AWS account.

## Why Spot Feed?

**Without Spot Feed:**
- OpenCost reports on-demand pricing for spot instances, overstating costs
- No visibility into actual spot savings
- Cost allocation and chargeback are inaccurate

**With Spot Feed:**
- OpenCost reads actual spot pricing from the data feed
- Accurate cost reports reflecting real spot discounts
- Reliable chargeback for teams using spot instances

## What It Creates

- **S3 Bucket** - Receives spot pricing data from AWS
- **BucketOwnershipControls** - Allows ACL-based writes from the spot feed service
- **BucketPublicAccessBlock** - Blocks all public access
- **SpotDatafeedSubscription** - Tells AWS to publish spot pricing to the bucket

## Quick Start

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: SpotFeed
metadata:
  name: hops-root-account
  namespace: default
spec:
  accountId: "123456789012"
  region: us-east-1
```

This creates a bucket named `hops-root-account-spot-feed` and subscribes the account's spot data feed to it.

## Configuration

### Required Fields

| Field | Description |
|-------|-------------|
| `spec.accountId` | AWS Account ID |
| `spec.region` | AWS region for the S3 bucket |

### Optional Fields

| Field | Default | Description |
|-------|---------|-------------|
| `spec.bucketName` | `{name}-spot-feed` | S3 bucket name |
| `spec.prefix` | - | S3 key prefix for spot feed files |
| `spec.providerConfigRef.name` | `"default"` | AWS ProviderConfig name |
| `spec.tags` | `{"hops": "true"}` | Additional AWS resource tags |

## Using with ObserveStack

Point your ObserveStack at the spot feed bucket to enable accurate spot pricing in OpenCost:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: ObserveStack
metadata:
  name: my-cluster
spec:
  clusterName: my-cluster
  aws:
    region: us-east-1
  spotFeed:
    enabled: true
    bucketName: hops-root-account-spot-feed
    region: us-east-1
```

This adds S3 read permissions to the OpenCost PodIdentity and configures the OpenCost exporter to read spot pricing from the feed.

## Custom Bucket Name

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: SpotFeed
metadata:
  name: prod
spec:
  accountId: "123456789012"
  region: us-west-2
  bucketName: my-org-spot-pricing
  prefix: spot-data/
  tags:
    environment: production
```

## Importing Existing Resources

If you already have a spot data feed subscription:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: SpotFeed
metadata:
  name: existing
spec:
  accountId: "123456789012"
  region: us-east-1
  bucketName: existing-spot-bucket
  managementPolicies: [Create, Update, Observe, LateInitialize]
  bucket:
    externalName: existing-spot-bucket
  subscription:
    externalName: existing-spot-bucket
```

## Status

```yaml
status:
  ready: true
  bucketName: hops-root-account-spot-feed
  bucketArn: arn:aws:s3:::hops-root-account-spot-feed
```

## Important Notes

- **One per account** - AWS allows exactly one spot data feed subscription per account
- **Name your XR meaningfully** - The XR name (`metadata.name`) drives resource naming, e.g. `hops-root-account` → `hops-root-account-spot-feed`
- **Convergence** - The subscription and bucket are created simultaneously; the subscription retries until the bucket is available

## Development

```bash
make render         # Render all examples
make test           # Run KCL composition tests
make e2e            # Run E2E tests (requires AWS credentials)
make validate       # Validate rendered output against schemas
```

## License

Apache-2.0
