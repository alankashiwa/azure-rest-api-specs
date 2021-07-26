#!/bin/bash

# npm install -g @microsoft/rush

if [[ -z $1 ]] ; then 
  echo "Using ../azure-sdk-for-js/ for js sdk"
  SDK_PATH="../azure-sdk-for-js"
else 
  SDK_PATH=$1
fi

VERSION=1.0.0

find specification/maps/data-plane/*/* -name "readme.md" -print | while read README_PATH ; do 
  # fails with openapi-document/multi-api/identity
  #TRACK1_COMMAND="autorest -typescript --verbose --license-header=MICROSOFT_MIT_NO_VERSION --typescript-sdks-folder=$SDK_PATH $README_PATH"
  TRACK2_COMMAND="autorest --typescript --track2 --license-header=MICROSOFT_MIT_NO_VERSION --typescript-sdks-folder=$SDK_PATH $README_PATH"

  README_FPATH=$(dirname $README_PATH)
  #SRCPATH=$(cat $README_FPATH/readme.typescript.md | grep '^\s*output-folder:' | sed "s/output-folder://" | xargs dirname)
  #SERVICE_NAME=$(dirname $SRCPATH | xargs basename)
  SERVICE_NAME=$(cat $README_FPATH/readme.typescript.md | grep '^\s*output-folder:' | sed "s/output-folder://" | xargs basename | sed 's/\r//g' )
  echo "SERVICE_NAME"
  echo $SERVICE_NAME
  TARGET_PATH="$SDK_PATH/sdk/maps/$SERVICE_NAME"
  echo "TARGET_PATH"
  echo $TARGET_PATH

  echo $TRACK2_COMMAND
  eval $TRACK2_COMMAND

  DESCRIPTION="A client library for Azure Maps ${SERVICE_NAME,,}"

  echo $TARGET_PATH
  cd $TARGET_PATH
  jq -s '.[0] + {
    name: "@azure/'"${SERVICE_NAME,,}"'",
    description: "'"${DESCRIPTION}"'",
    version: "'"${VERSION}"'"
  } | del(."//metadata") 
    | del(."//sampleConfiguration")
    + {module: "dist-esm/index.js", types: "types/'"${SERVICE_NAME,,}"'.d.ts"}
    | .dependencies += { 
      "@azure/core-paging": "^1.1.1",
      "@azure/core-lro": "^2.0.0",
      "@azure/abort-controller": "^1.0.0",
      "@azure/core-asynciterator-polyfill": "^1.0.0",
    }
    | .files = ["dist/", "dist-esm/", "types/'"${SERVICE_NAME,,}"'.d.ts"]
    | .scripts."build:types" = "downlevel-dts types types/3.1"
    | .typesVersions."<3.6"."*" = ["types/3.1/index.d.ts"]' ../../template/template/package.json > package.json

  jq -s '.[0] 
    | .compilerOptions += { noUnusedLocals: false, noUnusedParameters: false }
    | .compilerOptions.paths."@azure/'"${SERVICE_NAME,,}"'" = ["./src/generated/index"]
    | del(.compilerOptions.paths."@azure/template")' ../../template/template/tsconfig.json > tsconfig.json

  cp ../../template/template/rollup.config.js rollup.config.js
  jq -s '.[0] 
    | .mainEntryPointFilePath = "types/index.d.ts"
    | .dtsRollup.publicTrimmedFilePath = "types/'"${SERVICE_NAME,,}"'.d.ts"
  ' ../../template/template/api-extractor.json api-extractor.json > api-extractor.json

  # cannot parse json with commments with jq
  cat ../../../rush.json | head -n -3 > ../../../rush.temp.json
  mv ../../../rush.temp.json ../../../rush.json

  RUSH_CONFIG='    },
    {
      "packageName": "@azure/'"${SERVICE_NAME,,}"'", 
      "projectFolder": "sdk/maps/'"${SERVICE_NAME,,}"'",
      "versionPolicyName": "client"
    }
  ]  
}'
  echo "$RUSH_CONFIG" >> ../../../rush.json
  mkdir -p review
  cd -
done

cd $SDK_PATH
rush update 

find sdk/maps/maps-*/ -maxdepth 1 -name "package.json" -print | while read PACKAGEJSON_PATH ; do 
  TARGET_PATH="$(dirname $PACKAGEJSON_PATH)"
  RP=$(pwd)
  cd $TARGET_PATH
  
  #FIXME: circumvent @azure/core-lro not building at 1.0.2??? manual build in ./node_modules...
  cd ./node_modules/@azure/core-lro/
  rushx build
  cd -

  rushx build
  rushx pack
  cd $RP
done

# Taras 
# Loading AutoRest core '/home/ambientlight/.autorest/@autorest_core@3.1.3/node_modules/@autorest/core/dist' (3.1.3)
# INFORMATION: > Loading AutoRest extension '@autorest/typescript' (6.0.0-alpha.20210514.1->6.0.0-alpha.20210514.1)
# INFORMATION: > Loading AutoRest extension '@autorest/modelerfour' (4.15.456->4.15.456)

# Alan
# Loading AutoRest core      '/root/.autorest/@autorest_core@3.1.3/node_modules/@autorest/core/dist' (3.1.3)
# INFORMATION: > Loading AutoRest extension '@autorest/typescript' (latest->6.0.0-beta.8)
# INFORMATION: > Loading AutoRest extension '@autorest/modelerfour' (4.19.3->4.19.3)