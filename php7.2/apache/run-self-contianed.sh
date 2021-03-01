#!/bin/bash
MODE=$1

function fail {
  echo $1 >&2
  exit 1
}

function try_curl {
  local n=1
  local max=4
  local delay=15
  while true; do
    curl http://localhost:8000/ && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "Unable to connect to WordPress after $n attempts."
      fi
    }
  done
}

echo "Running under mode: $MODE"

echo "$(date) Obtaining current git sha for tagging the docker image"
headsha=$(git rev-parse --verify HEAD)

if [[ "$1" == "-test" ]]; then
	set -e
	docker run --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -d mysql:5.7
	docker run --rm -e MODE="polyscripted" --name wordpress -v $PWD/wordpress:/wordpress  --link mysql-host:mysql -p 8000:80  polyverse/polyscripted-wordpress:apache-7.2-$headsha & 
	sleep 55
	try_curl
	echo "Curled wordpress success. Testing polyscripted"
	docker exec -t wordpress /bin/bash -c 'if [[ $(diff /wordpress/index.php /var/www/html/index.php) && ! $(php -l /wordpress/index.php) && $(php -l /var/www/html/index.php) ]]; then exit 0 else exit 1; fi'
else 
	docker run --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -d mysql:5.7
	docker run --rm -e MODE=$MODE --name wordpress -v $PWD/wordpress:/wordpress  --link mysql-host:mysql -p 8000:80  polyverse/polyscripted-wordpress:apache-7.2-$headsha
fi

