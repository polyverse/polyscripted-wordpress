#!/bin/bash
set -ex

image=`docker images | awk '{print $1}' |grep polyscripted-wordpress | awk 'NR==1'`
container="wordpress"
git_root=`git rev-parse --show-toplevel`
compose=$1

function fail {
  echo $1 >&2
  docker stop mysql-host; docker stop $container
  exit 1
}


function try_curl {
  local n=1
  local max=5
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
  echo "Curled success. Checking Syntax."
  done
  if curl -f  http://localhost:8000/; then
  	if curl -f http://localhost:8000/ | grep -q "error" ; then
		fail "Site ran with errors."
  	else
  		echo "Site ran successfully."
  	fi
   else
	  fail "Site could not be reached"
  fi

  }

function start {
	if [[ -z $compose ]]; then
		docker run --rm --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -d mysql:5.7
		docker run --rm -e MODE=$MODE --name $container -v $PWD/wordpress:/wordpress  --link mysql-host:mysql -p 8000:80 $image
	else
		echo "alpine"
		docker tag $image $image:alpine-7.2-test
		MODE=$MODE headsha="test" docker-compose -f $compose up
	fi
}

echo "testing vanilla wordpress"
start &
sleep 20
if [ "$( docker container inspect -f '{{.State.Running}}' $container )" == "false" ]; then
        fail "Vanilla container failed to start -- check container errors."
fi
try_curl

docker stop mysql-host; docker stop $container
echo "testing Polyscripted wordpress"
MODE=polyscripted
start &
sleep 55
echo "Testing container started"
if [[ ! "$( docker container inspect -f '{{.State.Running}}' $container )" == "true" ]]; then
	fail "WordPess container failed to start -- check polyscripting errors."
fi
try_curl
docker exec -t $container /bin/bash -c 'if [[ $(diff /wordpress/index.php /var/www/html/index.php) && ! $(php -l /wordpress/index.php) && $(php -l /var/www/html/index.php) ]]; then exit 0 else exit 1; fi'

if [[ ! "$( docker container inspect -f '{{.State.Running}}' $container )" == "true" ]]; then
        fail "WordPess container failed -- check polyscripting errors."
fi

docker stop mysql-host; docker stop $container
