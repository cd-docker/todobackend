pipeline {
  agent {
    docker {
      image 'cloudhotspot/docker-agent'
      args '-v /var/run/docker.sock:/var/run/docker.sock'
    }
  }
  stages {
    stage('Test') {
      steps {
        sh 'make test'
      }
    }

    stage('Release') {
      steps {
        sh 'make release'
      }
    }

    stage('Clean') {
      steps {
        sh 'make clean'
      }
    }

  }
}