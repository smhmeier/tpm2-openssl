#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
set -eufx

EXPECTED=expected_modulus.pem
COMPUTED=modulus.pem
cat > ${EXPECTED} <<EOF
Modulus=B6BF038095A5756BA2951D2A0356A134DD52E326BF71A44A4DB1DCCAA883300F598C2D77213155810E9ADA19AD098A27C9773B801FEB770096B03FFDA25FFA248D39F503A8CB09185DA1F8A7461983A0C50800AEC0291732FAEC4789FB50DC5C613CB44E67623406D7FD943812FA4158CD807E9C11F81469043CF6FCB86E8D6FE50361A7289E5B3975D89E3C5CF4E5015BA24223117D6E823ACE5E9D60474117742E6D88500FABA3459ADD6F0A13733362914284F2766D6013B728B8C91801F5080F5EB833A33495459B5739B9B317A133E9982E421B98614B0DB468CF2F9D4B7750BB12776905567E816AB9450FB935B5F3003E10F1DDB3EABFB25B23E3C6CB
EOF

# create primary
tpm2_createprimary -G rsa -g sha256 -c primary.ctx

# make the primary persistent
HANDLE=$(tpm2_evictcontrol -c primary.ctx | cut -d ' ' -f 2 | head -n 1)

# Export the private key through the specified handle
openssl rsa -provider tpm2 -provider default -in "handle:${HANDLE}" -out primary_key.pem

# Import the private key and export 
openssl rsa -provider tpm2 -provider default -in primary_key.pem -modulus -noout -out ${COMPUTED}

# Simple test, check if the parameter is equals
if cmp -s "${EXPECTED}" "${COMPUTED}" ;
then
    echo "Modulus is equals!"
else
    echo "Expected modulus differs. Expected:"
    cat ${EXPECTED}
    echo "Got: "
    cat ${COMPUTED}
fi

# release the persistent key
tpm2_evictcontrol -c ${HANDLE}

rm primary.ctx primary_key.pem ${EXPECTED} ${COMPUTED}
