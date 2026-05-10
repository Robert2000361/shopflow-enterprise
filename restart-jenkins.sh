docker rm -f jenkins
docker run -d \
  --name jenkins \
  --privileged \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
sleep 5
docker cp /tmp/docker jenkins:/usr/local/bin/docker
docker exec -u root jenkins chmod +x /usr/local/bin/docker
echo "Jenkins ready!"

# chmod +x ~/restart-jenkins.sh

