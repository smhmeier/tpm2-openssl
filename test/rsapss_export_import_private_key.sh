#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
set -eufx

EXPECTED=expected_modulus.pem
COMPUTED=modulus.pem

cat > ${EXPECTED} <<EOF
Modulus=C1E772D397DD94F4F519E795DE8F653EAE3EB13AE2B570754E490241E7122E711F1455A684A6C5DE409F4EEDD2CAB9E18257489E25D58EC1113516E50137E3AD08EF20301EB4E8727025976999E92F625064ADDB8D543FBA97348D5AABE1BC5F83AD57200786DA914B8B0394782FF20AA678AD8F106EF2618D2FA85040BF2CEF101B18589C3F8B60470A25A63DAF9097AAE0733C51ED83D713B9AAEE069892C2B445770A363D27A2F17D5702E45FA3833729C649B3AD9E8CF974893B1AF41D538359E9A04B9F2C7BD82AA2F8CAFBC8D8475B0714FC69579D3AB28223569C44FC7215A9587974F94EBB542A991F8A846BA51AA9CDA5F6529B8042C3ECB4E3D1DB
EOF

# create primary
tpm2_createprimary -G rsa2048:rsapss-sha256:null -c primary.ctx -a 'fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign|restricted'

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
