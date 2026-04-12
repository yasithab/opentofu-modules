package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestValidateAllModules runs tofu validate on every module.
// No AWS credentials needed — checks syntax, types, and provider schema only.
func TestValidateAllModules(t *testing.T) {
	t.Parallel()

	rootDir, err := filepath.Abs("..")
	assert.NoError(t, err)
	modules := discoverModules(t, rootDir)

	for _, mod := range modules {
		mod := mod
		t.Run(mod, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir:    filepath.Join(rootDir, mod),
				TerraformBinary: "tofu",
			})

			terraform.InitAndValidate(t, terraformOptions)
		})
	}
}

// TestPlanAllModules runs tofu plan on every module with no variables.
// Requires AWS credentials (read-only). Plan never creates resources.
// This catches: invalid ARNs, bad IAM policies, data source resolution,
// cross-resource reference errors, and provider-level validation.
func TestPlanAllModules(t *testing.T) {
	t.Parallel()

	// Skip if no AWS credentials available (local dev without creds)
	if os.Getenv("AWS_DEFAULT_REGION") == "" && os.Getenv("AWS_REGION") == "" {
		t.Skip("Skipping plan tests: no AWS credentials configured (set AWS_REGION)")
	}

	rootDir, err := filepath.Abs("..")
	assert.NoError(t, err)
	modules := discoverModules(t, rootDir)

	for _, mod := range modules {
		mod := mod
		t.Run(mod, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir:    filepath.Join(rootDir, mod),
				TerraformBinary: "tofu",
				// No variables — modules should have sensible defaults
				// enabled defaults to true, but plan with no required vars
				// will fail for modules with required vars. We catch that.
				NoColor: true,
				PlanFilePath: filepath.Join(t.TempDir(), "plan.tfplan"),
			})

			// InitAndPlan runs init + plan. Plan calls AWS APIs (read-only)
			// but never creates resources. Exit code 0 = no changes (empty state),
			// exit code 2 = changes detected (expected for new modules).
			// Both are valid. Only exit code 1 (error) should fail.
			exitCode := terraform.InitAndPlanWithExitCode(t, terraformOptions)
			assert.NotEqual(t, 1, exitCode, "tofu plan failed with errors for module: %s", mod)
		})
	}
}

// discoverModules finds all directories containing main.tf
func discoverModules(t *testing.T, rootDir string) []string {
	var modules []string

	err := filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			name := info.Name()
			if strings.HasPrefix(name, ".") || name == "test" || name == "examples" {
				return filepath.SkipDir
			}
		}

		if info.Name() == "main.tf" && !strings.Contains(path, ".terraform") && !strings.Contains(path, "wrappers") {
			dir := filepath.Dir(path)
			rel, _ := filepath.Rel(rootDir, dir)
			modules = append(modules, rel)
		}

		return nil
	})

	assert.NoError(t, err)
	fmt.Printf("Discovered %d modules\n", len(modules))
	return modules
}
