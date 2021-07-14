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
  done
  echo "Curled success. Checking Syntax."

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

function repeated_scramble {
  for i in {1..20}
  do
    echo "Testing rescramble $i"
    scramble
  done
}

function ensure_scrambled {
    echo "Ensuring Wordpress is Scrambled"
    docker exec -t $container /bin/bash -c '[[ $(diff /wordpress/index.php /var/www/html/index.php) != "" ]]'
    docker exec -t $container /bin/bash -c 'php -l /wordpress/index.php; [ $? -ne 0 ]'
    docker exec -t $container /bin/bash -c 'php -l /var/www/html/index.php'
}

function ensure_vanilla {
  echo "Ensuring Wordpress is Vanilla"
  docker exec -t $container /bin/bash -c '[[ $(diff /wordpress/index.php /var/www/html/index.php) == "" ]]'
  docker exec -t $container /bin/bash -c 'php -l /wordpress/index.php'
  docker exec -t $container /bin/bash -c 'php -l /var/www/html/index.php'
}

function await_transform_finish {
  echo "Waiting for $1 to finish"
  {
    while [[ "$(docker exec $container /bin/bash -c 'ps aux |grep scramble.sh | grep -v grep |wc -l')" != "0" ]]; do
      #echo "Waiting for scrambling to finish... $(docker exec $container /bin/bash -c 'ps aux |grep scramble.sh | grep -v grep |wc -l')"
      sleep 1
    done

    sleep 1
  } 2> /dev/null

  echo "$1 finished."
}

function scramble {
  # Scramble/rescramble using either 1 or 2 as parameters to dispatcher
  scramble_dispatcher_command=$((1 + $RANDOM % 2))

  # Using a dumb if-cascade because I don't know how to expand variables to bash -c
  if [ "$scramble_dispatcher_command" == "1" ]; then
    docker exec -t $container /bin/bash -c 'echo "1 " | nc localhost 2323'
  elif [ "$scramble_dispatcher_command" == "2" ]; then
    docker exec -t $container /bin/bash -c 'echo "2 " | nc localhost 2323'
  fi

  await_scramble_finish "Scrambling"

  # Ensure works and is Polyscrpted
  try_curl
  ensure_scrambled
}

echo "testing vanilla wordpress"
MODE=
start &
sleep 20
if [ "$( docker container inspect -f '{{.State.Running}}' $container )" == "false" ]; then
        fail "Vanilla container failed to start -- check container errors."
fi

# Ensure works
try_curl
ensure_vanilla

# Live-scramble through dispatcher multiple times and ensure works and is polyscripted
repeated_scramble

# Unscramble through dispatcher and ensure works
docker exec -t $container /bin/bash -c 'echo "3 " | nc localhost 2323'
await_scramble_finish "Unscrambling"
try_curl
ensure_vanilla


docker stop mysql-host; docker stop $container
echo "testing Polyscripted wordpress"
MODE=polyscripted
start &
sleep 1
await_scramble_finish "Scrambling"
echo "Testing container started"
if [[ ! "$( docker container inspect -f '{{.State.Running}}' $container )" == "true" ]]; then
	fail "WordPess container failed to start -- check polyscripting errors."
fi

# Ensure works and is Polyscrpted
try_curl
ensure_scrambled

# Live-scramble through dispatcher multiple times and ensure works and is polyscripted
repeated_scramble

# Unscramble through dispatcher and ensure works
docker exec -t $container /bin/bash -c 'echo "3 " | nc localhost 2323'
await_scramble_finish "Unscrambling"
try_curl
ensure_vanilla

if [[ ! "$( docker container inspect -f '{{.State.Running}}' $container )" == "true" ]]; then
        fail "WordPess container failed -- check polyscripting errors."
fi

docker stop mysql-host; docker stop $container
