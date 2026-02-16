##
## A wrapper that allows local build & deploy.
## NOTICE: keep this 'in sync' with what happens in cicd/{build,deploy}/buildspec.yaml
##

.ONESHELL:

# Our own:
PROJECT="project/PPA"
DEPLOY_SCRIPT="cicd/deploy/deploy-to-beanstalk.sh"

# DEPLOY_SCRIPT (see also cicd/deploy) needs the following:
export BEANSTALK_BUCKET 	 = ppa-artifacts
export BEANSTALK_APP		 = PPA
export BEANSTALK_ENVIRONMENT = development-ng

# Make targets, help as the default:
help:
		@echo make build
		@echo make deploy
		@echo make clean

all:	clean build deploy

clean::
	@echo "** make clean"
	rm -rf artifacts
	rm -rf ${PROJECT}/target

build: artifacts/application.jar

artifacts/application.jar:
	@echo "** make build"
	mvn compile -f ${PROJECT}
	mvn package -f ${PROJECT}
	mkdir -p artifacts
	cp ${PROJECT}/target/application.zip artifacts
	git log -1 --pretty='%H' > artifacts/tag.id
	git log -1 --pretty='%B' > artifacts/tag.txt
	git name-rev HEAD --name-only > artifacts/branch.txt
	echo "artifacts: "
	@ls -asl artifacts
	
deploy: artifacts/application.zip
	@echo "** make deploy"
	cd artifacts
	sh ../${DEPLOY_SCRIPT}
