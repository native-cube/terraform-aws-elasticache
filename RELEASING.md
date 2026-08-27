# Releasing

This repository uses unprefixed semantic version tags in `MAJOR.MINOR.PATCH` form, such as `1.0.0`.

## 1.0.0 checklist

1. Confirm the GitHub repository is public, is named `terraform-aws-elasticache`, and has a concise repository description.
2. Confirm the repository's license or internal usage terms are explicitly set according to the owner's policy.
3. Update `CHANGELOG.md` with the release date and final user-facing changes.
4. Run `make release-check` with Terraform, terraform-docs, TFLint, Trivy, and jq installed.
5. Merge the release changes to `main` and confirm both GitHub Actions jobs pass.
6. Create and push the annotated tag:

   ```shell
   git tag -a 1.0.0 -m "terraform-aws-elasticache 1.0.0"
   git push origin 1.0.0
   ```

7. Create GitHub release notes from `CHANGELOG.md` and verify the tag appears in the intended public or private Terraform Registry.

Release tags must not include a prefix. Do not reuse or move a published version tag. If a release needs correction, make the fix and publish a new patch version.
