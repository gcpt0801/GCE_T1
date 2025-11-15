# Image Selection Strategy

## Overview

This project now supports two ways to select images:

1. **Specific Image** (Dev) - Use exact image created by Packer
2. **Latest from Family** (Cert/Prod) - Automatically use the newest image

## How It Works

### Packer Creates Image Family

All Packer-built images are now part of the `custom-apache` family:

```hcl
image_family = "custom-apache"
```

This groups all your custom Apache images together, with GCP tracking which is newest.

### Terraform Image Selection

```terraform
# Data source fetches the latest image from the family
data "google_compute_image" "latest_custom_apache" {
  family  = "custom-apache"
  project = "gcp-terraform-demo-474514"
}

# Conditional logic selects image based on use_latest_image flag
image = var.use_latest_image ? 
        data.google_compute_image.latest_custom_apache.self_link : 
        var.image_name
```

## Configuration by Environment

### Dev Environment (`dev.tfvars`)

**Use Case:** Test the specific image just built

```hcl
use_latest_image = false  # Use specific image
# image_name provided by workflow: custom-apache-image-{run_id}
```

**Workflow provides:**
```bash
terraform apply -var "image_name=custom-apache-image-19388339951" -var-file="dev.tfvars"
```

### Cert Environment (`cert.tfvars`)

**Use Case:** Promote latest tested image to certification

```hcl
use_latest_image = true  # Automatically use latest
```

**Deploy to cert:**
```bash
terraform apply -var-file="cert.tfvars"
```

**No manual image selection needed!** Terraform automatically picks the newest image from the `custom-apache` family.

## Workflow Examples

### Scenario 1: Normal Dev → Cert Promotion

```
Day 1:
├─ Workflow builds: custom-apache-image-19388339951
├─ Dev deploys with:  custom-apache-image-19388339951
└─ Cert deploys with: custom-apache-image-19388339951 (latest)

Day 2:
├─ Workflow builds: custom-apache-image-19400123456
├─ Dev deploys with:  custom-apache-image-19400123456
└─ Cert STILL uses:   custom-apache-image-19388339951 (previous latest)

After testing Day 2 image in Dev:
└─ Run: terraform apply -var-file="cert.tfvars"
   Cert NOW uses:     custom-apache-image-19400123456 (new latest)
```

### Scenario 2: Rollback Capability

If the latest image has issues:

**Option A: Use specific known-good image**
```hcl
# cert.tfvars
use_latest_image = false
image_name = "custom-apache-image-19388339951"  # Known good version
```

**Option B: Delete bad image, promote previous**
```bash
# Delete the problematic image
gcloud compute images delete custom-apache-image-19400123456

# Cert will now use the previous image automatically
terraform apply -var-file="cert.tfvars"
```

## Commands Reference

### List Images in Family
```bash
gcloud compute images list \
  --filter="family:custom-apache" \
  --sort-by="~creationTimestamp" \
  --format="table(name,family,creationTimestamp)"
```

### Check Which Image Will Be Used
```bash
# See what Terraform will use
terraform plan -var-file="cert.tfvars"

# Check the latest image in the family
gcloud compute images describe-from-family custom-apache
```

### Deploy to Different Environments
```bash
# Dev - uses specific image from workflow
terraform apply -var "image_name=custom-apache-image-19388339951" -var-file="dev.tfvars"

# Cert - uses latest from family
terraform apply -var-file="cert.tfvars"

# Prod - could use latest or specific (configure prod.tfvars accordingly)
terraform apply -var-file="prod.tfvars"
```

## Outputs

After deployment, Terraform shows:

```
Outputs:

instance_ips = [
  "34.172.99.219",
]
image_used = "custom-apache-image-19388339951"
image_source = "Latest from custom-apache family"
```

## Benefits

| Feature | Dev (Specific) | Cert (Latest) |
|---------|---------------|---------------|
| **Image Selection** | Manual (workflow) | Automatic |
| **Traceability** | Exact workflow run | Latest approved |
| **Flexibility** | Test specific builds | Always current |
| **Rollback** | Specify any version | Delete bad image |
| **Promotion** | Build → Test | Test → Promote |

## Best Practices

1. **Dev Environment**
   - Always use specific image (`use_latest_image = false`)
   - Test the image thoroughly
   - Verify functionality

2. **Cert Environment**
   - Use latest from family (`use_latest_image = true`)
   - Automatic promotion of tested images
   - No manual image name updates needed

3. **Prod Environment**
   - Consider using specific image for stability
   - Or use latest after cert validation
   - Document which image is in production

4. **Image Management**
   - Keep 3-5 recent images for rollback
   - Delete very old images to save costs
   - Use image families for organization

## Troubleshooting

### Error: "No image found in family"
```
Error: googleapi: Error 404: The resource 'projects/.../images/family/custom-apache' was not found
```

**Solution:** Run Packer build first to create an image in the family:
```bash
cd packer
packer build -var "project_id=..." -var "image_name=..." template.pkr.hcl
```

### Error: "image_name must be provided"
```
Error: image_name must be provided when use_latest_image is false
```

**Solution:** Either:
- Set `use_latest_image = true` in your `.tfvars` file, OR
- Provide image name: `terraform apply -var "image_name=custom-apache-image-123"`

### Wrong Image Version Used

**Check which image will be used:**
```bash
terraform plan -var-file="cert.tfvars" | grep image
```

**Force refresh:**
```bash
terraform refresh -var-file="cert.tfvars"
terraform plan -var-file="cert.tfvars"
```
