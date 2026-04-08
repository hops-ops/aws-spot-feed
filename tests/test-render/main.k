import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    # Test 1: Default bucket name derives from accountId
    metav1alpha1.CompositionTest {
        metadata.name = "default-bucket-name"
        spec = {
            compositionPath = "apis/spotfeeds/composition.yaml"
            xrdPath = "apis/spotfeeds/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.SpotFeed {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-1"
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "my-account-spot-feed"
                    metadata.annotations = {
                        "crossplane.io/external-name" = "my-account-spot-feed"
                    }
                }
            ]
        }
    }

    # Test 2: Custom bucket name overrides default external-name
    metav1alpha1.CompositionTest {
        metadata.name = "custom-bucket-name"
        spec = {
            compositionPath = "apis/spotfeeds/composition.yaml"
            xrdPath = "apis/spotfeeds/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.SpotFeed {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-1"
                    bucketName = "custom-spot-bucket"
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "my-account-spot-feed"
                    metadata.annotations = {
                        "crossplane.io/external-name" = "custom-spot-bucket"
                    }
                }
            ]
        }
    }

    # Test 3: Subscription references the bucket via bucketRef
    metav1alpha1.CompositionTest {
        metadata.name = "subscription-references-bucket"
        spec = {
            compositionPath = "apis/spotfeeds/composition.yaml"
            xrdPath = "apis/spotfeeds/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.SpotFeed {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-west-2"
                }
            }
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "SpotDatafeedSubscription"
                    metadata.name = "my-account-spot-feed"
                    spec.forProvider.bucket = "my-account-spot-feed"
                    spec.forProvider.region = "us-west-2"
                }
            ]
        }
    }

    # Test 4: Prefix is passed through when set
    metav1alpha1.CompositionTest {
        metadata.name = "prefix-passed-through"
        spec = {
            compositionPath = "apis/spotfeeds/composition.yaml"
            xrdPath = "apis/spotfeeds/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.SpotFeed {
                metadata.name = "my-account"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-1"
                    prefix = "spot-data/"
                }
            }
            assertResources = [
                {
                    apiVersion = "ec2.aws.m.upbound.io/v1beta1"
                    kind = "SpotDatafeedSubscription"
                    metadata.name = "my-account-spot-feed"
                    spec.forProvider.prefix = "spot-data/"
                }
            ]
        }
    }

    # Test 5: Custom tags are merged with defaults
    metav1alpha1.CompositionTest {
        metadata.name = "custom-tags-merged"
        spec = {
            compositionPath = "apis/spotfeeds/composition.yaml"
            xrdPath = "apis/spotfeeds/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = awsv1alpha1.SpotFeed {
                metadata.name = "tagged"
                spec = {
                    accountId = "123456789012"
                    region = "us-east-1"
                    tags = {
                        environment = "production"
                        team = "platform"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "s3.aws.m.upbound.io/v1beta1"
                    kind = "Bucket"
                    metadata.name = "tagged-spot-feed"
                    spec.forProvider.tags = {
                        "hops.ops.com.ai/managed" = "true"
                        "hops.ops.com.ai/spotfeed" = "tagged"
                        environment = "production"
                        team = "platform"
                    }
                }
            ]
        }
    }
]
items = _items
