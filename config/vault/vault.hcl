listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

## backend "file" {
##   path = "/vault/file"
## }

backend "consul" {
  address = "consul:8500"
  scheme = "http"
}

disable_mlock = true
