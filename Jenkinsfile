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
  }
  post {
    always {
      junit allowEmptyResults: true, testResults: '**/reports/*.xml'
      sh 'make clean'
    }
  }
}