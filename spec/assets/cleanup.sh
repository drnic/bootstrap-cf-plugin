#!/bin/bash

bundle exec bosh -n delete release bosh-release
bundle exec bosh stemcells | grep bosh-stemcell | tr -d '|' | awk '{print $1 " "  $2}' | while read i; do
    echo removing stemcell $i
    bundle exec bosh -n delete stemcell $i
done
