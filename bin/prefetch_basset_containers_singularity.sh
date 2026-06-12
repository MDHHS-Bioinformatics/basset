#!/usr/bin/env bash
set -euo pipefail

: "${NXF_SINGULARITY_CACHEDIR:?Please set NXF_SINGULARITY_CACHEDIR before running this script}"

CACHE="$NXF_SINGULARITY_CACHEDIR"
export NXF_SINGULARITY_CACHEDIR="$CACHE"
export SINGULARITY_CACHEDIR="$CACHE/singularity-oci-cache"

mkdir -p "$NXF_SINGULARITY_CACHEDIR" "$SINGULARITY_CACHEDIR"

singularity cache clean --force || true

pull_image () {
    local uri="$1"
    local name="$2"
    local sif="${CACHE}/${name}.img"

    if [[ -s "$sif" ]]; then
        echo "Already exists: $sif"
    else
        echo "Pulling: $uri"
        singularity pull --force --name "$sif" "$uri"
    fi
}

pull_image 'docker://quay.io/biocontainers/abricate@sha256:56f97396771e638bd3d1660f32afcb34c111734956498dd3a4ed6dae40a1137d' 'quay.io-biocontainers-abricate@sha256-56f97396771e638bd3d1660f32afcb34c111734956498dd3a4ed6dae40a1137d'

pull_image 'docker://quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' 'quay.io-biocontainers-pandas@sha256-509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'

pull_image 'docker://quay.io/biocontainers/ectyper@sha256:eb98dad0da8a8dbf8864ab724aa51bd59db1a5a80705cadb9c6e0a834ab4ba85' 'quay.io-biocontainers-ectyper@sha256-eb98dad0da8a8dbf8864ab724aa51bd59db1a5a80705cadb9c6e0a834ab4ba85'

pull_image 'docker://quay.io/staphb/elgato@sha256:4841ee5642816725358e173ca91c01f6fb2eece5b3a82dca8e175081f52ccc40' 'quay.io-staphb-elgato@sha256-4841ee5642816725358e173ca91c01f6fb2eece5b3a82dca8e175081f52ccc40'

pull_image 'docker://quay.io/staphb/emmtyper@sha256:544873e26de1753691f7765118cfc6295e18c46008a70968b251ad830ebf344a' 'quay.io-staphb-emmtyper@sha256-544873e26de1753691f7765118cfc6295e18c46008a70968b251ad830ebf344a'

pull_image 'docker://quay.io/biocontainers/hicap@sha256:c9d2d2bb63c1a869543217f79cd08c85989a8fac145f61b5402babbc4670764a' 'quay.io-biocontainers-hicap@sha256-c9d2d2bb63c1a869543217f79cd08c85989a8fac145f61b5402babbc4670764a'

pull_image 'docker://quay.io/staphb/kaptive@sha256:dbf67cd9a82269e03cd0b0dbeb7079112d9ae50557eed0c1edc6011b4cf007a8' 'quay.io-staphb-kaptive@sha256-dbf67cd9a82269e03cd0b0dbeb7079112d9ae50557eed0c1edc6011b4cf007a8'

pull_image 'docker://quay.io/biocontainers/kleborate@sha256:51d5627fb1835f0e8600ef38dc1ed63c823cc0babe4e4f1e73e5f1a4722817cf' 'quay.io-biocontainers-kleborate@sha256-51d5627fb1835f0e8600ef38dc1ed63c823cc0babe4e4f1e73e5f1a4722817cf'

pull_image 'docker://quay.io/biocontainers/lissero@sha256:7f98157516187944a503985e8a307f666207b4e3c2969abe5235b2b328fad007' 'quay.io-biocontainers-lissero@sha256-7f98157516187944a503985e8a307f666207b4e3c2969abe5235b2b328fad007'

pull_image 'docker://quay.io/biocontainers/meningotype@sha256:db45c259335cc7ad549e7a965d32f85c8b1ebaa42034ae625463772d90cb7af2' 'quay.io-biocontainers-meningotype@sha256-db45c259335cc7ad549e7a965d32f85c8b1ebaa42034ae625463772d90cb7af2'

pull_image 'docker://quay.io/biocontainers/shigatyper@sha256:a7f11cb5a43d48f977dc87fb2ec3f4b9f259d5ac79b5cb531cc80a7f67042c37' 'quay.io-biocontainers-shigatyper@sha256-a7f11cb5a43d48f977dc87fb2ec3f4b9f259d5ac79b5cb531cc80a7f67042c37'

pull_image 'docker://quay.io/biocontainers/sccmec@sha256:6b8f6b25bd125bbc9b5997fbea9a2a61c56659594af65c47c3790b34d4c34a76' 'quay.io-biocontainers-sccmec@sha256-6b8f6b25bd125bbc9b5997fbea9a2a61c56659594af65c47c3790b34d4c34a76'

pull_image 'docker://quay.io/biocontainers/agrvate@sha256:69a7f3d16d6641206a9c1dd09c5f1c3e68ace8e50c4593703dbff52399a5aa03' 'quay.io-biocontainers-agrvate@sha256-69a7f3d16d6641206a9c1dd09c5f1c3e68ace8e50c4593703dbff52399a5aa03'

pull_image 'docker://quay.io/biocontainers/shigeifinder@sha256:938e6d771ce71f87b625c0ff616d595d55b0b742fcffb89742b67aad81b57013' 'quay.io-biocontainers-shigeifinder@sha256-938e6d771ce71f87b625c0ff616d595d55b0b742fcffb89742b67aad81b57013'

pull_image 'docker://quay.io/biocontainers/seqsero2@sha256:f21a1590fa916deab4418a232c3b1c4e8ade920effda82f8fca88b932fc0e769' 'quay.io-biocontainers-seqsero2@sha256-f21a1590fa916deab4418a232c3b1c4e8ade920effda82f8fca88b932fc0e769'

pull_image 'docker://quay.io/biocontainers/ngmaster@sha256:e915dc192be212ab7f9813b937a3ad0c7afd2f32e7f7d7a58326a1fe91b1899c' 'quay.io-biocontainers-ngmaster@sha256-e915dc192be212ab7f9813b937a3ad0c7afd2f32e7f7d7a58326a1fe91b1899c'

pull_image 'docker://quay.io/biocontainers/sistr_cmd@sha256:91619cb8daecadeeb457f56e38bd6e5ec980d76e521067eccf1355984bfd4171' 'quay.io-biocontainers-sistr_cmd@sha256-91619cb8daecadeeb457f56e38bd6e5ec980d76e521067eccf1355984bfd4171'

pull_image 'docker://quay.io/biocontainers/pbptyper@sha256:6c1867a14528a4bbe5d7eed5bd9bca64ecd1604d4f1f3641e5c0d7ca4345ed47' 'quay.io-biocontainers-pbptyper@sha256-6c1867a14528a4bbe5d7eed5bd9bca64ecd1604d4f1f3641e5c0d7ca4345ed47'

pull_image 'docker://quay.io/biocontainers/pasty@sha256:2176d371c9061e8ad52bbac90b3eca5f1b79888d9fc59a6f7df845ba92c1c841' 'quay.io-biocontainers-pasty@sha256-2176d371c9061e8ad52bbac90b3eca5f1b79888d9fc59a6f7df845ba92c1c841'

pull_image 'docker://sangerbentleygroup/seroba@sha256:f72ff38a051dde6bf3c755e3d5c96ba6e8f5e15c0dc967187065c72f7f1a0ff2' 'sangerbentleygroup-seroba@sha256-f72ff38a051dde6bf3c755e3d5c96ba6e8f5e15c0dc967187065c72f7f1a0ff2'

pull_image 'docker://quay.io/biocontainers/spatyper@sha256:8c29abb04a86643c36a7bc46e08141b4c181e1ea25bfd90e9b43f22f0940bc82' 'quay.io-biocontainers-spatyper@sha256-8c29abb04a86643c36a7bc46e08141b4c181e1ea25bfd90e9b43f22f0940bc82'

rm -rf "$NXF_SINGULARITY_CACHEDIR/singularity-oci-cache/"
