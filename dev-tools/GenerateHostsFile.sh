#!/usr/bin/env bash
# https://www.mypdns.org/
# Copyright: Content: https://gitlab.com/spirillen
# Source:Content:
#
# You are free to copy and distribute this file for non-commercial uses,
# as long the original URL and attribution is included.
#
# Please forward any additions, corrections or comments by logging an 
# issue at https://gitlab.com/my-privacy-dns/support/issues


# ******************
# Set Some Variables
# ******************

now=$(date '+%F %T %z (%Z)')
my_git_tag=V.${TRAVIS_BUILD_NUMBER}
bad_referrers=$(wc -l < ${TRAVIS_BUILD_DIR}/PULL_REQUESTS/domains.txt)

# ********************
# Set the output files
# ********************

outdir="${TRAVIS_BUILD_DIR}/download_here" # no trailing / as it would make a double //

# ordinary without safe search records
hosts="${outdir}/0.0.0.0/hosts"
hosts127="${outdir}/127.0.0.1/hosts"
mobile="${outdir}/mobile/hosts"
dnsmasq="${outdir}/dnsmasq/dnsmasq.conf"
rpz="${outdir}/rpz/pornhosts.rpz"

# Safe Search enabled output
ssoutdir="${outdir}/safesearch" # no trailing / as it would make a double //

sshosts="${ssoutdir}/0.0.0.0/hosts"
sshosts127="${ssoutdir}/127.0.0.1/hosts"
mobile="${ssoutdir}/mobile/hosts"
dnsmasq="${ssoutdir}/dnsmasq/dnsmasq.conf"
rpz="${ssoutdir}/rpz/pornhosts.rpz"

# ******************
# Set templates path
# ******************
templpath="${TRAVIS_BUILD_DIR}/dev-tools/templates"

hostsTempl=${templpath}/hosts.template
mobileTempl=${templpath}/dev-tools/mobile.template
dnsmasqTempl=${templpath}/ddwrt-dnsmasq.template
rpzTempl="${templpath}/safesearch/safesearch.rpz"
# Safe Search is in subpath

# TODO Get templates from the master source at 
# https://gitlab.com/my-privacy-dns/matrix/matrix/tree/master/safesearch
shostsTempl="${templpath}/safesearch/hosts.template"
smobileTempl="${templpath}/safesearch/mobile.template"
sdnsmasqTempl="${templpath}/safesearch/ddwrt-dnsmasq.template"
srpzTempl="${templpath}/safesearch/safesearch.rpz"

# First let us clean out old data in output folders

find "${outdir}" -type f -delete
find "${ssoutdir}" -type f -delete

# Next ensure all output folders is there

bash "${TRAVIS_BUILD_DIR}/dev-tools/make_output_dirs.dh (`grep -vE '^$' ${TRAVIS_BUILD_DIR}/dev-tools/output_dirs.txt`)"

# **************************************************************************************
# Strip out our Dead Domains / Whitelisted Domains and False Positives from CENTRAL REPO
# **************************************************************************************



# *******************************
echo Generate hosts 0.0.0.0
# *******************************

cat ${hostsTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${hosts}

# *******************************
echo Generate hosts 0.0.0.0
# *******************************

cat ${sshostsTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${sshosts}

# *******************************
echo Generate hosts 127.0.0.1
# *******************************

cat ${hostsTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("127.0.0.1\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${hosts127}

# *******************************
# Generate Mobile hosts
# *******************************

cat ${MobileTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${mobile}

# *******************************
# Generate hosts + SafeSearch
# *******************************

#cat ${SafeSearchTemplate} > ${tmphostsA}
#printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
#cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
#cp ${tmphostsA} ${safesearch}

# ********************************************************
# PRINT DATE AND TIME OF LAST UPDATE INTO DNSMASQ TEMPLATE
# ********************************************************

cat ${dnsmasqTemplate} > ${tmphostsB}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsB}
cat "${input1}" | awk '/^#/{ next }; {  printf("address=/%s/\n",tolower($1)) }' >> ${tmphostsB}
mv ${tmphostsB} ${dnsmasq}

# ************************************
echo Make Bind format RPZ 
# ************************************
RPZ="$(mktemp)"

printf "localhost.\t3600\tIN\tSOA\tneed.to.know.only. hostmaster.mypdns.org. `date +%s` 3600 60 604800 60;\nlocalhost.\t3600\tIN\tNS\tlocalhost\n" > "${RPZ}"
cat "${input1}" | awk '/^#/{ next }; {  printf("%s\tCNAME\t.\n*.%s\tCNAME\t.\n",tolower($1),tolower($1)) }' >> "${RPZ}"
mv "${RPZ}" "${TRAVIS_BUILD_DIR}/mypdns.cloud.rpz"

# ***********************************
echo Unbound zone file always_nxdomain
# ***********************************
UNBOUND="$(mktemp)"

cat "${input1}" | awk '/^#/{ next }; {  printf("local-zone: \"%s\" always_nxdomain\n",tolower($1)) }' >> "${UNBOUND}"
mv "${UNBOUND}" "${TRAVIS_BUILD_DIR}/unbound.nxdomain.zone"




exit ${?}
