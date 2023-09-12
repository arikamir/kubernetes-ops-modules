module "manifest_set" {
    source = "github.com/arikamir/kubernetes-ops-modules.git//terraform-modules/aws/kubernetes/manifest_set?ref=v2.0.12"

    upload_source_path = path.cwd
    upload_directory   = "yaml"
}
