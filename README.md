# Nagios check_bundle_audit

[![Build Status](https://travis-ci.org/tommarshall/nagios-check-bundle-audit.svg?branch=master)](https://travis-ci.org/tommarshall/nagios-check-bundle-audit)

Nagios plugin to monitor ruby applications for security vulnerabilities via [bundler-audit](https://github.com/rubysec/bundler-audit).

## Installation

Install the [bundler-audit](https://github.com/rubysec/bundler-audit) gem.

Download the [check_bundle_audit](https://cdn.rawgit.com/tommarshall/nagios-check-bundle-audit/v0.2.0/check_bundle_audit) script and make it executable.

Define a new `command` in the Nagios config, e.g.

```
define command {
    command_name    check_bundle_audit
    command_line    $USER1$/check_bundle_audit -p /var/www/app
}
```

## Usage

```sh
./check_bundle_audit -p <path> [options]
```

### Examples

```sh
# 'Unknown' or 'High' CVEs exit CRITICAL; 'Medium' or 'Low' exit WARNING
./check_bundle_audit -p /var/www/app

# exit CRITICAL if any CVE(s) are present
./check_bundle_audit -p /var/www/app -c all

# exit WARNING if any CVE(s) (including high) are present
./check_bundle_audit -p /var/www/app -c '' -w all

# 'High' CVEs exit CRITICAL; 'Unknown' or 'Medium' exit WARNING; 'Low' exit OK
./check_bundle_audit -p /var/www/app -c high -w medium,unknown

# 'High' CVEs exit CRITICAL; 'Medium', 'Low' or 'Unknown' exit WARNING
./check_bundle_audit -p /var/www/app -c high -w medium,low,unknown

# set full path to bundle-audit
./check_bundle_audit -p /var/www/app -b /usr/local/bin/bundle-audit
```

### Options

```
-p, --path <path>              path to project
-b  --bundle-audit-path        path to `bundle-audit` gem
-w, --warning <criticalities>  comma seperated CVE criticalities to treat as WARNING
-c, --critical <criticalities> comma seperated CVE criticalities to treat as CRITICAL
-v, --version                  output version
-h, --help                     output help information
```

#### Criticalities
* `-c/--critical` takes priority over `-w/--warning`.
* `-c/--critical` default is `high,unknown`.
* `-w/--warning` default is `low,medium,high,unknown`.
* Criticality levels:
 * `low`
 * `medium`
 * `high`
 * `unknown`
 * `all` (alias for `low,medium,high,unknown`)

## Dependencies

* bash
* [bundler-audit](https://github.com/rubysec/bundler-audit)
