pipeline {
  agent {
    docker {
      image 'cloudhotspot/docker-agent'
      args '-v /var/run/docker.sock:/var/run/docker.sock --mount type=tmpfs,destination=/.docker'
    }
  }
  environment {
    DOCKER_USER     = credentials('docker-user')
    DOCKER_PASSWORD = credentials('docker-password')
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

    stage('Publish') {
      steps {
        sh 'make login'
        sh 'make publish'
      }
    }
  }
  post {
    always {
      junit allowEmptyResults: true, testResults: '**/reports/*.xml'
      sh 'make clean'
      sh 'make logout'
    }
  }
}