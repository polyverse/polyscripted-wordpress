set -e

image=`docker images | awk '{print $1}' | awk 'NR==2'`
container="test-buildi-wordpress"
git_root=`git rev-parse --show-toplevel`

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
  echo "Curled success. Checking Syntax."
  done
  if curl -f http://localhost:8000/ | grep -q "error" ; then
	fail "Site ran with errors."
  else
  	echo "Site ran successfully."
  fi
}

function start {
        docker run --rm --name mysql-host -e MYSQL_ROOT_PASSWORD=qwerty -d mysql:5.7
	docker run --rm -e MODE=$MODE --name wordpress -v $PWD/wordpress:/wordpress  --link mysql-host:mysql -p 8000:80 $image 
}


echo "testing vanillay wordpress"
start &
sleep 20
try_curl

docker stop mysql-host; docker stop /wordpress
echo "testing Polyscripted wordpress"
MODE=polyscripted
start &
sleep 55
try_curl
docker exec -t wordpress /bin/bash -c 'if [[ $(diff /wordpress/index.php /var/www/html/index.php) && ! $(php -l /wordpress/index.php) && $(php -l /var/www/html/index.php) ]]; then exit 0 else exit 1; fi'



