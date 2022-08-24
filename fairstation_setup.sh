#!/usr/bin/env sh
# Need to pass 1 argument, either sudo or blank
# method to download and setup environment
env_setup(){
	$1 apt update && $1 apt install git docker
	# If this docker install fails, can install docker compose through pip. Using the latest version, hopefully does not break anything else.
	$1 curl -L https://github.com/docker/compose/releases/download/v2.10.0/docker-compose-linux-x86_64  -o /usr/local/bin/docker-compose
	$1 chmod +x /usr/local/bin/docker-compose
	$1 ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	$1 service docker start
	docker-compose --version
}
docker_setup(){
	$1 docker-compose up -d --quiet-pull
}
repo_setup(){
	git clone https://gitlab.com/UM-CDS/protrait/fairifier2.git
	cd fairifier2
	# if additional env variables need to be added, add here 	
	touch .env
	echo "\nAIRFLOW_UID=50000" >> .env
	echo "\nAIRFLOW_GID=0" >> .env
	echo "\nR2RML_RDB_CONNSTR=jdbc:postgresql://localhost:5432/protrait" >> .env
	echo "\nR2RML_RDB_PASSWORD=passwordhere" >> .env
	echo "\nR2RML_RDB_USER=postgres" >> .env
	echo "\nR2RML_REPO=https://github.com/jaspersnel/r2rml_tests.git" >> .env
	echo "\nR2RML_REPO_SUBDIR=." >> .env
}
if [ "$1" == "sudo" ]
then
	echo "Running the process as $1"
else
	echo "Running the process as normal user"
fi
echo "Setting up the environment"
env_setup
echo "Downloading the repo and creating the environment file for airflow"
repo_setup
echo "Creating docker containers"
docker_setup
echo "Done. Airflow can be accessed on 8080, Graphdb on 7200, term mapper on 5001"
