instance_count = 1
machine_type   = "n2-standard-2"
zone           = "us-central1-a"

# Dev uses specific image created by workflow
use_latest_image = false
# image_name is provided by the workflow via -var flag
# Format: custom-apache-image-{github.run_id}