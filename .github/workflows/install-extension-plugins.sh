#!/bin/bash
set -euo pipefail

MAIL_COMPAT3_URL=https://github.com/9506hqwy/redmine_mail_delivery_compat3.git

git clone --depth 1 "${MAIL_COMPAT3_URL}"
