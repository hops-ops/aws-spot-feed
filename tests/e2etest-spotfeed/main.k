# e2etest-spotfeed - AWS Spot Data Feed E2E Test
# ================================================
# Tests S3 bucket and SpotDatafeedSubscription creation with optional import.
#
# First run creates resources in AWS. Future runs manage the existing resources
# via orphan policy (no Delete). Resources persist in AWS after claim deletion.
#
# Get resource external names after first run:
#   kubectl get bucket -l crossplane.io/composite=e2e-spot-feed \
#     -o jsonpath='{.items[0].metadata.annotations.crossplane\.io/external-name}'
#   kubectl get spotdatafeedsubscription -l crossplane.io/composite=e2e-spot-feed \
#     -o jsonpath='{.items[0].metadata.annotations.crossplane\.io/external-name}'

import models.ai.com.ops.hops.aws.v1alpha1 as hops
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

import file
import base64

# Read AWS credentials from local file (must be created manually, gitignored)
_awsCredsRaw = file.read("secrets/aws-creds")
_awsCreds = base64.encode(_awsCredsRaw)

# AWS account ID and region for testing
_testAccountId = file.read("env/AWS_ACCOUNT_ID").strip()
_testRegion = file.read("env/AWS_REGION").strip()

# Orphan policy - no Delete means resources persist in AWS after claim deletion
_orphan = ["Create", "Observe", "Update", "LateInitialize"]

# =============================================================================
# External names for import
# =============================================================================
# Bucket external name matches the default bucket naming: {name}-spot-feed
_test_name = "e2e-spot-feed"
_bucket_external_name = _test_name + "-spot-feed"

# Subscription external name — AWS only allows one per account, so after first
# run this is stable. On first run, leave empty to create; on subsequent runs
# the orphaned subscription already exists and gets adopted.
# _subscription_external_name = ""
_subscription_external_name = _bucket_external_name

# =============================================================================
# Test SpotFeed
# =============================================================================
_items = [
    metav1alpha1.E2ETest {
        metadata.name = "spotfeed-e2e"
        spec = {
            crossplane = {
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions = ["Ready"]
            skipDelete = False
            timeoutSeconds = 4500

            # Extra resources: AWS credentials secret and ProviderConfig
            extraResources = [
                # AWS credentials secret
                {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = "aws-creds"
                        namespace = "default"
                    }
                    type = "Opaque"
                    data.creds = _awsCreds
                }
                # ProviderConfig for AWS
                {
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    kind = "ProviderConfig"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Secret"
                            secretRef = {
                                name = "aws-creds"
                                namespace = "default"
                                key = "creds"
                            }
                        }
                    }
                }
            ]

            # The SpotFeed claim to test
            manifests = [
                hops.SpotFeed {
                    metadata = {
                        name = _test_name
                        namespace = "default"
                    }
                    spec = {
                        accountId = _testAccountId
                        region = _testRegion
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        # Prevent deletion of resources after E2E test
                        managementPolicies = _orphan
                        if _bucket_external_name:
                            bucket = {
                                externalName = _bucket_external_name
                            }
                        if _subscription_external_name:
                            subscription = {
                                externalName = _subscription_external_name
                            }
                        tags = {
                            "hops.ops.com.ai/test-repo": "https://github.com/hops-ops/aws-spot-feed"
                            "hops.ops.com.ai/persistent": "true"
                        }
                    }
                }
            ]
        }
    }
]
items = _items
