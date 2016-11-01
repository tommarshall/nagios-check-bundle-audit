#!/usr/bin/env bats

load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'
load 'test_helper'

# Validation
# ------------------------------------------------------------------------------
@test "exits UNKNOWN if unrecognised option provided" {
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --not-an-arg
  assert_failure 3
  assert_line "UNKNOWN: Unrecognised argument: --not-an-arg"
  assert_line --partial "Usage:"
}

@test "exits UNKNOWN if --path/-p not provided" {
  run $BASE_DIR/check_bundle_audit
  assert_failure 3
  assert_output "UNKNOWN: --path/-p not set"
}

@test "exits UNKNOWN if Gemfile.lock missing" {
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 3
  assert_output "UNKNOWN: Unable to find Gemfile.lock"
}

@test "exits UNKNOWN if bundle-audit missing" {
  PATH='/bin'
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 3
  assert_output "UNKNOWN: Unable to find bundle-audit"
}

@test "exits UNKNOWN if unable update the ruby advisory db" {
  load_fixture clean
  HOME='/root'
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 3
  assert_output "UNKNOWN: Unable to update ruby-advisory-db"
}

@test "exits UNKNOWN if unable to parse report" {
  load_fixture clean
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --bundle-audit-path /bin/echo
  assert_failure 3
  assert_output "UNKNOWN: Unable to parse bundle-audit report"
}

# Defaults
# ------------------------------------------------------------------------------
@test "exits OK if no vulnerabilities present" {
  load_fixture clean
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_success
  assert_output "OK: No vulnerabilities found"
}

@test "exits WARNING if low vulnerability present" {
  load_fixture dirty-low
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 1
  assert_output "WARNING: 1 vulnerabilities found (0 high, 0 medium, 1 low, 0 unknown)"
}

@test "exits WARNING if medium vulnerability present" {
  load_fixture dirty-medium
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 1
  assert_output "WARNING: 1 vulnerabilities found (0 high, 1 medium, 0 low, 0 unknown)"
}

@test "exits CRITICAL if high vulnerability present" {
  load_fixture dirty-high
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 2
  assert_output "CRITICAL: 1 vulnerabilities found (1 high, 0 medium, 0 low, 0 unknown)"
}

@test "exits CRITICAL if unknown vulnerability present" {
  load_fixture dirty-unknown
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 2
  assert_output "CRITICAL: 1 vulnerabilities found (0 high, 0 medium, 0 low, 1 unknown)"
}

@test "exits CRITICAL if high, medium & low vulnerabilies present" {
  load_fixture dirty-all
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY
  assert_failure 2
  assert_output "CRITICAL: 4 vulnerabilities found (1 high, 1 medium, 1 low, 1 unknown)"
}

# --path
# ------------------------------------------------------------------------------
@test "-p is an alias for --path" {
  load_fixture dirty-all
  run $BASE_DIR/check_bundle_audit -p $TMP_DIRECTORY
  assert_failure 2
  assert_output "CRITICAL: 4 vulnerabilities found (1 high, 1 medium, 1 low, 1 unknown)"
}

# --critical
# ------------------------------------------------------------------------------
@test "--critical takes prescence over warning" {
  load_fixture dirty-low
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --critical high,medium,low,unknown
  assert_failure 2
  assert_output "CRITICAL: 1 vulnerabilities found (0 high, 0 medium, 1 low, 0 unknown)"
}

@test "--critical takes 'all' alias" {
  load_fixture dirty-low
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --critical all
  assert_failure 2
  assert_output "CRITICAL: 1 vulnerabilities found (0 high, 0 medium, 1 low, 0 unknown)"
}

@test "--critical can be none" {
  load_fixture dirty-high
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --critical ''
  assert_failure 1
  assert_output "WARNING: 1 vulnerabilities found (1 high, 0 medium, 0 low, 0 unknown)"
}

@test "-c is an alias for --critical" {
  load_fixture dirty-low
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY -c high,medium,low,unknown
  assert_failure 2
  assert_output "CRITICAL: 1 vulnerabilities found (0 high, 0 medium, 1 low, 0 unknown)"
}

# --warning
# ------------------------------------------------------------------------------
@test "--warning takes 'all' alias" {
  load_fixture dirty-high
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --critical '' --warning all
  assert_failure 1
  assert_output "WARNING: 1 vulnerabilities found (1 high, 0 medium, 0 low, 0 unknown)"
}

@test "--warning can be none" {
  load_fixture dirty-low
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --warning ''
  assert_success
  assert_output "OK: 1 vulnerabilities found (0 high, 0 medium, 1 low, 0 unknown)"
}

@test "-w is an alias for --warning" {
  load_fixture dirty-high
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --critical '' -w all
  assert_failure 1
  assert_output "WARNING: 1 vulnerabilities found (1 high, 0 medium, 0 low, 0 unknown)"
}

# --bundle-audit-path
# ------------------------------------------------------------------------------

@test "--bundle-audit-path overrides default" {
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY --bundle-audit-path /not-a-path
  assert_failure 3
  assert_output "UNKNOWN: Unable to find bundle-audit"
}

@test "-b is an alias for --bundle-audit-path" {
  run $BASE_DIR/check_bundle_audit --path $TMP_DIRECTORY -b /not-a-path
  assert_failure 3
  assert_output "UNKNOWN: Unable to find bundle-audit"
}

# --version
# ------------------------------------------------------------------------------
@test "--version prints the version" {
  run $BASE_DIR/check_bundle_audit --version
  assert_success
  [[ "$output" == "check_bundle_audit "?.?.? ]]
}

@test "-v is an alias for --version" {
  run $BASE_DIR/check_bundle_audit -v
  assert_success
  [[ "$output" == "check_bundle_audit "?.?.? ]]
}

# --help
# ------------------------------------------------------------------------------
@test "--help prints the usage" {
  run $BASE_DIR/check_bundle_audit --help
  assert_success
  assert_line --partial "Usage: ./check_bundle_audit -p <path> [options]"
}

@test "-h is an alias for --help" {
  run $BASE_DIR/check_bundle_audit -h
  assert_success
  assert_line --partial "Usage: ./check_bundle_audit -p <path> [options]"
}
