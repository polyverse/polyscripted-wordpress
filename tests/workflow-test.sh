#!/bin/bash
set -ex

image=$(docker images | awk '{print $1}' | grep polyscripted-wordpress | awk 'NR==1')
container="wordpress"
git_root=$(git rev-parse --show-toplevel)
compose=$1

function fail {
  echo "FATAL ERROR: $1" >&2
  docker rm -f mysql-host
  docker rm -f $container
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
        sleep $delay
      else
        fail "Unable to connect to WordPress after $n attempts."
      fi
    }
  done
  echo "Curled success. Checking Syntax."

  if curl -f http://localhost:8000/; then
    if curl -f http://localhost:8000/ | grep -q "error"; then
      fail "Site ran with errors."
    else
      echo "Site ran successfully."
    fi
  else
    fail "Site could not be reached"
  fi

}

function start {
  extra_docker_params="$1"
  if [[ -z $compose ]]; then
    docker run --rm --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -d mysql:5.7
    docker run --rm -e MODE=$MODE --name $container -v $PWD/wordpress:/wordpress $extra_docker_params --link mysql-host:mysql -p 8000:80 ${image}
  else
    echo "alpine"
    docker tag ${image} ${image}:alpine-7.2-test
    MODE=$MODE headsha="test" docker-compose -f $compose up
  fi
}

function repeated_scramble {
  count=$1

  for i in $(seq 1 $count); do
    printf "\n\n\n\n\n"
    echo "---------------------------------------------------------------------------------------------------"
    echo "Scrambling wordpress repeatedly. Now testing scramble $i of $count"
    scramble
  done
}

function ensure_scrambled {
  echo "Ensuring Wordpress is Scrambled"
  docker exec -t $container /bin/bash -c '[[ $(diff /wordpress/index.php /var/www/html/index.php) != "" ]] || { echo "Wordpress is not scrambled when expected. Empty diff between /wordpress/index.php and /var/www/html/index.php."; diff /wordpress/index.php /var/www/html/index.php; exit 1; }'
  docker exec -t $container /bin/bash -c 'php -l /wordpress/index.php; retcode=$?; if [[ $retcode -eq 0 ]]; then echo "Wordpress is not scrambled when expected. Polyscripted PHP was able to successfully parse Vanilla /wordpress/index.php and exited with code $retcode"; exit 1; fi;'
  docker exec -t $container /bin/bash -c 'php -l /var/www/html/index.php; retcode=$?; if [[ $retcode -ne 0 ]]; then echo "Wordpress transformation has probably failed. Polyscripted PHP was not able to successfully parse Polyscripted /var/www/html/index.php and exited with code $retcode"; exit 1; fi;'
  docker exec -t $container /bin/bash -c 's_php -l /wordpress/index.php; retcode=$?; if [[ $retcode -ne 0 ]]; then echo "s_php is no longer Vanilla and was not able to successfully parse Polyscripted /wordpress/index.php and exited with code $retcode"; exit 1; fi;'
}

function ensure_vanilla {
  echo "Ensuring Wordpress is Vanilla"
  docker exec -t $container /bin/bash -c '[[ $(diff /wordpress/index.php /var/www/html/index.php) == "" ]] || { echo "Wordpress is scrambled when not expected. Printing diff between /wordpress/index.php and /var/www/html/index.php."; diff /wordpress/index.php /var/www/html/index.php; exit 1; }'
  docker exec -t $container /bin/bash -c 'php -l /wordpress/index.php; retcode=$?; if [[ $retcode -ne 0 ]]; then echo "Either one of PHP or Wordpress is scrambled when not expected. Expected Vanilla PHP was not able to successfully parse Vanilla /wordpress/index.php and exited with code $retcode"; exit 1; fi;'
  docker exec -t $container /bin/bash -c 'php -l /var/www/html/index.php; retcode=$?; if [[ $retcode -ne 0 ]]; then echo "Either one of PHP or Wordpress is scrambled when not expected. Expected Vanilla PHP was not able to successfully parse Expected Vanilla /var/www/html/index.php and exited with code $retcode"; exit 1; fi;'
}

function await_scramble_finish {
  echo "Waiting for Scrambling to finish"
  {
    while [[ "$(docker exec $container /bin/bash -c 'ps aux |grep scramble.sh | grep -v grep |wc -l')" != "0" ]]; do
      sleep 1
    done

    sleep 1
  } 2>/dev/null

  echo "Scrambling finished."
}

function await_reset_finish {
  echo "Waiting for Reset to finish"
  {
    while [[ "$(docker exec $container /bin/bash -c 'ps aux |grep reset.sh | grep -v grep |wc -l')" != "0" ]]; do
      sleep 1
    done

    sleep 1
  } 2>/dev/null

  echo "Reset finished."
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

  await_scramble_finish

  # Ensure works and is Polyscrpted
  ensure_scrambled
  try_curl
}

function test_safe_mount_var_www_html {

  printf "\n\n\n\n\n"
  echo "---------------------------------------------------------------------------------------------------"
  echo "testing wordpress started in vanilla mode with /var/www/html mounted and non-empty..."
  MODE=
  start "-v $PWD/wordpress:/var/www/html" &
  sleep 20
  if [ "$(docker ps |grep wordpress)" != "" ]; then
    fail "Polyscripted container with wordpress mounted at /var/www/html exists. This is not allowed for Polyscripted containers. They MUST ABORT when /var/www/html is non-empty."
  fi

  {docker rm -f mysql-host; docker rm -f $container;}

  printf "\n\n\n\n\n"
  echo "---------------------------------------------------------------------------------------------------"
  echo "testing wordpress started in Polyscripted mode with /var/www/html mounted and non-empty..."
  MODE=polyscripted
  start "-v $PWD/wordpress:/var/www/html" &
  sleep 20
  echo "Testing container started"
  if [ "$(docker ps |grep wordpress)" != "" ]; then
    fail "Polyscripted container with wordpress mounted at /var/www/html exists. This is not allowed for Polyscripted containers. They MUST ABORT when /var/www/html is non-empty."
  fi

  {docker rm -f mysql-host; docker rm -f $container;}

}

function test_start_polyscripted_scramble_more_end_vanilla {
  printf "\n\n\n\n\n"
  echo "---------------------------------------------------------------------------------------------------"
  echo "testing wordpress started in Polyscripted mode"
  MODE=polyscripted
  start &
  sleep 20
  echo "Testing container started"
  if [[ ! "$(docker container inspect -f '{{.State.Running}}' $container)" == "true" ]]; then
    fail "WordPess container failed to start -- check polyscripting errors."
  fi

  await_scramble_finish

  # Ensure works and is Polyscrpted
  ensure_scrambled
  try_curl

  # Live-scramble through dispatcher multiple times and ensure works and is polyscripted
  repeated_scramble 2

  # Unscramble through dispatcher and ensure works
  printf "\n\n\n\n\n"
  echo "---------------------------------------------------------------------------------------------------"
  echo "Unscrambling wordpress started polyscripted and scrambled repeatedly..."
  docker exec -t $container /bin/bash -c 'echo "3 " | nc localhost 2323'
  await_reset_finish
  ensure_vanilla
  try_curl

  {docker rm -f mysql-host; docker rm -f $container;}

}

function test_start_vanilla_scramble_some_end_vanilla {
  printf "\n\n\n\n\n"
  echo "---------------------------------------------------------------------------------------------------"
  echo "testing wordpress started in vanilla mode..."
  MODE=
  start &
  sleep 20
  if [ "$(docker container inspect -f '{{.State.Running}}' $container)" == "false" ]; then
    fail "Vanilla container failed to start -- check container errors."
  fi
  await_reset_finish

  # Ensure works
  ensure_vanilla
  try_curl

  printf "\n\n\n\n\n"
  echo "---------------------------------------------------------------------------------------------------"
  echo "Testing wordpress started vanilla and reset again, stays vanilla..."
  docker exec -t $container /bin/bash -c 'echo "3 " | nc localhost 2323'
  await_reset_finish

  # Ensure works
  ensure_vanilla
  try_curl


  # Live-scramble through dispatcher multiple times and ensure works and is polyscripted
  repeated_scramble 2

  # Unscramble through dispatcher and ensure works
  printf "\n\n\n\n\n"
  echo "---------------------------------------------------------------------------------------------------"
  echo "Unscrambling wordpress started vanilla and scrambled a few times..."
  docker exec -t $container /bin/bash -c 'echo "3 " | nc localhost 2323'
  await_reset_finish
  ensure_vanilla
  try_curl

  {docker rm -f mysql-host; docker rm -f $container;}

}

function test_all {
  test_safe_mount_var_www_html
  test_start_polyscripted_scramble_more_end_vanilla
  test_start_vanilla_scramble_some_end_vanilla
}

test_all
