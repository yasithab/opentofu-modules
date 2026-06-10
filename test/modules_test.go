package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestValidateAllModules runs tofu validate on every module.
// No AWS credentials needed.
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

// TestPlanAllModules runs tofu plan on modules that have a test/test.tfvars file.
// Requires AWS credentials (read-only). Plan never creates resources.
//
// To enable plan testing for a module, create a test/test.tfvars file in
// the module directory with realistic variable values. Modules without
// this file are skipped (they still pass validate tests above).
//
// After a successful plan the test asserts that at least one resource change
// is planned - an empty plan almost always means the fixture left the module
// fully toggled off, which silently tests nothing. A module that legitimately
// plans zero resources with its default fixture can opt out by adding an
// empty marker file at test/allow-empty-plan.
func TestPlanAllModules(t *testing.T) {
	t.Parallel()
	requirePlanCredentials(t)

	rootDir, err := filepath.Abs("..")
	assert.NoError(t, err)
	modules := discoverModules(t, rootDir)

	plannable := 0
	for _, mod := range modules {
		mod := mod
		modDir := filepath.Join(rootDir, mod)
		tfvarsFile := filepath.Join(modDir, "test/test.tfvars")

		if _, err := os.Stat(tfvarsFile); os.IsNotExist(err) {
			continue // No test/test.tfvars - skip this module
		}

		plannable++
		t.Run(mod, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir:    modDir,
				TerraformBinary: "tofu",
				VarFiles:        []string{tfvarsFile},
				NoColor:         true,
				PlanFilePath:    filepath.Join(t.TempDir(), "plan.tfplan"),
			})

			plan, err := terraform.InitAndPlanAndShowWithStructE(t, terraformOptions)
			require.NoError(t, err, "tofu plan failed for module: %s", mod)

			if _, statErr := os.Stat(filepath.Join(modDir, "test/allow-empty-plan")); statErr == nil {
				return // Module explicitly allows an empty default plan
			}
			assert.NotEmpty(t, plan.ResourceChangesMap,
				"tofu plan for module %s planned zero resource changes - the default fixture is testing nothing. Fix test/test.tfvars or, if the module is genuinely conditional, add a test/allow-empty-plan marker file", mod)
		})
	}

	if plannable == 0 {
		t.Log("No modules have test/test.tfvars - add one to enable plan testing for a module")
	}
}

// TestPlanFixtures runs one tofu plan per optional test/fixtures/plan-*.tfvars
// file, exercising additional plan paths beyond the default test/test.tfvars
// fixture (e.g. alternate feature toggles). Each plan-*.tfvars must be a
// complete, standalone variable set - it is the only var file passed to plan.
// Requires AWS credentials, same gating as TestPlanAllModules.
func TestPlanFixtures(t *testing.T) {
	t.Parallel()
	requirePlanCredentials(t)

	rootDir, err := filepath.Abs("..")
	assert.NoError(t, err)
	modules := discoverModules(t, rootDir)

	found := 0
	for _, mod := range modules {
		mod := mod
		modDir := filepath.Join(rootDir, mod)

		fixtures, err := filepath.Glob(filepath.Join(modDir, "test", "fixtures", "plan-*.tfvars"))
		require.NoError(t, err)

		for _, fixture := range fixtures {
			fixture := fixture
			found++
			name := strings.TrimSuffix(filepath.Base(fixture), ".tfvars")
			t.Run(mod+"/"+name, func(t *testing.T) {
				t.Parallel()

				terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
					TerraformDir:    modDir,
					TerraformBinary: "tofu",
					VarFiles:        []string{fixture},
					NoColor:         true,
					PlanFilePath:    filepath.Join(t.TempDir(), "plan.tfplan"),
				})

				exitCode := terraform.InitAndPlanWithExitCode(t, terraformOptions)
				assert.NotEqual(t, 1, exitCode, "tofu plan failed for fixture: %s/%s", mod, name)
			})
		}
	}

	if found == 0 {
		t.Log("No modules have test/fixtures/plan-*.tfvars - add one to exercise additional plan paths")
	}
}

// TestDisabledAllModules proves that every module that declares
// variable "enabled" can be planned with enabled = false and that the
// resulting plan contains zero create/update/delete actions. This catches the
// historical bug class where enabled = false breaks the plan (e.g. index
// errors on empty resource collections) or still plans resources.
//
// The override is applied as a final -var-file so it wins over any enabled
// value set in test/test.tfvars. Modules without test/test.tfvars or without
// an enabled variable (e.g. thin submodules) are skipped.
// Requires AWS credentials, same gating as TestPlanAllModules.
func TestDisabledAllModules(t *testing.T) {
	t.Parallel()
	requirePlanCredentials(t)

	rootDir, err := filepath.Abs("..")
	assert.NoError(t, err)
	modules := discoverModules(t, rootDir)

	for _, mod := range modules {
		mod := mod
		modDir := filepath.Join(rootDir, mod)
		tfvarsFile := filepath.Join(modDir, "test/test.tfvars")

		if _, err := os.Stat(tfvarsFile); os.IsNotExist(err) {
			continue // No test/test.tfvars - skip this module
		}
		if !moduleHasEnabledVariable(modDir) {
			continue // Module does not declare variable "enabled"
		}

		t.Run(mod, func(t *testing.T) {
			t.Parallel()

			// Written as the last var file so it overrides any enabled value
			// in test/test.tfvars (terratest passes VarFiles in order and the
			// last -var-file wins).
			disabledTfvars := filepath.Join(t.TempDir(), "disabled.tfvars")
			require.NoError(t, os.WriteFile(disabledTfvars, []byte("enabled = false\n"), 0o644))

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir:    modDir,
				TerraformBinary: "tofu",
				VarFiles:        []string{tfvarsFile, disabledTfvars},
				NoColor:         true,
				PlanFilePath:    filepath.Join(t.TempDir(), "plan.tfplan"),
			})

			plan, err := terraform.InitAndPlanAndShowWithStructE(t, terraformOptions)
			require.NoError(t, err, "tofu plan with enabled=false failed for module: %s", mod)

			var changed []string
			for address, rc := range plan.ResourceChangesMap {
				if rc.Change == nil {
					continue
				}
				for _, action := range rc.Change.Actions {
					switch string(action) {
					case "create", "update", "delete":
						changed = append(changed, fmt.Sprintf("%s (%s)", address, action))
					}
				}
			}
			assert.Empty(t, changed,
				"module %s planned resource changes with enabled=false - the enabled toggle is leaking: %s", mod, strings.Join(changed, ", "))
		})
	}
}

// TestInvalidFixtures proves that variable validations actually fire.
// Every test/fixtures/invalid-*.tfvars file inside a module is a fixture that
// MUST fail tofu plan with a variable validation error. Each invalid fixture
// must be standalone: it includes the module's normally-required happy-path
// variables so that ONLY the targeted validation fails.
//
// No AWS credentials needed: variable validations are evaluated during plan
// expression evaluation, before provider authentication (verified
// empirically - an invalid fixture fails with "Invalid value for variable"
// even without credentials). The test asserts on that error string rather
// than the bare exit code, so a plan that fails for unrelated reasons (e.g.
// missing credentials on an accidentally-valid fixture) does not pass
// vacuously.
func TestInvalidFixtures(t *testing.T) {
	t.Parallel()

	rootDir, err := filepath.Abs("..")
	assert.NoError(t, err)
	modules := discoverModules(t, rootDir)

	found := 0
	for _, mod := range modules {
		mod := mod
		modDir := filepath.Join(rootDir, mod)

		fixtures, err := filepath.Glob(filepath.Join(modDir, "test", "fixtures", "invalid-*.tfvars"))
		require.NoError(t, err)

		for _, fixture := range fixtures {
			fixture := fixture
			found++
			name := strings.TrimSuffix(filepath.Base(fixture), ".tfvars")
			t.Run(mod+"/"+name, func(t *testing.T) {
				t.Parallel()

				// Deliberately not using WithDefaultRetryableErrors: the plan
				// is expected to fail and must not be retried.
				terraformOptions := &terraform.Options{
					TerraformDir:    modDir,
					TerraformBinary: "tofu",
					VarFiles:        []string{fixture},
					NoColor:         true,
				}

				output, err := terraform.InitAndPlanE(t, terraformOptions)
				require.Error(t, err,
					"tofu plan succeeded for invalid fixture %s/%s - the validation it targets is not firing", mod, name)
				assert.Contains(t, output, "Invalid value for variable",
					"tofu plan for invalid fixture %s/%s failed, but not with a variable validation error - the fixture is broken for an unintended reason", mod, name)
			})
		}
	}

	if found == 0 {
		t.Log("No modules have test/fixtures/invalid-*.tfvars - add one to prove a variable validation fires")
	}
}

// requirePlanCredentials gates plan-based tests on AWS configuration.
// Locally the test is skipped when AWS is not configured; in CI a missing AWS
// configuration means the OIDC credential step silently failed, so fail hard.
func requirePlanCredentials(t *testing.T) {
	t.Helper()

	if os.Getenv("AWS_DEFAULT_REGION") == "" && os.Getenv("AWS_REGION") == "" {
		if os.Getenv("CI") == "true" {
			t.Fatal("CI run without AWS credentials configured (set AWS_REGION) - plan tests must not be skipped in CI")
		}
		t.Skip("Skipping plan tests: no AWS credentials configured (set AWS_REGION)")
	}
}

// moduleHasEnabledVariable reports whether the module declares
// variable "enabled" in its variables.tf.
func moduleHasEnabledVariable(modDir string) bool {
	content, err := os.ReadFile(filepath.Join(modDir, "variables.tf"))
	if err != nil {
		return false
	}
	return strings.Contains(string(content), `variable "enabled"`)
}

// discoverModules finds modules to test.
// If TEST_MODULES env var is set (comma-separated), only those modules are tested.
// Otherwise, discovers all directories containing main.tf.
func discoverModules(t *testing.T, rootDir string) []string {
	if filterEnv := os.Getenv("TEST_MODULES"); filterEnv != "" {
		var modules []string
		for _, mod := range strings.Split(filterEnv, ",") {
			mod = strings.TrimSpace(mod)
			if mod != "" {
				modules = append(modules, mod)
			}
		}
		fmt.Printf("Testing %d filtered modules (from TEST_MODULES)\n", len(modules))
		return modules
	}

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
