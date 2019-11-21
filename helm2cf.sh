#!/bin/bash

# This script assumes the following layout
# /helm       -- Content of the Helm charts
# /manifests  -- Location where CF manifests are rendered
# /tmp        -- Scratch space

convert_to_manifest() {
    echo Converting [$i] ..
    BASE=$(get_helm_template_base)
    CHART_DIR=$BASE/charts/$1
    TEMPLATE_DIR=$CHART_DIR/templates
    MANIFEST_FILE=/manifests/$1.yml
    DEPLOYMENT_FILE=$TEMPLATE_DIR/deployment.yaml
    _depl() {
        echo $(yq r $DEPLOYMENT_FILE ${1})
    }
    _image=$(_depl 'spec.template.spec.containers[0].image')
    _replicas=$(_depl 'spec.replicas')
    _appname=$1
    _memory=1G
    _disk_quota=1G

    cat <<EOF > $MANIFEST_FILE
applications:
- name: $1
  disk_quota: $_disk_quota
  docker:
    image: $_image
  instances: $_replicas
  memory: $_memory
  routes:
  - route: $_appname.apps.internal
EOF
    # Convert to JSON for better handling
    _json=$(yq r -j $MANIFEST_FILE)
    # Add empty env. TODO: check if it's there and append
    _json=$(echo ${_json}|jq '.applications[0] |= .+ {env}')

    # Parsing environment variables
    _vars=$(yq r -j $TEMPLATE_DIR/deployment.yaml spec.template.spec.containers[0].env)

    if [ "x$_vars" != "xnull" ]; then
        _envs=$(echo $_vars|jq -c '.[] | @base64')
        for row in $_envs; do
            _jq() {
                echo ${row} | base64 -d | jq -r ${1}
            }
            _name=$(_jq '.name')
            _value=$(_jq '.value')
            _json=$(echo ${_json}|jq --arg name $_name --arg value "$_value" '.applications[0].env |= .+ {($name): $value}')
        done
    fi
    # ..Aaand back to yaml
    echo $_json | yq r - > $MANIFEST_FILE
}

render_helm_template() {
    echo Rendering templates to /tmp/yamls/helm
    rm -fr /tmp/yamls
    mkdir -p /tmp/yamls
    echo helm template --output-dir /tmp/yamls /helm $@
    helm template --output-dir /tmp/yamls /helm $@
    test $? -eq 0 || exit $?
}

get_helm_template_base() {
    echo /tmp/yamls/$(get_helm_name)
}
get_helm_name() {
    __name=$(yq r /helm/Chart.yaml name)
    echo $__name
}

get_charts_from_requirements_yaml() {
    __charts=$(yq r -j /helm/requirements.yaml|jq -r .dependencies[].name)
    echo $__charts
}

convert_helm_charts() {
    CHARTS=$(get_charts_from_requirements_yaml)
    echo Finding and converting charts ..
    for i in $CHARTS; do
        CHART=/helm/charts/$i
        if [ -f $CHART/Chart.yaml ]; then
            convert_to_manifest $i
        fi
    done
}

main() {
    echo Helm: $(get_helm_name)
    render_helm_template $@
    convert_helm_charts
}

main $@
