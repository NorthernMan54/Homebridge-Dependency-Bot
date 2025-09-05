#!/bin/bash

# Test Configuration Validator
# This script validates the test configuration files and tests
# basic functionality of the action's configuration parsing logic.

set -e

echo "🧪 Testing Homebridge Dependency Bot Configuration Files"
echo "========================================================"

# Install required tools
echo "Installing required tools..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y jq > /dev/null 2>&1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0
fail_count=0

run_test() {
    local test_name="$1"
    local config_file="$2"
    local expected_result="$3"  # "pass" or "fail"
    
    test_count=$((test_count + 1))
    echo -n "Testing $test_name... "
    
    # Basic JSON validation
    if ! jq '.' "$config_file" > /dev/null 2>&1; then
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}PASS${NC} (expected failure)"
            pass_count=$((pass_count + 1))
        else
            echo -e "${RED}FAIL${NC} (invalid JSON)"
            fail_count=$((fail_count + 1))
        fi
        return
    fi
    
    # Validate required fields
    git_user_name=$(jq -r '.git_user.name // null' "$config_file")
    git_user_email=$(jq -r '.git_user.email // null' "$config_file")
    has_auto_merge=$(jq -r 'has("auto_merge")' "$config_file")
    directories=$(jq -r '.directories | type' "$config_file" 2>/dev/null || echo "null")
    
    # Check for required fields
    if [ "$git_user_name" = "null" ] || [ "$git_user_email" = "null" ] || \
       [ "$has_auto_merge" = "false" ] || [ "$directories" != "array" ]; then
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}PASS${NC} (expected failure - missing fields)"
            pass_count=$((pass_count + 1))
        else
            echo -e "${RED}FAIL${NC} (missing required fields)"
            fail_count=$((fail_count + 1))
        fi
        return
    fi
    
    # Validate directory structure and packages
    dirs_length=$(jq '.directories | length' "$config_file")
    validation_error=false
    
    for i in $(seq 0 $((dirs_length - 1))); do
        pkgs_length=$(jq ".directories[$i].packages | length" "$config_file")
        for j in $(seq 0 $((pkgs_length - 1))); do
            pkg_name=$(jq -r ".directories[$i].packages[$j].name" "$config_file")
            has_tag=$(jq -r ".directories[$i].packages[$j].tag // null" "$config_file")
            has_pattern=$(jq -r ".directories[$i].packages[$j].pattern // null" "$config_file")
            
            # Check for invalid combinations
            if [ "$has_tag" != "null" ] && [ "$has_pattern" != "null" ]; then
                validation_error=true
                break 2
            fi
            
            if [ "$has_tag" = "null" ] && [ "$has_pattern" = "null" ]; then
                validation_error=true
                break 2
            fi
        done
    done
    
    if [ "$validation_error" = "true" ]; then
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}PASS${NC} (expected failure - validation error)"
            pass_count=$((pass_count + 1))
        else
            echo -e "${RED}FAIL${NC} (validation error)"
            fail_count=$((fail_count + 1))
        fi
    else
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}PASS${NC}"
            pass_count=$((pass_count + 1))
        else
            echo -e "${RED}FAIL${NC} (expected failure but passed)"
            fail_count=$((fail_count + 1))
        fi
    fi
}

echo ""
echo "Running configuration validation tests..."
echo ""

# Test valid configurations
run_test "Valid tag-based config" "test-configs/valid-tag-config.json" "pass"
run_test "Valid pattern-based config" "test-configs/valid-pattern-config.json" "pass"
run_test "Multi-directory config" "test-configs/multi-directory-config.json" "pass"

# Test invalid configurations
run_test "Invalid: both tag and pattern" "test-configs/invalid-both-tag-pattern.json" "fail"
run_test "Invalid: neither tag nor pattern" "test-configs/invalid-neither-tag-pattern.json" "fail"

echo ""
echo "========================================================"
echo "Test Summary:"
echo "  Total tests: $test_count"
echo -e "  Passed: ${GREEN}$pass_count${NC}"
echo -e "  Failed: ${RED}$fail_count${NC}"
echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC} ✅"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC} ❌"
    exit 1
fi