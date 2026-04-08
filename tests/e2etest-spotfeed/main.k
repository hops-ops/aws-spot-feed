# e2etest-spotfeed - AWS Spot Data Feed E2E Test
# ================================================
# Tests SpotFeed XRD by importing the persistent spot feed resources.
#
# AWS allows only ONE spot data feed per account, so this test imports the
# existing bucket and subscription rather than creating new ones. Uses orphan
# policy (no Delete) so resources persist after test cleanup.
#
# The persistent resources were created by the hops-root-account SpotFeed XR
# and live in the shared CI account.

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

# Persistent resource names from GitHub variables
_bucketName = file.read("env/SPOT_FEED_BUCKET_NAME").strip()
_subscriptionExternalName = file.read("env/SPOT_FEED_SUBSCRIPTION_EXTERNAL_NAME").strip()

# Orphan policy - no Delete means resources persist in AWS after claim deletion
_orphan = ["Create", "Observe", "Update", "LateInitialize"]

_test_name = "e2e-spot-feed"

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

            # The SpotFeed claim — imports existing persistent resources
            manifests = [
                hops.SpotFeed {
                    metadata = {
                        name = _test_name
                        namespace = "default"
                    }
                    spec = {
                        accountId = _testAccountId
                        region = _testRegion
                        bucketName = _bucketName
                        providerConfigRef = {
                            name = "default"
                            kind = "ProviderConfig"
                        }
                        managementPolicies = _orphan
                        bucket = {
                            externalName = _bucketName
                        }
                        subscription = {
                            externalName = _subscriptionExternalName
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
