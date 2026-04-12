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

// TestPlanAllModules runs tofu plan on every module.
// Requires AWS credentials (read-only). Plan never creates resources.
func TestPlanAllModules(t *testing.T) {
	t.Parallel()

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

			modDir := filepath.Join(rootDir, mod)
			vars := buildRequiredVars(t, modDir)

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir:    modDir,
				TerraformBinary: "tofu",
				Vars:            vars,
				NoColor:         true,
				PlanFilePath:    filepath.Join(t.TempDir(), "plan.tfplan"),
			})

			// Exit code 0 = no changes, 2 = changes detected (both OK for plan)
			// Only exit code 1 = error
			exitCode := terraform.InitAndPlanWithExitCode(t, terraformOptions)
			assert.NotEqual(t, 1, exitCode, "tofu plan failed for module: %s", mod)
		})
	}
}

// buildRequiredVars reads variables.tf and builds a map of required variables
// with sensible dummy values so tofu plan can run.
func buildRequiredVars(t *testing.T, modDir string) map[string]interface{} {
	t.Helper()
	vars := make(map[string]interface{})

	varsFile := filepath.Join(modDir, "variables.tf")
	content, err := os.ReadFile(varsFile)
	if err != nil {
		return vars
	}

	src := string(content)

	// Find all variable blocks
	varPattern := regexp.MustCompile(`variable\s+"(\w+)"\s*\{`)
	matches := varPattern.FindAllStringSubmatchIndex(src, -1)

	for _, match := range matches {
		varName := src[match[2]:match[3]]
		blockStart := match[0]

		// Find the matching closing brace for this variable block
		block := extractBlock(src[blockStart:])
		if block == "" {
			continue
		}

		// Skip variables that have a default
		if strings.Contains(block, "default") && regexp.MustCompile(`\bdefault\s*=`).MatchString(block) {
			continue
		}

		// Skip standard variables we always set
		if varName == "enabled" || varName == "tags" || varName == "region" {
			continue
		}

		// Determine type and assign appropriate dummy value
		vars[varName] = getDummyValue(varName, block)
	}

	return vars
}

// extractBlock extracts a complete HCL block starting from the given position
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

// getDummyValue returns an appropriate dummy value based on variable name and type
func getDummyValue(varName string, block string) interface{} {
	// Check type
	typePattern := regexp.MustCompile(`\btype\s*=\s*(\w+)`)
	typeMatch := typePattern.FindStringSubmatch(block)
	varType := "string"
	if typeMatch != nil {
		varType = typeMatch[1]
	}

	// Name-based heuristics for realistic values
	nameLower := strings.ToLower(varName)

	// ARN patterns
	if strings.HasSuffix(nameLower, "_arn") || nameLower == "arn" {
		if strings.Contains(nameLower, "role") {
			return "arn:aws:iam::123456789012:role/test-role"
		}
		if strings.Contains(nameLower, "policy") {
			return "arn:aws:iam::123456789012:policy/test-policy"
		}
		if strings.Contains(nameLower, "kms") {
			return "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
		}
		if strings.Contains(nameLower, "bucket") {
			return "arn:aws:s3:::test-bucket"
		}
		if strings.Contains(nameLower, "sns") || strings.Contains(nameLower, "topic") {
			return "arn:aws:sns:us-east-1:123456789012:test-topic"
		}
		if strings.Contains(nameLower, "certificate") || strings.Contains(nameLower, "acm") {
			return "arn:aws:acm:us-east-1:123456789012:certificate/test-cert"
		}
		if strings.Contains(nameLower, "firehose") {
			return "arn:aws:firehose:us-east-1:123456789012:deliverystream/test"
		}
		return "arn:aws:iam::123456789012:root"
	}

	// ID patterns
	if nameLower == "vpc_id" || strings.HasSuffix(nameLower, "_vpc_id") {
		return "vpc-12345678"
	}
	if nameLower == "subnet_id" || strings.HasSuffix(nameLower, "_subnet_id") {
		return "subnet-12345678"
	}
	if strings.Contains(nameLower, "subnet_ids") {
		return []string{"subnet-12345678"}
	}
	if strings.Contains(nameLower, "security_group_id") {
		if strings.Contains(block, "list") || strings.Contains(block, "set") {
			return []string{"sg-12345678"}
		}
		return "sg-12345678"
	}
	if strings.Contains(nameLower, "zone_id") || strings.Contains(nameLower, "hosted_zone") {
		return "Z1234567890ABC"
	}
	if strings.Contains(nameLower, "account_id") {
		return "123456789012"
	}

	// Policy/JSON patterns
	if strings.Contains(nameLower, "policy") && varType == "string" {
		return `{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject"],"Resource":"*"}]}`
	}
	if nameLower == "assume_role_policy" {
		return `{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}`
	}
	if nameLower == "definition" {
		return `{"StartAt":"Pass","States":{"Pass":{"Type":"Pass","End":true}}}`
	}

	// Specific names
	if nameLower == "domain_name" {
		return "test.example.com"
	}
	if nameLower == "bucket" {
		return "test-bucket-terratest"
	}
	if nameLower == "key" && strings.Contains(block, "S3 object key") {
		return "test-key"
	}
	if nameLower == "public_key" {
		return "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDtest test@test"
	}
	if nameLower == "dashboard_body" {
		return `{"widgets":[]}`
	}
	if nameLower == "schema" {
		return "type Query { test: String }"
	}
	if nameLower == "query_string" {
		return "fields @timestamp"
	}

	// Type-based fallback
	switch varType {
	case "number":
		return 1
	case "bool":
		return false
	case "list", "set":
		return []string{}
	case "map", "object":
		return map[string]interface{}{}
	case "any":
		// Check if block hints at the real type
		if strings.Contains(block, "map(") || strings.Contains(block, "object(") {
			return map[string]interface{}{}
		}
		if strings.Contains(block, "list(") || strings.Contains(block, "set(") {
			return []string{}
		}
		return ""
	default:
		// Complex types
		if strings.Contains(block, "map(") || strings.Contains(block, "object(") {
			return map[string]interface{}{}
		}
		if strings.Contains(block, "list(") || strings.Contains(block, "set(") {
			return []string{}
		}
		return "test-value"
	}
}

// discoverModules finds modules to test.
// If TEST_MODULES env var is set (comma-separated), only those modules are tested.
// Otherwise, discovers all directories containing main.tf.
func discoverModules(t *testing.T, rootDir string) []string {
	// Check for filtered module list (PR workflow sets this for changed modules only)
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

	// Full discovery
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
