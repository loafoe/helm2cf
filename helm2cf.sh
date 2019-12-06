#!/bin/bash

# This script assumes the following layout
# /helm       -- Content of the Helm charts
# /manifests  -- Location where CF manifests are rendered
# /tmp        -- Scratch space

get_helm_template_base() {
    echo /tmp/yamls/$(get_helm_name)
}

get_helm_name() {
    __name=$(yq r /helm/Chart.yaml name)
    echo $__name
}

convert_chart_to_manifests() {
    echo Converting [$1]
    BASE=$(get_helm_template_base)
    CHART_DIR=$BASE/charts/$1
    convert_folder_with_templates_to_manifests $CHART_DIR
}

convert_folder_with_templates_to_manifests() {
    for template in $1/templates/*.yaml; do
        echo Parsing $template ..
        convert_template_to_manifest $template
    done
}

convert_template_to_manifest() {
    _deployment_file=$1
    if [ ! -f $_deployment_file ]; then
        return 404
    fi

    _depl() {
        echo $(yq r $_deployment_file ${1})
    }
    _kind=$(_depl 'kind')
    if [ "x$_kind" != "xDeployment" ]; then
        return 400
    fi

    _name=$(_depl 'metadata.name')
    _image=$(_depl 'spec.template.spec.containers[0].image')
    _replicas=$(_depl 'spec.replicas')
    _memory=1G
    _disk_quota=1G
    MANIFEST_FILE=/manifests/$_name.yml

    cat <<EOF > $MANIFEST_FILE
applications:
- name: $_name
  disk_quota: $_disk_quota
  docker:
    image: $_image
  instances: $_replicas
  memory: $_memory
  routes:
  - route: $_name.apps.internal
EOF
    # Convert to JSON for better handling
    _json=$(yq r -j $MANIFEST_FILE)
    # Add empty env. TODO: check if it's there and append
    _json=$(echo ${_json}|jq '.applications[0] |= .+ {env}')

    # Parsing environment variables
    _vars=$(yq r -j $_deployment_file spec.template.spec.containers[0].env)

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



get_charts_from_requirements_yaml() {
    if [ ! -f /helm/requirements.yaml ]; then
        echo ""
        return 404
    fi
    __charts=$(yq r -j /helm/requirements.yaml|jq -r .dependencies[].name)
    echo $__charts
}

convert_helm_templates() {
    convert_folder_with_templates_to_manifests $(get_helm_template_base)
}

convert_helm_charts() {
    CHARTS=$(get_charts_from_requirements_yaml)
    echo Finding and converting charts ..
    for i in $CHARTS; do
        CHART=/helm/charts/$i
        if [ -f $CHART/Chart.yaml ]; then
            convert_chart_to_manifests $i
        fi
    done
}

main() {
    echo Helm: $(get_helm_name)
    render_helm_template $@
    convert_helm_templates
    convert_helm_charts
}

main $@
