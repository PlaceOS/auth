#! /usr/bin/env bash

set -eu

docker-compose down

# this function is called when Ctrl-C is sent
function trap_ctrlc ()
{
    docker-compose down &> /dev/null
    exit 2
}

# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2

docker-compose pull -q
docker-compose build -q
# docker-compose up -d

exit_code="0"

# docker-compose exec -it auth2 rake db:create db:migrate
# docker-compose exec -it auth2 bundle exec rails db:seed
#docker-compose exec -it auth2 bundle exec rails test

docker-compose run -it --entrypoint="" auth2 bundle exec rails test
docker-compose down &> /dev/null

exit ${exit_code}
