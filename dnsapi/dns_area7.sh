#!/usr/bin/env sh
# shellcheck disable=SC2034
dns_area7_info='area-7.it
Site: area-7.it
Docs: https://github.com/acmesh-official/acme.sh/wiki/dnsapi2#dns_area7
Options:
 area7_Token API Token
Issues: https://github.com/acmesh-official/acme.sh/issues/6248
Author: John Lebherz
'

area7_API="https://portal.area-7.cloud/api/v1/"

########  Public functions ######################

#Usage: dns_area-7_add _acme-challenge.domain.area-7.it.net "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_area7_add() {
  fulldomain=$1
  txtvalue=$2

  area7_Token="${area7_Token:-$(_readaccountconf_mutable area7_Token)}"
  if [ -z "$area7_Token" ]; then
    _err "You must export variable: area7_Token"
    return 1
  fi

  # Now save the credentials.
  _saveaccountconf_mutable area7_Token "$area7_Token"

  if ! _get_root "$fulldomain"; then
    _err "invalid domain" "$fulldomain"
    return 1
  fi
  _debug _sub_domain "$_sub_domain"
  _debug _domain "$_domain"

  # convert to lower case
  _domain="$(echo "$_domain" | _lower_case)"
  _sub_domain="$(echo "$_sub_domain" | _lower_case)"
  # Now add the TXT record
  _info "Trying to add TXT record"
  if _area7_rest "POST" "dnsAPI/createRecord" "domain=$_domain&prefix=$_sub_domain&type=txt&value=$txtvalue&ttl=10"; then
    _info "TXT record has been successfully added."
    return 0
  else
    _err "Errors happened during adding the TXT record, response=$_response"
    return 1
  fi

}

#Usage: fulldomain txtvalue
#Usage: dns_area-7_rm _acme-challenge.domain.area-7.it "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
#Remove the txt record after validation.
dns_area7_rm() {
  fulldomain=$1
  txtvalue=$2

  area7_Token="${area7_Token:-$(_readaccountconf_mutable area7_Token)}"
  if [ -z "$area7_Token" ]; then
    _err "You must export variable: area7_Token"
    return 1
  fi

  if ! _get_root "$fulldomain"; then
    _err "invalid domain" "$fulldomain"
    return 1
  fi
  _debug _sub_domain "$_sub_domain"
  _debug _domain "$_domain"

  # convert to lower case
  _domain="$(echo "$_domain" | _lower_case)"
  _sub_domain="$(echo "$_sub_domain" | _lower_case)"
  # Now delete the TXT record
  _info "Trying to delete TXT record"
  if _area7_rest "POST" "dnsAPI/delRecord" "domain=$_domain&prefix=$_sub_domain&type=txt&value=$txtvalue"; then
    _info "TXT record has been successfully deleted."
    return 0
  else
    _err "Errors happened during deleting the TXT record, response=$_response"
    return 1
  fi

}

####################  Private functions below ##################################
#_acme-challenge.www.domain.com
#returns
# _sub_domain=_acme-challenge.www
# _domain=domain.com
_get_root() {
  domain="$1"
  i=1
  p=1


      _sub_domain=$(printf "%s" "$domain" | cut -d . -f 1-"$p")
      _domain=$(echo "$domain" | cut -d . -f 2-)
      return 0
}

#send get request to api
# $1 has to set the api-function
_area7_get() {
  url="$area7_API?$1"
  export _H1="Authorization: Bearer $area7_Token"

  _response=$(_get "$url")
  _response="$(echo "$_response" | _normalizeJson)"

}

_area7_rest() {
  url="$area7_API$2"
  export _H1="Authorization: Bearer $area7_Token"
  export _H2="Content-Type: application/x-www-form-urlencoded"
  _response=$(_post "$3" "$url" "" "$1")


  if ! _contains "$_response" "\"message\":\"OK\""; then
    return 1
  fi
  _debug2 response "$_response"
  return 0
}
