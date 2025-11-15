# Certification Environment Configuration
# This configuration promotes the latest custom image from dev to cert

instance_count = 1
machine_type   = "n2-standard-4"
zone           = "us-central1-b"

# Automatically use the latest image from the custom-apache family
# This picks the most recently created image without manual intervention
use_latest_image = true

# Alternative: To use a specific image, set use_latest_image = false
# and specify the image name:
# use_latest_image = false
# image_name = "custom-apache-image-19388339951"
