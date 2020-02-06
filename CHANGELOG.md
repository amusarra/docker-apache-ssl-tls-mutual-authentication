# Changelog
Tutte le modifiche importanti a questo progetto saranno documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e questo progetto aderisce a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.7] - 2020-02-06
### Changed
- Disabled the TLSv1.3 protocol for the issue TLS 1.3: cannot perform post-handshake authentication.
  You can see this issue at this URL https://bugs.chromium.org/p/chromium/issues/detail?id=911653

## [1.2.6] - 2020-02-06
### Changed
- Updated Ubuntu from 18.04 to 19.10
- Updated Apache HTTP 2.4 to 2.2.41
- Added ServerTokens and ServerSignature Apache HTTP directive
- Added Support for TLS v1.3
- Added Support for Strict Transport Security 

## [1.2.5] - 2020-02-03
### Changed
- Let's Encrypt - Free SSL/TLS Certificates Updated
- Updated - Copyright year

## [1.2.4] - 2019-09-26
### Added
- Added Play-With-Docker button

## [1.2.3] - 2019-09-07
### Added
- Let's Encrypt - Free SSL/TLS Certificates Updated
- Add Apache environment for enable or disable SSL Proxy
- Add Apache environment for enable or disable the remote server certificates
- Add Apache environment for enable or disable proxy preserve host
- Upgrade README

## [1.2.2] - 2019-05-30
### Added
- Add Let's Encrypt - Free SSL/TLS Certificates
- Add the Secure API button
- Upgrade README

## [1.2.1] - 2019-04-25
### Changed
- Upgrade Jinja2 and rope for security reason
- Upgrade README

## [1.2.0] - 2019-04-25
### Added
- Include the [httpbin project](https://github.com/postmanlabs/httpbin.git). Project of [Kenneth Reitz](http://kennethreitz.org/bitcoin)

## [1.1.0] - 2019-04-17
### Added
- Regenerate all certificates with strong SHA2 alg
- Enabled HTTP/2 protocol
- Enabled PHP 7.2 FPM

## [1.0.0] - 2019-04-12
Prima release del progetto. Fare riferimento al README.md per maggiori dettagli
circa il progetto.