## TypeScript

These settings apply only when `--typescript` is specified on the command line.
Please also specify `--typescript-sdks-folder=<path to root folder of your azure-sdk-for-js clone>`.

``` yaml $(typescript)
azure-arm: false
title: GeneratedClient
package-name: "@azure/maps-render"
license-header: MICROSOFT_MIT_NO_VERSION
output-folder: "$(typescript-sdks-folder)/sdk/maps/maps-render"
source-code-folder-path: "src/generated"
clear-output-folder: false
generate-metadata: false
add-credentials: false
credential-scopes: ""
use-extension:
  "@autorest/typescript": "6.0.0-beta.12"
  "@autorest/modelerfour": "4.19.3"
```
