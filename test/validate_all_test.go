package test

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
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

// TestPlanAllModules runs tofu plan on modules that have a terratest.tfvars file.
// Requires AWS credentials (read-only). Plan never creates resources.
//
// To enable plan testing for a module, create a terratest.tfvars file in
// the module directory with realistic variable values. Modules without
// this file are skipped (they still pass validate tests above).
func TestPlanAllModules(t *testing.T) {
	t.Parallel()

	if os.Getenv("AWS_DEFAULT_REGION") == "" && os.Getenv("AWS_REGION") == "" {
		t.Skip("Skipping plan tests: no AWS credentials configured (set AWS_REGION)")
	}

	rootDir, err := filepath.Abs("..")
	assert.NoError(t, err)
	modules := discoverModules(t, rootDir)

	plannable := 0
	for _, mod := range modules {
		mod := mod
		modDir := filepath.Join(rootDir, mod)
		tfvarsFile := filepath.Join(modDir, "terratest.tfvars")

		if _, err := os.Stat(tfvarsFile); os.IsNotExist(err) {
			continue // No terratest.tfvars — skip this module
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

			exitCode := terraform.InitAndPlanWithExitCode(t, terraformOptions)
			assert.NotEqual(t, 1, exitCode, "tofu plan failed for module: %s", mod)
		})
	}

	if plannable == 0 {
		t.Log("No modules have terratest.tfvars — add one to enable plan testing for a module")
	}
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

// buildRequiredVars is kept for backward compatibility but no longer used
// by TestPlanAllModules (which now uses terratest.tfvars files instead).
func buildRequiredVars(t *testing.T, modDir string) map[string]interface{} {
	t.Helper()
	vars := make(map[string]interface{})

	varsFile := filepath.Join(modDir, "variables.tf")
	content, err := os.ReadFile(varsFile)
	if err != nil {
		return vars
	}

	src := string(content)
	varPattern := regexp.MustCompile(`variable\s+"(\w+)"\s*\{`)
	matches := varPattern.FindAllStringSubmatchIndex(src, -1)

	for _, match := range matches {
		varName := src[match[2]:match[3]]
		block := extractBlock(src[match[0]:])
		if block == "" || regexp.MustCompile(`\bdefault\s*=`).MatchString(block) {
			continue
		}
		if varName == "enabled" || varName == "tags" || varName == "region" {
			continue
		}
		vars[varName] = "test-value"
	}

	return vars
}

func extractBlock(s string) string {
	depth := 0
	started := false
	for i, ch := range s {
		if ch == '{' {
			depth++
			started = true
		} else if ch == '}' {
			depth--
		}
		if started && depth == 0 {
			return s[:i+1]
		}
	}
	return ""
}
