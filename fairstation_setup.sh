#!/usr/bin/env sh
# Need to pass 1 argument, either sudo or blank
# Before running the script, make it executable chmod +x command
# method to download and setup environment
ubuntu_env_setup(){
	$1 apt update && $1 apt install apt-transport-https git ca-certificates curl gnupg lsb-release -y 
	$1 mkdir -p /etc/apt/keyrings 
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $1 gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | $1 tee /etc/apt/sources.list.d/docker.list > /dev/null
	$1 apt update
	$1 apt install docker-ce docker-ce-cli containerd.io docker-compose-p -y
	# $1 usermod -aG docker $USER -- if permission becomes an issue
	# If this docker install fails, can install docker compose through pip. Using the latest version, hopefully does not break anything else.
	$1 curl -L https://github.com/docker/compose/releases/download/v2.10.0/docker-compose-linux-x86_64  -o /usr/local/bin/docker-compose
	$1 chmod +x /usr/local/bin/docker-compose
	$1 ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
	$1 service docker start
	docker-compose --version
}

redhat_env_setup(){
	sudo yum update && sudo yum install -y yum-utils git curl wget #device-mapper-persistent-data lvm2
	sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
	sudo yum update && sudo yum install -y docker-ce docker-ce-cli containerd.io 
	# sudo yum install docker-ce --allowerasing # if dependency issues with podman
	sudo systemctl enable --now docker
	systemctl status docker
	sudo usermod -aG docker $USER
	newgrp docker
	id $USER
	docker version
	curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url  | grep docker-compose-linux-x86_64 | cut -d '"' -f 4 | wget -qi -
	chmod +x docker-compose-linux-x86_64
	sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
	docker-compose version
}

docker_setup(){
	docker-compose up -d --quiet-pull
}

repo_setup(){
	git clone https://gitlab.com/UM-CDS/protrait/fairifier2.git
	cd fairifier2
	# if additional env variables need to be added, add here 	
	touch .env
	printf "AIRFLOW_VAR_APPEND_CSV=0\n" >> .env
	printf "\n" >> .env
	printf "AIRFLOW_UID=50000\n" >> .env
	printf "AIRFLOW_GID=0\n" >> .env
	printf "\n" >> .env
	printf "# R2RML\n" >> .env
	printf "AIRFLOW_VAR_R2RML_REPO=https://github.com/jaspersnel/r2rml_tests.git\n" >> .env
	printf "AIRFLOW_VAR_R2RML_REPO_SUBDIR=.\n" >> .env
	printf "AIRFLOW_VAR_R2RML_DB_URL=postgresql://airflow:airflow@postgres:5432/data\n" >> .env
	printf "AIRFLOW_VAR_R2RML_RDB_CONNSTR=jdbc:postgresql://localhost:5432/protrait\n" >> .env
	printf "AIRFLOW_VAR_R2RML_RDB_PASSWORD=passwordhere\n" >> .env
	printf "AIRFLOW_VAR_R2RML_RDB_USER=postgres\n" >> .env
	printf "\n" >> .env
	printf "# Triplestore\n" >> .env
	printf "AIRFLOW_VAR_SPARQL_ENDPOINT=http://graphdb:7200/repositories/data\n" >> .env
	printf "\n" >> .env
	printf "# LibreClinica\n" >> .env
	printf "AIRFLOW_VAR_LC_ENDPOINT=https://libreclinica.health-ri.nl/lcws_test/ws/\n" >> .env
	printf "AIRFLOW_VAR_LC_USER=protrait_import\n" >> .env
	printf "AIRFLOW_VAR_LC_PASSWORD=hashed_password_here" >> .env
}

if [ "$1" == "sudo" ]
then
	echo "Running the process as $1"
else
	echo "Running the process as normal user"
fi

echo "Setting up the environment"
if [ "$2" == "ubuntu" ]
then
	ubuntu_env_setup
else
	redhat_env_setup
fi

echo "Downloading the repo and creating the environment file for airflow"
repo_setup

echo "Creating docker containers"
docker_setup

echo "Done. Airflow can be accessed on 8080, Graphdb on 7200, term mapper on 5001"
